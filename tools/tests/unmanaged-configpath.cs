using System;
using System.Configuration;
using System.Diagnostics;
using System.IO;
using System.Reflection;

namespace Tests {

public class UnmanagedConfigPathTest
{
	public static int Main()
	{
		string exename = Assembly.GetExecutingAssembly().Location;
		string exedir = Path.GetDirectoryName(exename);
		var process = new Process();
		process.StartInfo.FileName = Path.Combine(exedir, "vstests", "call-method.exe");
		process.StartInfo.Arguments = String.Format("\"{0}\" Tests.UnmanagedConfigPathTest TestConfigPath \"{1}\"",
			exename,
			Path.Combine(exedir, "vstests", "call-method.exe.config"));
		process.StartInfo.RedirectStandardError = false;
		process.StartInfo.RedirectStandardOutput = false;
		process.StartInfo.UseShellExecute = false;
		process.Start();
		process.WaitForExit();
		return process.ExitCode;
	}

	public static int TestConfigPath(string expected)
	{
		var config = ConfigurationManager.OpenExeConfiguration(ConfigurationUserLevel.None);
		if (config.FilePath != expected)
		{
			Console.WriteLine("Expected {0} got {1}", expected, config.FilePath);
			return 1;
		}
		return 0;
	}
}

}
