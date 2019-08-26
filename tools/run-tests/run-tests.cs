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
	HashSet<string> pass_list = new HashSet<string> ();
	HashSet<string> fail_list = new HashSet<string> ();
	Dictionary<string, List<string>> skip_list = new Dictionary<string, List<string>> ();
	Dictionary<string, List<string>> run_list = new Dictionary<string, List<string>> ();

	// actual results
	List<string> passing_tests = new List<string> ();
	List<string> failing_tests = new List<string> ();

	bool test_timed_out;

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
		bool any_passed = false;
		bool any_failed = false;

		while ((line = p.StandardOutput.ReadLine ()) != null)
		{
			Console.WriteLine(line);
			if (line.StartsWith("Running '") && line.EndsWith("' ..."))
			{
				if (current_test != null)
				{
					passing_tests.Add(String.Format("{0}:{1}", test_assembly, current_test));
					any_passed = true;
				}
				current_test = line.Substring(9, line.Length - 14);
			}
			else if (line.StartsWith(String.Format("{0} failed: got ", current_test)))
			{
				failing_tests.Add(String.Format("{0}:{1}", test_assembly, current_test));
				current_test = null;
				any_failed = true;
			}
			else if (line.StartsWith("Regression tests: ") &&
				line.Contains(" ran, ") && line.Contains(" failed in "))
			{
				if (current_test != null)
				{
					passing_tests.Add(String.Format("{0}:{1}", test_assembly, current_test));
					any_passed = true;
					current_test = null;
				}
			}
		}

		if (current_test != null)
		{
			p.WaitForExit();
			failing_tests.Add(String.Format("{0}:{1}", test_assembly, current_test));
		}

		if (test_timed_out)
		{
			failing_tests.Add(test_assembly);
			Console.WriteLine("Test timed out: {0}", test_assembly);
		}
		else if (p.ExitCode == 0 && !any_failed)
		{
			passing_tests.Add(test_assembly);
			Console.WriteLine("Test succeeded: {0}", test_assembly);
		}
		else if (any_passed)
		{
			Console.WriteLine("Some tests succeeded: {0}", test_assembly);
		}
		else
		{
			failing_tests.Add(test_assembly);
			Console.WriteLine("Test failed({0}): {1}", p.ExitCode, test_assembly);
		}
	}

	void run_mono_test_exe(string path, string arch)
	{
		string testname = Path.GetFileNameWithoutExtension(path);
		string fulltestname = String.Format("{0}.{1}", arch, testname);
		test_timed_out = false;

		List<string> runs = new List<string> ();
		if (run_list.Count != 0)
		{
			bool run=false;
			if (run_list.ContainsKey(testname))
			{
				run = true;
				if (run_list[testname] != null)
				{
					runs.AddRange(run_list[testname]);
				}
			}
			if (run_list.ContainsKey(fulltestname))
			{
				run = true;
				if (run_list[fulltestname] != null)
				{
					runs.AddRange(run_list[fulltestname]);
				}
			}
			if (!run)
				return;
		}

		List<string> skips = new List<string> ();
		if (skip_list.ContainsKey(testname))
		{
			if (skip_list[testname] == null)
			{
				Console.WriteLine("Skipping {0}", fulltestname);
				return;
			}
			skips.AddRange(skip_list[testname]);
		}
		if (skip_list.ContainsKey(fulltestname))
		{
			if (skip_list[fulltestname] == null)
			{
				Console.WriteLine("Skipping {0}", fulltestname);
				return;
			}
			skips.AddRange(skip_list[fulltestname]);
		}

		Console.WriteLine("Starting test: {0}", fulltestname);
		Process p = new Process ();
		p.StartInfo = new ProcessStartInfo (path);
		p.StartInfo.Arguments = "--verbose";
		foreach (string test in skips)
		{
			p.StartInfo.Arguments = String.Format("{0} --exclude-test \"{1}\"",
				p.StartInfo.Arguments, test);
		}
		foreach (string test in runs)
		{
			p.StartInfo.Arguments = String.Format("{0} --run-only \"{1}\"",
				p.StartInfo.Arguments, test);
		}
		p.StartInfo.UseShellExecute = false;
		p.StartInfo.RedirectStandardOutput = true;
		p.StartInfo.WorkingDirectory = Path.GetDirectoryName(path);
		p.Start();
		Thread t = new Thread(process_mono_test_output);
		t.Start(Tuple.Create(p, fulltestname));
		p.WaitForExit(5 * 60 * 1000); // 5 minutes
		if (!p.HasExited)
		{
			test_timed_out = true;
			p.Kill();
		}
		t.Join(10 * 1000);
		if (t.IsAlive)
		{
			p.StandardOutput.Close();
			t.Join();
		}
	}

	void run_mono_test_dir(string path, string arch)
	{
		foreach (string filename in Directory.EnumerateFiles(path, "*.exe"))
		{
			run_mono_test_exe(filename, arch);
		}
	}

	void add_to_testlist(string str, Dictionary<string, List<string>> testlist)
	{
		if (str.Contains(":"))
		{
			int index = str.IndexOf(':');
			string assembly = str.Substring(0, index);
			string test = str.Substring(index+1);
			List <string> l;
			if (!testlist.TryGetValue(assembly, out l) || l == null)
			{
				l = testlist[assembly] = new List<string>();
			}
			l.Add(test);
		}
		else
		{
			testlist.TryAdd(str, null);
		}
	}

	void read_testlist(string filename, Dictionary<string, List<string>> testlist)
	{
		using (StreamReader sr = new StreamReader(filename))
		{
			string line;
			while ((line = sr.ReadLine()) != null)
			{
				if (line.Contains("#"))
				{
					line = line.Substring(0, line.IndexOf('#'));
				}
				foreach (string test in line.Split(new char[] {' '}))
				{
					string trtest = test.Trim();
					if (trtest != "")
						add_to_testlist(trtest, testlist);
				}
			}
		}
	}

	void read_stringlist(string filename, HashSet<string> testlist)
	{
		using (StreamReader sr = new StreamReader(filename))
		{
			string line;
			while ((line = sr.ReadLine()) != null)
			{
				if (line.Contains("#"))
				{
					line = line.Substring(0, line.IndexOf('#'));
				}
				foreach (string test in line.Split(new char[] {' '}))
				{
					string trtest = test.Trim();
					if (trtest != "")
						testlist.Add(trtest);
				}
			}
		}
	}

	int main(string[] arguments)
	{
		int result;

		foreach (string argument in arguments)
		{
			if (argument.StartsWith("-write-passing:"))
				passing_output_path = argument.Substring(15);
			else if (argument.StartsWith("-write-failing:"))
				failing_output_path = argument.Substring(15);
			else if (argument.StartsWith("-skip:"))
				add_to_testlist(argument.Substring(6), skip_list);
			else if (argument.StartsWith("-skip-list:"))
				read_testlist(argument.Substring(11), skip_list);
			else if (argument.StartsWith("-run:"))
				add_to_testlist(argument.Substring(5), run_list);
			else if (argument.StartsWith("-run-list:"))
				read_testlist(argument.Substring(10), run_list);
			else if (argument.StartsWith("-pass-list:"))
				read_stringlist(argument.Substring(11), pass_list);
			else if (argument.StartsWith("-fail-list:"))
				read_stringlist(argument.Substring(11), fail_list);
			else
			{
				Console.WriteLine("Unrecognized argument: {0}", argument);
				return 1;
			}
		}

		run_mono_test_dir(Path.Combine(BasePath, "tests-x86"), "x86");
		run_mono_test_dir(Path.Combine(BasePath, "tests-x86_64"), "x86_64");

		result = failing_tests.Count;

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

		if (pass_list.Count != 0)
		{
			var unexpected_pass = new List<string> ();
			foreach (string name in passing_tests)
				if (!pass_list.Contains(name) &&
					!pass_list.Contains(name.Split(new char[]{'.'}, 2)[1]))
					unexpected_pass.Add(name);
			if (unexpected_pass.Count != 0)
			{
				Console.WriteLine("The following tests passed but were not in pass-list:");
				Console.WriteLine();
				foreach (string name in unexpected_pass)
					Console.WriteLine(name);
				Console.WriteLine();
			}
		}

		if (fail_list.Count != 0)
		{
			var unexpected_fail = new List<string> ();
			foreach (string name in failing_tests)
				if (!fail_list.Contains(name) &&
					!fail_list.Contains(name.Split(new char[]{'.'}, 2)[1]))
					unexpected_fail.Add(name);
			if (unexpected_fail.Count != 0)
			{
				Console.WriteLine("The following tests failed but were not in fail-list:");
				Console.WriteLine();
				foreach (string name in unexpected_fail)
					Console.WriteLine(name);
				Console.WriteLine();
			}
			result = unexpected_fail.Count;
		}

		Console.WriteLine("{0} tests passed, {1} tests failed",
			passing_tests.Count, failing_tests.Count);

		return result;
	}

	static int Main(string[] arguments)
	{
		RunTests instance = new RunTests();
		return instance.main(arguments);
	}
}
