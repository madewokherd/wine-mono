
// CSCFLAGS=-r:System.Windows.Forms.dll

using System;
using System.Runtime.InteropServices;
using System.Threading;
using System.Windows.Forms;

public class TestComFinalizerSync
{
    [DllImport ("libtest")]
	public static extern int mono_test_marshal_com_object_create (out IntPtr pUnk);

	Thread winformsthread;
	Form form;
	IntPtr comptr;
	Object comobject;
	Exception threadexception;

	public static void DoNothing()
	{
		Console.WriteLine("DoNothing");
	}

	public void ThreadProc()
	{
		try
		{
			form = new Form();
			form.Show();

			if (!form.IsHandleCreated)
			{
				throw new Exception("Form handle not created");
			}

			if (!(SynchronizationContext.Current is WindowsFormsSynchronizationContext))
			{
				throw new Exception("WindowsFormsSynchronizationContext not installed");
			}

			mono_test_marshal_com_object_create(out comptr);

			comobject = Marshal.GetObjectForIUnknown(comptr);
		}
		catch (Exception e)
		{
			threadexception = e;
		}
	}

	static void WaitForHandleDestroyed(Control c)
	{
		while (c.IsHandleCreated)
		{
			try
			{
				c.BeginInvoke(new Action(DoNothing));
			}
			catch (InvalidOperationException)
			{
				break;
			}
			Thread.Sleep(100);
		}
	}

	public int Run()
	{
		winformsthread = new Thread(new ThreadStart(ThreadProc));

		winformsthread.SetApartmentState(ApartmentState.STA);

		winformsthread.Start();

		winformsthread.Join();

		if (threadexception != null)
		{
			Console.WriteLine(threadexception);
			return 1;
		}

		WaitForHandleDestroyed(form);

		comobject = null;

		GC.Collect();

		var refcount = Marshal.AddRef(comptr);

		if (refcount != 1)
		{
			Console.WriteLine("unexpected refcount: {0}", refcount);
		}

		return 0;
	}

	public static int Main()
	{
		var test = new TestComFinalizerSync();
		return test.Run();
	}
}
