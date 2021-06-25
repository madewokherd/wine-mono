
using System;
using System.Runtime.InteropServices;
using System.Text;

static class TestMarshalAnsi
{
	static readonly byte[] teststring = {
		230, 150, 135, 229, 173, 151, 229, 140, 150, 227, 129, 145, 0};

	static string utf16_string;

	[DllImport("kernel32")]
	unsafe extern static int MultiByteToWideChar(int cp, int flags,
		byte* mbstr, int mbstr_len, char* wstr, int wstr_len);

	unsafe public static void Initialize()
	{
		fixed (byte* mbstr = teststring)
		{
			int wstr_len = MultiByteToWideChar(0, 0, mbstr, teststring.Length-1, null, 0);
			char[] wstr = new char[wstr_len];
			fixed (char* pwstr = wstr)
			{
				MultiByteToWideChar(0, 0, mbstr, teststring.Length-1, pwstr, wstr_len);
			}
			utf16_string = new String(wstr);
		}
		Console.WriteLine("Test string: {0} (length {1})", utf16_string, utf16_string.Length);
	}

	unsafe public static bool TestPtrToStringAnsi()
	{
		fixed (byte* mbstr = teststring) {
			IntPtr pstr = new IntPtr(mbstr);

			string str = Marshal.PtrToStringAnsi(pstr);

			if (str != utf16_string)
			{
				Console.WriteLine("PtrToStringAnsi[1] returned {0} (length {1})", str, str.Length);
				return false;
			}

			str = Marshal.PtrToStringAnsi(pstr, teststring.Length-1);

			if (str != utf16_string)
			{
				Console.WriteLine("PtrToStringAnsi[1] returned {0} (length {1})", str, str.Length);
				return false;
			}
		}
		return true;
	}

	static bool check_mem(IntPtr mem, string test)
	{
		for (int i=0; i<teststring.Length; i++)
		{
			if (Marshal.ReadByte(mem, i) != teststring[i])
			{
				Console.WriteLine("{0}: returned string differs at index {1}, got {2}, expected {3}", test, i, Marshal.ReadByte(mem, i), teststring[i]);
				return false;
			}
		}
		return true;
	}

	public static bool TestStringToCoTaskMemAnsi()
	{
		IntPtr mem = Marshal.StringToCoTaskMemAnsi(utf16_string);

		if (!check_mem(mem, "TestStringToCoTaskMemAnsi"))
			return false;

		Marshal.FreeCoTaskMem(mem);

		return true;
	}

	public static bool TestStringToHGlobalAnsi()
	{
		IntPtr mem = Marshal.StringToHGlobalAnsi(utf16_string);

		if (!check_mem(mem, "TestStringToHGlobalAnsi"))
			return false;

		Marshal.FreeHGlobal(mem);

		return true;
	}

	[StructLayout(LayoutKind.Sequential)]
	struct str_lpstr
	{
		[MarshalAs(UnmanagedType.LPStr)] public string str;
	}

	public static bool TestStringToLpstr()
	{
		var s = new str_lpstr();

		s.str = utf16_string;

		var struct_mem = Marshal.AllocCoTaskMem(Marshal.SizeOf(s));

		Marshal.StructureToPtr(s, struct_mem, false);

		var lpstr = Marshal.ReadIntPtr(struct_mem);

		if (!check_mem(lpstr, "TestStringToLpstr"))
			return false;

		Marshal.DestroyStructure(struct_mem, typeof(str_lpstr));
		Marshal.FreeCoTaskMem(struct_mem);
		return true;
	}

	unsafe public static bool TestLpstrToString()
	{
		var struct_mem = Marshal.AllocCoTaskMem(Marshal.SizeOf(typeof(str_lpstr)));

		fixed (byte* mbstr = teststring) {
			IntPtr pstr = new IntPtr(mbstr);

			Marshal.WriteIntPtr(struct_mem, pstr);

			var s = (str_lpstr)Marshal.PtrToStructure(struct_mem, typeof(str_lpstr));

			string str = s.str;

			Marshal.FreeCoTaskMem(struct_mem);

			if (str != utf16_string)
			{
				Console.WriteLine("PtrToStructure[str_lpstr] returned {0} (length {1})", str, str.Length);
				return false;
			}
		}
		return true;
	}

	[DllImport("kernel32")]
	extern static void RtlMoveMemory(IntPtr dst, [MarshalAs(UnmanagedType.LPStr)] StringBuilder src, IntPtr length);

	public static bool TestBuilderToLpstr()
	{
		StringBuilder sb = new StringBuilder(utf16_string);

		IntPtr lpstr = Marshal.AllocCoTaskMem(teststring.Length);

		RtlMoveMemory(lpstr, sb, new IntPtr(teststring.Length));

		if (!check_mem(lpstr, "TestBuilderToLpstr"))
			return false;

		Marshal.FreeCoTaskMem(lpstr);

		return true;
	}

	[DllImport("kernel32")]
	extern static void RtlMoveMemory([MarshalAs(UnmanagedType.LPStr)] StringBuilder dst, byte[] src, IntPtr length);

	static bool TestLpstrToBuilder()
	{
		StringBuilder sb = new StringBuilder(teststring.Length);

		RtlMoveMemory(sb, teststring, new IntPtr(teststring.Length));

		string str = sb.ToString();

		if (str != utf16_string)
		{
			Console.WriteLine("TestLpstrToBuilder got {0} (length {1})", str, str.Length);
			return false;
		}
		return true;
	}

	[DllImport("kernel32")]
	extern static void RtlMoveMemory([MarshalAs(UnmanagedType.LPStr)] out StringBuilder dst, ref IntPtr src, IntPtr length);

	unsafe static bool TestLpstrToBuilderOut()
	{
		StringBuilder sb;

		IntPtr lpstr = Marshal.AllocCoTaskMem(teststring.Length);

		Marshal.Copy(teststring, 0, lpstr, teststring.Length);

		RtlMoveMemory(out sb, ref lpstr, new IntPtr(Marshal.SizeOf(typeof(IntPtr))));

		// lpstr is freed by pinvoke wrapper

		string str = sb.ToString();

		if (str != utf16_string)
		{
			Console.WriteLine("TestLpstrToBuilderOut got {0} (length {1})", str, str.Length);
			return false;
		}
		return true;
	}

    public static int Main()
    {
		Initialize();
		if (!TestPtrToStringAnsi())
			return 1;
		if (!TestStringToCoTaskMemAnsi())
			return 2;
		if (!TestStringToHGlobalAnsi())
			return 3;
		if (!TestStringToLpstr())
			return 4;
		if (!TestLpstrToString())
			return 5;
		if (!TestBuilderToLpstr())
			return 6;
		if (!TestLpstrToBuilder())
			return 7;
		if (!TestLpstrToBuilderOut())
			return 8;
		return 0;
    }
}
