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
		return process.ExitCode;
	}
}
