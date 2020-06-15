
using NUnit.Framework;
using System;
using System.Reflection;
using System.Windows.Media.TextFormatting;

namespace WineMono.Tests.System.Windows.Media.TextFormatting {
	[TestFixture]
	public class TextFormatterTest {
		[Test]
		public void CreateTest ()
		{
			var formatter = TextFormatter.Create ();
			formatter.Dispose();
		}
	}
}
