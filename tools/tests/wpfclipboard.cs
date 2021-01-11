
using System;
using System.Windows;

public class ClipboardTest {
	[STAThread]
	public static int Main ()
	{
		Clipboard.Clear();
		string text = Clipboard.GetText();
		if (text != string.Empty)
		{
			Console.WriteLine("got wrong clipboard text contents: {0}", text);
			return 1;
		}
		Clipboard.SetText("Clipboard test string");
		text = Clipboard.GetText();
		if (text != "Clipboard test string")
		{
			Console.WriteLine("got wrong clipboard text contents: {0}", text);
			return 1;
		}
		return 0;
	}
}
