using System;
using System.Diagnostics;

class CscWrapper
{

#if VERSION20
    const string VERSION_STRING = "2.0-api";
#elif VERSION40
    const string VERSION_STRING = "4.0-api";
#endif

    static void Main(string[] arguments)
    {
        var addStdlib = true;

        for (int i = 0; i< arguments.Length; i++)
        {
            if (arguments[i] == "/nostdlib" || arguments[i] == "-nostdlib")
               addStdlib = false;
            arguments[i] = '"' + arguments[i] + '"';
        }

        var versionArguments = "";
        if (addStdlib)
            versionArguments = String.Format(@"/nostdlib /r:c:\windows\mono\mono-2.0\lib\mono\{0}\mscorlib.dll /lib:c:\windows\mono\mono-2.0\lib\mono\{0} ", VERSION_STRING);

        var process = new Process();
        process.StartInfo.FileName = @"c:\windows\mono\mono-2.0\lib\mono\4.5\mcs.exe";
        process.StartInfo.Arguments = versionArguments + String.Join(" ", arguments);
        process.StartInfo.CreateNoWindow = true;
        process.StartInfo.UseShellExecute = false;
        process.StartInfo.RedirectStandardOutput = true;
        process.OutputDataReceived += (sender, args) => Console.WriteLine(args.Data);
        process.Start();
        process.BeginOutputReadLine();
        process.WaitForExit();
    }
}

