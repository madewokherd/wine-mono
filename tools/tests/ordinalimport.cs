using System;
using System.Runtime.InteropServices;

static class TestOrdinalImport
{
	[DllImport("shlwapi", EntryPoint="#33")]
	unsafe extern static bool IsCharDigitW(char ch);

    public static int Main()
    {
		if (!IsCharDigitW('2'))
			return 1;
		if (IsCharDigitW('s'))
			return 2;
		return 0;
    }
}
