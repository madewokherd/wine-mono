/* Having a native or mixed-mode .exe in our tests-x86 dir causes
 * problems, and in some cases we want to control what dependencies
 * are in what path, so just chain to the real exe. */
using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;

class MixedModeExe
{
	static int Main()
	{
		string exedir = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);
		var process = new Process();
		process.StartInfo.FileName = Path.Combine(exedir, "vstests-native", "mixedmode-managedcaller.exe");
		process.Start();
		process.WaitForExit();
		return process.ExitCode == 0 ? 1 : 0;
	}
}
