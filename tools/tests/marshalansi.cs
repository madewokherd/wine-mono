
using System;
using System.Runtime.InteropServices;

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

    public static int Main()
    {
		Initialize();
		if (!TestPtrToStringAnsi())
			return 1;
		if (!TestStringToCoTaskMemAnsi())
			return 2;
		if (!TestStringToHGlobalAnsi())
			return 3;
		return 0;
    }
}
