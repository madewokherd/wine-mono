using System;
using System.Runtime.InteropServices;

static class ReleaseBadPtr
{
    public unsafe static int Main()
    {
		var x = Marshal.StringToCoTaskMemUni("T\uffffh\uffffis is a bad pointer, probably");
		int result = Marshal.Release(x);
		if (result != 0)
		{
			Console.WriteLine("Marshal.Release returned {0}");
			return 1;
		}
		Console.WriteLine("Success");
		Marshal.FreeCoTaskMem(x);
		return 0;
    }
}
