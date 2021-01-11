
using System;
using System.Diagnostics;

static class TestProcessNames
{
    public static int Main()
    {
		foreach (var p in Process.GetProcesses())
		{
			Console.WriteLine(p.Id);
			try
			{
				Console.WriteLine(p.ProcessName);
			}
			catch (InvalidOperationException)
			{
				if (p.HasExited)
					Console.WriteLine("[Process Exited]");
				else
					throw;
			}
		}
		return 0;
    }
}
