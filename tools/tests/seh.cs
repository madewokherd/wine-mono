using System;
using System.Runtime.ExceptionServices;
using System.Runtime.InteropServices;
using System.Text;

static class TestSeh
{
	[DllImport("kernel32")]
	extern static void RaiseException(uint code, int flags, int argc, [In] IntPtr[] arguments);

	[DllImport("msvcrt", CallingConvention=CallingConvention.Cdecl)]
	extern static IntPtr memcpy(IntPtr dest, IntPtr src, IntPtr count);

	[HandleProcessCorruptedStateExceptions]
	public static int Main()
	{
		bool got_exception = false;
		try
		{
			RaiseException(0x88888888, 0, 0, null);
		}
		catch (SEHException)
		{
			Console.WriteLine("1");
			got_exception = true;
		}
		if (!got_exception)
			return 1;

		got_exception = false;
		try
		{
			RaiseException(0xc0000017, 0, 0, null);
		}
		catch (OutOfMemoryException)
		{
			Console.WriteLine("2");
			got_exception = true;
		}
		if (!got_exception)
			return 2;

		got_exception = false;
		try
		{
			memcpy(IntPtr.Zero, IntPtr.Zero, new IntPtr(1));
		}
		catch (AccessViolationException)
		{
			Console.WriteLine("3");
			got_exception = true;
		}
		if (!got_exception)
			return 3;
		return 0;
	}
}
