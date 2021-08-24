using System;
using System.Runtime.InteropServices;

static class TestCctor
{
	[DllImport("kernel32", CharSet=CharSet.Unicode, EntryPoint="LoadLibraryW", CallingConvention=CallingConvention.StdCall)]
	public static extern IntPtr LoadLibrary(string filename);

	[DllImport("nativelibrary.dll", CallingConvention=CallingConvention.Cdecl, EntryPoint="test_native_fn")]
	public static extern int dllimport(int input);

	static TestCctor ()
	{
		if (LoadLibrary("vstests\\nativelibrary.dll") == IntPtr.Zero)
			throw new Exception("LoadLibrary failed");
	}
}

static class Test
{
	static public int Main()
	{
		if (TestCctor.dllimport(-5) != 0)
			return 1;
		return 0;
	}
}

