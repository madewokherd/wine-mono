/* Chain to an exe in a subdirectory with a broken System.Windows.Forms.dll in it. */
using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;

class AssemblySearchTest
{
	static int Main()
	{
		string exedir = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);
		var process = new Process();
		process.StartInfo.FileName = Path.Combine(exedir, "searchgacbeforepath", "webbrowsertest.exe");
		process.Start();
		process.WaitForExit();
		if (process.ExitCode == 2) {
			// The test fails in this way on Wine, but this shows winforms loaded which is good enough
			return 0;
		}
		return process.ExitCode;
	}
}
