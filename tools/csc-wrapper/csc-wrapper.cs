using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Threading;

class CscWrapper
{

#if VERSION20
	const string VERSION_STRING = "2.0-api";
#elif VERSION40
	const string VERSION_STRING = "4.0-api";
#endif

	[DllImport("kernel32", CallingConvention=CallingConvention.StdCall, SetLastError=true)]
	extern static uint GetConsoleCP();

	[DllImport("kernel32", CallingConvention=CallingConvention.StdCall, SetLastError=true)]
	extern static IntPtr GetStdHandle(int nStdHandle);

	const int STD_INPUT_HANDLE = -10;
	const int STD_OUTPUT_HANDLE = -11;
	const int STD_ERROR_HANDLE = -12;

	[StructLayout(LayoutKind.Sequential, CharSet=CharSet.Unicode)]
	struct STARTUPINFOW
	{
		public uint cb;
		public string lpReserved;
		public string lpDesktop;
		public string lpTitle;
		public uint dwX;
		public uint dwY;
		public uint dwXSize;
		public uint dwYSize;
		public uint dwXCountChars;
		public uint dwYCountChars;
		public uint dwFillAttribute;
		public uint dwFlags;
		public ushort wShowWindow;
		public ushort cbReserved2;
		public IntPtr lpReserved2;
		public IntPtr hStdInput;
		public IntPtr hStdOutput;
		public IntPtr hStdError;
	}

	const uint STARTF_USESTDHANDLES = 0x00000100;

	[StructLayout(LayoutKind.Sequential)]
	struct PROCESS_INFORMATION
	{
		public IntPtr hProcess;
		public IntPtr hThread;
		public uint dwProcessId;
		public uint dwThreadId;
	}

	[DllImport("kernel32", CallingConvention=CallingConvention.StdCall, CharSet=CharSet.Unicode, SetLastError=true)]
	extern static bool CreateProcessW(string lpApplicationName, char[] lpCommandLine, IntPtr lpProcessAttributes,
		IntPtr lpThreadAttributes, bool bInheritHandles, uint dwCreationFlags, IntPtr lpEnvironment,
		string lpCurrentDirectory, ref STARTUPINFOW lpStartupInfo, ref PROCESS_INFORMATION lpProcessInformation);

	const uint CREATE_NO_WINDOW = 0x08000000;

	[DllImport("kernel32", CallingConvention=CallingConvention.StdCall)]
	extern static uint WaitForSingleObject(IntPtr hHandle, uint dwMilliseconds);

	const uint INFINITE = 0xffffffff;

	[DllImport("kernel32", CallingConvention=CallingConvention.StdCall)]
	extern static bool CloseHandle(IntPtr hObject);

	[DllImport("kernel32", CallingConvention=CallingConvention.StdCall)]
	extern static bool GetExitCodeProcess(IntPtr hProcess, ref int lpExitCode);

	static string GetCorlibName()
	{
		Assembly corlib = Assembly.ReflectionOnlyLoad("mscorlib");
		return corlib.Location;
	}

	static int Main(string[] arguments)
	{
		var addStdlib = true;

		for (int i = 0; i< arguments.Length; i++)
		{
			if (arguments[i] == "/nostdlib" || arguments[i] == "-nostdlib")
			   addStdlib = false;
			arguments[i] = '"' + arguments[i] + '"';
		}

		string corlib = GetCorlibName();
		string current_lib = Path.GetDirectoryName(corlib);
		string api_lib = Path.Combine(Path.GetDirectoryName(current_lib), VERSION_STRING);
		string mcs_name = Path.Combine(current_lib, "mcs.exe");
		corlib = Path.Combine(api_lib, "mscorlib.dll");

		var versionArguments = mcs_name;
		if (addStdlib)
			versionArguments = String.Format("/nostdlib \"/r:{0}\" \"/lib:{1}\" ", corlib, api_lib);

		var commandLine = String.Format("\"{0}\" {1}{2}", mcs_name, versionArguments, String.Join(" ", arguments));

		uint flags = 0;

		var si = new STARTUPINFOW();
		si.cb = (uint)Marshal.SizeOf(si);
		
		if (GetConsoleCP() == 0)
		{
			// This process was created without a console. We don't want mcs.exe to create a console,
			// but this seems to be the only way to pass through the handles, so just hide the window.
			flags |= CREATE_NO_WINDOW;
			si.dwFlags |= STARTF_USESTDHANDLES;
			si.hStdInput = GetStdHandle(STD_INPUT_HANDLE);
			si.hStdOutput = GetStdHandle(STD_OUTPUT_HANDLE);
			si.hStdError = GetStdHandle(STD_ERROR_HANDLE);
		}

		var pi = new PROCESS_INFORMATION();

		if (!CreateProcessW(mcs_name, (commandLine+"\0").ToCharArray(), IntPtr.Zero, IntPtr.Zero, true, flags, IntPtr.Zero, null, ref si, ref pi))
		{
			throw new Exception(String.Format("CreateProcessW failed with error {0}", Marshal.GetLastWin32Error()));
		}

		CloseHandle(pi.hThread);

		WaitForSingleObject(pi.hProcess, INFINITE);

		int exit_code = 1;

		GetExitCodeProcess(pi.hProcess, ref exit_code);

		CloseHandle(pi.hProcess);

		return exit_code;
	}
}

