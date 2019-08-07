using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;

class RunTests
{
	string ExePath;
	string BasePath;

	// expected results
	//HashSet<string> pass_list;
	//HashSet<string> todo_list;
	//Dictionary<string, List<string>> skip_list;

	// actual results
	List<string> passing_tests = new List<string> ();
	List<string> failing_tests = new List<string> ();

	RunTests ()
	{
		ExePath = Environment.GetCommandLineArgs()[0];
		BasePath = Path.GetDirectoryName(ExePath);
	}

	void run_mono_test_exe(string path, string arch)
	{
		string testname = Path.GetFileNameWithoutExtension(path);
		string fulltestname = String.Format("{0}.{1}", arch, testname);

		// TODO: check skip list

		Console.WriteLine("Starting test: {0}", fulltestname);
		Process p = new Process ();
		p.StartInfo = new ProcessStartInfo (path, "--verbose");
		p.StartInfo.UseShellExecute = false;
		// TODO: redirect standard out, parse output
		p.Start();
		p.WaitForExit(5 * 60 * 1000); // 5 minutes
		if (p.HasExited && p.ExitCode == 0)
		{
			passing_tests.Add(fulltestname);
			Console.WriteLine("Test succeeded: {0}", fulltestname);
		}
		else
		{
			failing_tests.Add(fulltestname);
			if (!p.HasExited)
			{
				p.Kill();
				Console.WriteLine("Test timed out: {0}", fulltestname);
			}
			else
				Console.WriteLine("Test failed: {0}", fulltestname);
		}
	}

	void run_mono_test_dir(string path, string arch)
	{
		foreach (string filename in Directory.EnumerateFiles(path, "*.exe"))
		{
			run_mono_test_exe(filename, arch);
		}
	}

	int main(string[] arguments)
	{
		run_mono_test_dir(Path.Combine(BasePath, "tests-x86"), "x86");
		run_mono_test_dir(Path.Combine(BasePath, "tests-x86_64"), "x86_64");

		Console.WriteLine("{0} tests passed, {1} tests failed",
			passing_tests.Count, failing_tests.Count);

		return failing_tests.Count;
	}

	static int Main(string[] arguments)
	{
		RunTests instance = new RunTests();
		return instance.main(arguments);
	}
}
