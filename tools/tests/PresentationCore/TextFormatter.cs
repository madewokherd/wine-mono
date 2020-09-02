
using NUnit.Framework;
using System;
using System.Collections.Generic;
using System.Globalization;
using System.Reflection;
using System.Windows;
using System.Windows.Media;
using System.Windows.Media.TextFormatting;

namespace WineMono.Tests.System.Windows.Media.TextFormatting {
	public class LoggingTextSource : TextSource
	{
		public List<string> destination;

		public List<TextRun> contents = new List<TextRun> ();
		public int last_index = 0;

		public LoggingTextSource(List<string> destination)
		{
			this.destination = destination;
		}

		public void AddContents(TextRun source)
		{
			contents.Add(source);
		}

		public void AddContents(string text, TextRunProperties props)
		{
			for (int i=0; i<text.Length; i++)
			{
				AddContents(new TextCharacters(text, i, text.Length - i, props));
			}
		}

		public void AddContents(string text, string name)
		{
			AddContents(text, new LoggingTextRunProperties(destination, name));
		}

		public void AddContents(string text)
		{
			AddContents(text, text);
		}

		public void Log(string info)
		{
			if (!destination.Contains(info))
				destination.Add(info);
		}

		public override TextSpan<CultureSpecificCharacterBufferRange>
			GetPrecedingText (int textSourceCharacterIndexLimit)
		{
			throw new NotImplementedException("LoggingTextSource.GetPrecedingText");
		}

		public override int GetTextEffectCharacterIndexFromTextSourceCharacterIndex (int textSourceCharacterIndex)
		{
			throw new NotImplementedException("LoggingTextSource.GetTextEffectCharacterIndexFromTextSourceCharacterIndex");
		}

		public override TextRun GetTextRun(int textSourceCharacterIndex)
		{
			Log(String.Format("GetTextRun({0})", textSourceCharacterIndex));
			if (textSourceCharacterIndex < 0)
				throw new ArgumentOutOfRangeException("textSourceCharacterIndex", "value must be greater than 0");

			if (textSourceCharacterIndex >= contents.Count)
				return new TextEndOfParagraph(1);

			return contents[textSourceCharacterIndex];
		}
	}

	public class LoggingTextRunProperties : TextRunProperties
	{
		public List<string> destination;
		public string name;

		public CultureInfo cultureInfo = CultureInfo.InvariantCulture;
		public TextDecorationCollection textDecorations = null;
		public TextEffectCollection textEffects = null;
		public Typeface typeface = new Typeface("Arial");
		public double fontRenderingEmSize = 128;

		public LoggingTextRunProperties(List<string> destination, string name)
		{
			this.destination = destination;
			this.name = name;
		}

		public void Log(string info)
		{
			info = string.Format("{0}.{1}", name, info);
			if (!destination.Contains(info))
				destination.Add(info);
		}

		public override double FontHintingEmSize
		{
			get
			{
				throw new NotImplementedException("LoggingTextRunProperties.FontHintingEmSize");
			}
		}

		public override double FontRenderingEmSize
		{
			get
			{
				Log("FontRenderingEmSize");
				return fontRenderingEmSize;
			}
		}

		public override TextDecorationCollection TextDecorations
		{
			get
			{
				Log("TextDecorations");
				return textDecorations;
			}
		}

		public override CultureInfo CultureInfo
		{
			get
			{
				Log("CultureInfo");
				return cultureInfo;
			}
		}

		public override Brush ForegroundBrush
		{
			get
			{
				throw new NotImplementedException("LoggingTextRunProperties.ForegroundBrush");
			}
		}

		public override TextEffectCollection TextEffects
		{
			get
			{
				Log("TextEffects");
				return textEffects;
			}
		}

		public override Typeface Typeface
		{
			get
			{
				Log("Typeface");
				return typeface;
			}
		}

		public override Brush BackgroundBrush
		{
			get
			{
				throw new NotImplementedException("LoggingTextRunProperties.BackgroundBrush");
			}
		}
	}

	public class LoggingTextParagraphProperties : TextParagraphProperties
	{
		public List<string> destination;

		public TextRunProperties defaultTextRunProperties;
		public bool firstLineInParagraph = true;
		public FlowDirection flowDirection = FlowDirection.LeftToRight;
		public double indent = 0;
		public double lineheight = 0;
		public TextAlignment textAlignment = TextAlignment.Left;
		public TextMarkerProperties textMarkerProperties = null;
		public TextWrapping textWrapping = TextWrapping.Wrap;
		public bool alwaysCollapsible = false;

		public LoggingTextParagraphProperties(List<string> destination)
		{
			this.destination = destination;
			defaultTextRunProperties = new LoggingTextRunProperties(destination, "DefaultTextRunProperties");
		}

		public void Log(string info)
		{
			if (!destination.Contains(info))
				destination.Add(info);
		}

		public override bool AlwaysCollapsible
		{
			get
			{
				Log("AlwaysCollapsible");
				return alwaysCollapsible;
			}
		}

		public override TextWrapping TextWrapping
		{
			get
			{
				Log("TextWrapping");
				return textWrapping;
			}
		}

		public override bool FirstLineInParagraph
		{
			get
			{
				Log("FirstLineInParagraph");
				return firstLineInParagraph;
			}
		}

		public override FlowDirection FlowDirection
		{
			get
			{
				Log("FlowDirection");
				return flowDirection;
			}
		}

		public override double Indent
		{
			get
			{
				Log("Indent");
				return indent;
			}
		}

		public override TextAlignment TextAlignment
		{
			get
			{
				Log("TextAlignment");
				return textAlignment;
			}
		}

		public override TextMarkerProperties TextMarkerProperties
		{
			get
			{
				Log("TextMarkerProperties");
				return textMarkerProperties;
			}
		}

		public override TextRunProperties DefaultTextRunProperties
		{
			get
			{
				Log("DefaultTextRunProperties");
				return defaultTextRunProperties;
			}
		}

		public override double LineHeight
		{
			get
			{
				Log("LineHeight");
				return lineheight;
			}
		}
	}

	[TestFixture]
	public class TextFormatterTest {
		[Test]
		public void CreateTest ()
		{
			var formatter = TextFormatter.Create ();
			formatter.Dispose();
		}

		public void AssertTextRun(TextRun expected, TextRun actual, string name)
		{
			Assert.AreEqual(expected.GetType(), actual.GetType(), name);
			Assert.AreEqual(expected.Length, actual.Length, String.Format("{0} Length", name));
			Assert.AreEqual(expected.CharacterBufferReference, actual.CharacterBufferReference, name);
		}

		public void AssertTextRunSpans(int[] lengths, TextRun[] values, TextLine line)
		{
			int count=0;
			foreach (var span in line.GetTextRunSpans())
			{
				Assert.AreEqual(lengths[count], span.Length, String.Format("lengths[{0}]", count));
				AssertTextRun(values[count], span.Value, String.Format("values[{0}]", count));
				count += 1;
			}
			Assert.AreEqual(lengths.Length, count, "TextLine.GetTextRunSpans() count");
		}

		[Test]
		public void SingleWordTest ()
		{
			using (var formatter = TextFormatter.Create ())
			{
				List<string> log = new List<string> ();
				var textSource = new LoggingTextSource(log);
				textSource.AddContents("test");
				textSource.AddContents(new TextEndOfLine(1));
				var textParagraphProperties = new LoggingTextParagraphProperties(log);
				log.Clear();
				var line = formatter.FormatLine (textSource, 0, 256.0, textParagraphProperties, null);
				Assert.AreEqual(147.18+0.02/3.0, line.Height, "line.Height");
				Assert.AreEqual(5, line.Length, "line.Length");
				Assert.AreEqual(1, line.NewlineLength, "line.NewlineLength");
				Assert.AreEqual(117.97, line.Baseline, 0.000000001, "line.Baseline");
				Assert.AreEqual(206.31+0.01/3.0, line.Width, "line.Width");
				Assert.IsFalse(line.HasOverflowed, "line.HasOverflowed");
				Assert.AreEqual(206.31+0.01/3.0, line.WidthIncludingTrailingWhitespace, "line.WidthIncludingTrailingWhitespace");
				AssertTextRunSpans(
					new int[] { 4, 1 },
					new TextRun[] { textSource.contents[0], new TextEndOfLine(1) },
					line);
				Assert.AreEqual(new string[] {
					"DefaultTextRunProperties",
					"DefaultTextRunProperties.Typeface",
					"DefaultTextRunProperties.FontRenderingEmSize",
					"Indent",
					"LineHeight",
					"FlowDirection",
					"AlwaysCollapsible",
					"TextAlignment",
					"FirstLineInParagraph",
					"TextMarkerProperties",
					"TextWrapping",
					"GetTextRun(0)",
					"test.FontRenderingEmSize",
					"test.CultureInfo",
					"test.Typeface",
					"test.TextEffects",
					"test.TextDecorations",
					"GetTextRun(4)",
					}, log);
				Assert.IsNull(line.GetTextLineBreak(), "GetTextLineBreak");
				Assert.AreEqual(0, line.Start, "line.Start");
			}
		}

		[Test]
		public void SingleWordTahomaTest ()
		{
			using (var formatter = TextFormatter.Create ())
			{
				List<string> log = new List<string> ();
				var textProps = new LoggingTextRunProperties(log, "Tahoma");
				textProps.typeface = new Typeface("Tahoma");
				var textSource = new LoggingTextSource(log);
				textSource.AddContents("test", textProps);
				textSource.AddContents(new TextEndOfLine(1));
				var textParagraphProperties = new LoggingTextParagraphProperties(log);
				log.Clear();
				var line = formatter.FormatLine (textSource, 0, 256.0, textParagraphProperties, null);
				Assert.AreEqual(154.5, line.Height, "line.Height");
				Assert.AreEqual(5, line.Length, "line.Length");
				Assert.AreEqual(1, line.NewlineLength, "line.NewlineLength");
				Assert.AreEqual(128.06+0.01/3.0, line.Baseline, "line.Baseline");
				Assert.AreEqual(210.12+0.02/3.0, line.Width, 0.000000001, "line.Width");
				Assert.IsFalse(line.HasOverflowed, "line.HasOverflowed");
				Assert.AreEqual(210.12+0.02/3.0, line.WidthIncludingTrailingWhitespace, 0.000000001, "line.WidthIncludingTrailingWhitespace");
				AssertTextRunSpans(
					new int[] { 4, 1 },
					new TextRun[] { textSource.contents[0], new TextEndOfLine(1) },
					line);
				Assert.AreEqual(new string[] {
					"DefaultTextRunProperties",
					"DefaultTextRunProperties.Typeface",
					"DefaultTextRunProperties.FontRenderingEmSize",
					"Indent",
					"LineHeight",
					"FlowDirection",
					"AlwaysCollapsible",
					"TextAlignment",
					"FirstLineInParagraph",
					"TextMarkerProperties",
					"TextWrapping",
					"GetTextRun(0)",
					"Tahoma.FontRenderingEmSize",
					"Tahoma.CultureInfo",
					"Tahoma.Typeface",
					"Tahoma.TextEffects",
					"Tahoma.TextDecorations",
					"GetTextRun(4)",
					}, log);
				Assert.IsNull(line.GetTextLineBreak(), "GetTextLineBreak");
				Assert.AreEqual(0, line.Start, "line.Start");
			}
		}

		[Test]
		public void EmptyLineTest ()
		{
			using (var formatter = TextFormatter.Create ())
			{
				List<string> log = new List<string> ();
				var textSource = new LoggingTextSource(log);
				textSource.AddContents(new TextEndOfLine(1));
				var textParagraphProperties = new LoggingTextParagraphProperties(log);
				Assert.AreEqual(2355/2048.0, textParagraphProperties.DefaultTextRunProperties.Typeface.FontFamily.LineSpacing);
				log.Clear();
				var line = formatter.FormatLine (textSource, 0, 256.0, textParagraphProperties, null);
				Assert.AreEqual(147.18+0.02/3.0, line.Height, "line.Height");
				Assert.AreEqual(1, line.Length, "line.Length");
				Assert.AreEqual(1, line.NewlineLength, "line.NewlineLength");
				Assert.AreEqual(117.97, line.Baseline, 0.000000001, "line.Baseline");
				Assert.AreEqual(0, line.Width, "line.Width");
				Assert.IsFalse(line.HasOverflowed, "line.HasOverflowed");
				Assert.AreEqual(0, line.WidthIncludingTrailingWhitespace, "line.WidthIncludingTrailingWhitespace");
				AssertTextRunSpans(
					new int[] { 1 },
					new TextRun[] { new TextEndOfLine(1) },
					line);
				Assert.AreEqual(new string[] {
					"DefaultTextRunProperties",
					"DefaultTextRunProperties.Typeface",
					"DefaultTextRunProperties.FontRenderingEmSize",
					"Indent",
					"LineHeight",
					"FlowDirection",
					"AlwaysCollapsible",
					"TextAlignment",
					"FirstLineInParagraph",
					"TextMarkerProperties",
					"TextWrapping",
					"GetTextRun(0)",
					}, log);
				Assert.IsNull(line.GetTextLineBreak(), "GetTextLineBreak");
				Assert.AreEqual(0, line.Start, "line.Start");
			}
		}

		[Test]
		public void EmptyLineCollapsibleTest ()
		{
			using (var formatter = TextFormatter.Create ())
			{
				List<string> log = new List<string> ();
				var textSource = new LoggingTextSource(log);
				textSource.AddContents(new TextEndOfLine(1));
				var textParagraphProperties = new LoggingTextParagraphProperties(log);
				textParagraphProperties.alwaysCollapsible = true;
				Assert.AreEqual(2355/2048.0, textParagraphProperties.DefaultTextRunProperties.Typeface.FontFamily.LineSpacing);
				log.Clear();
				var line = formatter.FormatLine (textSource, 0, 256.0, textParagraphProperties, null);
				Assert.AreEqual(147.18+0.02/3.0, line.Height, "line.Height");
				Assert.AreEqual(1, line.Length, "line.Length");
				Assert.AreEqual(1, line.NewlineLength, "line.NewlineLength");
				Assert.AreEqual(117.97, line.Baseline, 0.000000001, "line.Baseline");
				Assert.AreEqual(0, line.Width, "line.Width");
				Assert.IsFalse(line.HasOverflowed, "line.HasOverflowed");
				Assert.AreEqual(0, line.WidthIncludingTrailingWhitespace, "line.WidthIncludingTrailingWhitespace");
				AssertTextRunSpans(
					new int[] { 1 },
					new TextRun[] { new TextEndOfLine(1) },
					line);
				Assert.IsNull(line.GetTextLineBreak(), "GetTextLineBreak");
				Assert.AreEqual(0, line.Start, "line.Start");
			}
		}

		[Test]
		public void SingleWordCollapsibleTest ()
		{
			using (var formatter = TextFormatter.Create ())
			{
				List<string> log = new List<string> ();
				var textSource = new LoggingTextSource(log);
				textSource.AddContents("test");
				textSource.AddContents(new TextEndOfLine(1));
				var textParagraphProperties = new LoggingTextParagraphProperties(log);
				textParagraphProperties.alwaysCollapsible = true;
				log.Clear();
				var line = formatter.FormatLine (textSource, 0, 256.0, textParagraphProperties, null);
				Assert.AreEqual(147.18+0.02/3.0, line.Height, "line.Height");
				Assert.AreEqual(5, line.Length, "line.Length");
				Assert.AreEqual(1, line.NewlineLength, "line.NewlineLength");
				Assert.AreEqual(117.97, line.Baseline, 0.000000001, "line.Baseline");
				Assert.AreEqual(206.31+0.01/3.0, line.Width, "line.Width");
				Assert.IsFalse(line.HasOverflowed, "line.HasOverflowed");
				Assert.AreEqual(206.31+0.01/3.0, line.WidthIncludingTrailingWhitespace, "line.WidthIncludingTrailingWhitespace");
				AssertTextRunSpans(
					new int[] { 4, 1 },
					new TextRun[] { textSource.contents[0], new TextEndOfLine(1) },
					line);
				Assert.IsNull(line.GetTextLineBreak(), "GetTextLineBreak");
				Assert.AreEqual(0, line.Start, "line.Start");
			}
		}

		[Test]
		public void OverflowTest ()
		{
			using (var formatter = TextFormatter.Create ())
			{
				List<string> log = new List<string> ();
				var textSource = new LoggingTextSource(log);
				textSource.AddContents("test test");
				textSource.AddContents(new TextEndOfLine(1));
				var textParagraphProperties = new LoggingTextParagraphProperties(log);
				textParagraphProperties.alwaysCollapsible = true;
				textParagraphProperties.textWrapping = TextWrapping.NoWrap;
				log.Clear();
				var line = formatter.FormatLine (textSource, 0, 256.0, textParagraphProperties, null);
				Assert.AreEqual(147.18+0.02/3.0, line.Height, "line.Height");
				Assert.AreEqual(10, line.Length, "line.Length");
				Assert.AreEqual(1, line.NewlineLength, "line.NewlineLength");
				Assert.AreEqual(117.97, line.Baseline, 0.000000001, "line.Baseline");
				Assert.AreEqual(448.19, line.Width, 0.000000001, "line.Width");
				Assert.IsTrue(line.HasOverflowed, "line.HasOverflowed");
				Assert.AreEqual(448.19, line.WidthIncludingTrailingWhitespace, 0.000000001, "line.WidthIncludingTrailingWhitespace");
				AssertTextRunSpans(
					new int[] { 9, 1 },
					new TextRun[] { textSource.contents[0], new TextEndOfLine(1) },
					line);
				Assert.IsNull(line.GetTextLineBreak(), "GetTextLineBreak");
				Assert.AreEqual(0, line.Start, "line.Start");
			}
		}

		[Test]
		public void WrapTest ()
		{
			using (var formatter = TextFormatter.Create ())
			{
				List<string> log = new List<string> ();
				var textSource = new LoggingTextSource(log);
				textSource.AddContents("test test2");
				textSource.AddContents(new TextEndOfLine(1));
				var textParagraphProperties = new LoggingTextParagraphProperties(log);
				textParagraphProperties.alwaysCollapsible = true;
				log.Clear();
				var line = formatter.FormatLine (textSource, 0, 256.0, textParagraphProperties, null);
				Assert.AreEqual(147.18+0.02/3.0, line.Height, "line.Height");
				Assert.AreEqual(5, line.Length, "line.Length");
				Assert.AreEqual(0, line.NewlineLength, "line.NewlineLength");
				Assert.AreEqual(117.97, line.Baseline, 0.000000001, "line.Baseline");
				Assert.AreEqual(206.31+0.01/3.0, line.Width, 0.000000001, "line.Width");
				Assert.IsFalse(line.HasOverflowed, "line.HasOverflowed");
				Assert.AreEqual(241.87+0.02/3.0, line.WidthIncludingTrailingWhitespace, 0.000000001, "line.WidthIncludingTrailingWhitespace");
				AssertTextRunSpans(
					new int[] { 5 },
					new TextRun[] { textSource.contents[0] },
					line);
				Assert.IsNull(line.GetTextLineBreak(), "GetTextLineBreak");
				Assert.AreEqual(0, line.Start, "line.Start");

				line = formatter.FormatLine (textSource, 5, 300.0, textParagraphProperties, null);
				Assert.AreEqual(147.18+0.02/3.0, line.Height, "line.Height");
				Assert.AreEqual(6, line.Length, "line.Length");
				Assert.AreEqual(1, line.NewlineLength, "line.NewlineLength");
				Assert.AreEqual(117.97, line.Baseline, 0.000000001, "line.Baseline");
				Assert.AreEqual(277.5, line.Width, 0.000000001, "line.Width");
				Assert.IsFalse(line.HasOverflowed, "line.HasOverflowed");
				Assert.AreEqual(277.5, line.WidthIncludingTrailingWhitespace, 0.000000001, "line.WidthIncludingTrailingWhitespace");
				AssertTextRunSpans(
					new int[] { 5, 1 },
					new TextRun[] { textSource.contents[5], new TextEndOfLine(1) },
					line);
				Assert.IsNull(line.GetTextLineBreak(), "GetTextLineBreak");
				Assert.AreEqual(0, line.Start, "line.Start");
			}
		}
	}
}
