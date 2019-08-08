using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Threading;

class RunTests
{
	string ExePath;
	string BasePath;

	string passing_output_path;
	string failing_output_path;

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

	void process_mono_test_output(object o)
	{
		var t = (Tuple<Process,string>)o;
		Process p = t.Item1;
		string test_assembly = t.Item2;
		string line;
		string current_test = null;

		while ((line = p.StandardOutput.ReadLine ()) != null)
		{
			Console.WriteLine(line);
			if (line.StartsWith("Running '") && line.EndsWith("' ..."))
			{
				if (current_test != null)
				{
					passing_tests.Add(String.Format("{0}:{1}", test_assembly, current_test));
				}
				current_test = line.Substring(9, line.Length - 14);
			}
			else if (line.StartsWith(String.Format("{0} failed: got ", current_test)))
			{
				failing_tests.Add(String.Format("{0}:{1}", test_assembly, current_test));
				current_test = null;
			}
		}

		if (current_test != null)
		{
			p.WaitForExit();
			if (p.ExitCode == 0)
			{
				passing_tests.Add(String.Format("{0}:{1}", test_assembly, current_test));
			}
			else
			{
				failing_tests.Add(String.Format("{0}:{1}", test_assembly, current_test));
			}
		}
	}

	void run_mono_test_exe(string path, string arch)
	{
		string testname = Path.GetFileNameWithoutExtension(path);
		string fulltestname = String.Format("{0}.{1}", arch, testname);
		bool timeout = false;

		// TODO: check skip list

		Console.WriteLine("Starting test: {0}", fulltestname);
		Process p = new Process ();
		p.StartInfo = new ProcessStartInfo (path, "--verbose");
		p.StartInfo.UseShellExecute = false;
		p.StartInfo.RedirectStandardOutput = true;
		p.Start();
		Thread t = new Thread(process_mono_test_output);
		t.Start(Tuple.Create(p, fulltestname));
		p.WaitForExit(5 * 60 * 1000); // 5 minutes
		if (!p.HasExited)
		{
			p.Kill();
			timeout = true;
		}
		t.Join();
		if (p.ExitCode == 0)
		{
			passing_tests.Add(fulltestname);
			Console.WriteLine("Test succeeded: {0}", fulltestname);
		}
		else if (passing_tests[passing_tests.Count-1].StartsWith(fulltestname+":"))
		{
			Console.WriteLine("Some tests succeeded: {0}", fulltestname);
		}
		else
		{
			failing_tests.Add(fulltestname);
			if (timeout)
				Console.WriteLine("Test timed out: {0}", fulltestname);
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
		foreach (string argument in arguments)
		{
			if (argument.StartsWith("-write-passing:"))
				passing_output_path = argument.Substring(15);
			else if (argument.StartsWith("-write-failing:"))
				failing_output_path = argument.Substring(15);
			else
			{
				Console.WriteLine("Unrecognized argument: {0}", argument);
				return 1;
			}
		}

		run_mono_test_dir(Path.Combine(BasePath, "tests-x86"), "x86");
		run_mono_test_dir(Path.Combine(BasePath, "tests-x86_64"), "x86_64");

		if (!String.IsNullOrEmpty(passing_output_path))
		{
			using (var f = new StreamWriter(passing_output_path))
			{
				foreach (string name in passing_tests)
					f.WriteLine(name);
			}
		}

		if (!String.IsNullOrEmpty(failing_output_path))
		{
			using (var f = new StreamWriter(failing_output_path))
			{
				foreach (string name in failing_tests)
					f.WriteLine(name);
			}
		}

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
