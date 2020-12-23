
using System;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;

[Guid ("bd39d1d2-ba2f-486a-89b0-b4b0cb466891")]
[InterfaceType (ComInterfaceType.InterfaceIsIUnknown)]
[ComImport ()]
public interface ICLRRuntimeInfo
{
	[MethodImpl (MethodImplOptions.InternalCall, MethodCodeType = MethodCodeType.Runtime)]
	void GetVersionString(
		IntPtr pwzBuffer,
		ref uint pcchBuffer);

	// There are more methods, but we're only testing the first one.
}

static class TestRuntimeInterface
{
    public static int Main()
    {
		var re = (ICLRRuntimeInfo)RuntimeEnvironment.GetRuntimeInterfaceAsObject(Guid.Empty, typeof(ICLRRuntimeInfo).GUID);

		uint buffer_size = 260;

		re.GetVersionString(IntPtr.Zero, ref buffer_size);

		var buffer = Marshal.AllocCoTaskMem((int)buffer_size);

		re.GetVersionString(buffer, ref buffer_size);

		string version = Marshal.PtrToStringUni(buffer);

		Marshal.FreeCoTaskMem(buffer);

		if (version != RuntimeEnvironment.GetSystemVersion())
		{
			Console.WriteLine("ICLRRuntimeInfo version is {0}", version);
			Console.WriteLine("RuntimeEnvironment.GetSystemVersion is {0}", RuntimeEnvironment.GetSystemVersion());
			return 1;
		}

		return 0;
    }
}
