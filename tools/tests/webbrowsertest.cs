
using System;
using System.Windows.Forms;

// CSCFLAGS=-r:System.Windows.Forms.dll

static class WebBrowserTest
{
	[STAThreadAttribute]
    public static int Main()
    {
		using (var wb = new WebBrowser())
		{
			wb.DocumentText = null;
			if (wb.ActiveXInstance == null)
			{
				Console.WriteLine("ActiveXInstance == null");
				return 1;
			}
			if (wb.DocumentText != "<HTML></HTML>\0")
			{
				Console.WriteLine(wb.DocumentText);
				return 2;
			}
		}
		Console.WriteLine("success");
		return 0;
    }
}
