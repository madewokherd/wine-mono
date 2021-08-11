//
// thread-exit-bk.cs:
//
//  Testing background thread behavior on application exit
//

using System;
using System.Runtime.InteropServices;
using System.Threading;

public class Test
{
	public static IntPtr evt;
	public static bool isWindows;

	[DllImport("kernel32.dll", EntryPoint="CreateEventW")]
	public static extern IntPtr CreateEvent(IntPtr attr, [MarshalAs(UnmanagedType.Bool)]bool manual, [MarshalAs(UnmanagedType.Bool)]bool initialState, [MarshalAs(UnmanagedType.LPWStr)]string name);

	[DllImport("kernel32.dll")]
	public static extern uint WaitForSingleObject(IntPtr handle, int ms);

	public static void bkMethod ()
	{
		try
		{
			WaitForSingleObject(evt, -1);
			Console.WriteLine("[FAIL] Background thread stopped waiting");
			System.Environment.Exit(1);
		}
		catch (Exception e)
		{
			Console.WriteLine($"[FAIL] Exception in background thread: {e}");
			System.Environment.Exit(1);
		}
	}

	public static void busyMethod ()
	{
		try
		{
			while (true) { }
		}
		catch (Exception e)
		{
			Console.WriteLine($"[FAIL] Exception in busy background thread: {e}");
			System.Environment.Exit(2);
		}
	}

	public static void fgMethod ()
	{
		try
		{
			WaitForSingleObject(evt, 1000);
			Console.WriteLine("Foreground thread stopped waiting, test should finish");
		}
		catch (Exception e)
		{
			Console.WriteLine($"[FAIL] Exception in foreground thread: {e}");
			System.Environment.Exit(3);
		}
	}

	public static int Main ()
	{
		evt = CreateEvent(IntPtr.Zero, true, false, null);

		Thread bkThread = new Thread(new ThreadStart(bkMethod));
		Thread busyThread = new Thread(new ThreadStart(busyMethod));
		Thread fgThread = new Thread(new ThreadStart(fgMethod));
		bkThread.IsBackground = true;
		busyThread.IsBackground = true;

		Console.WriteLine("Starting background thread...");
		bkThread.Start();
		Console.WriteLine("Starting busy background thread...");
		busyThread.Start();
		Console.WriteLine("Starting foreground thread...");
		fgThread.Start();
		Console.WriteLine("Threads started");

		return 0;
	}
}
