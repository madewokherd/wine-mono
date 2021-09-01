using System;
using System.Runtime.InteropServices;

static class TestVaList
{
	[DllImport("winemonotest", CallingConvention=CallingConvention.Cdecl)]
	extern static IntPtr get_valist_argument(int index, ArgIterator valist);

	static IntPtr GetVaListArgument(int index, __arglist)
	{
		return get_valist_argument(index, new ArgIterator(__arglist));
	}

	public static int Main()
	{
		if (GetVaListArgument(2, __arglist(5, 6, 7, 8)) != new IntPtr(7))
		{
			Console.WriteLine("Got {0}", GetVaListArgument(2, __arglist(5, 6, 7, 8)));
			return 1;
		}

		return 0;
	}
}

