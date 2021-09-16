using Microsoft.Win32;
using System;

class TimeZoneTest
{
	static void dumptzi(TimeZoneInfo tzi)
	{
		Console.WriteLine(tzi.Id);
		Console.WriteLine("  Display name: {0}", tzi.DisplayName);
		Console.WriteLine("  Standard name: {0}", tzi.StandardName);
		Console.WriteLine("  Daylight name: {0}", tzi.DaylightName);
		Console.WriteLine("  Base offset: {0}", tzi.BaseUtcOffset);

		foreach (TimeZoneInfo.AdjustmentRule rule in tzi.GetAdjustmentRules())
		{
			Console.WriteLine("  Adjustment Rule:");
			Console.WriteLine("	Start date: {0}", rule.DateStart);
			Console.WriteLine("	End date: {0}", rule.DateEnd);
			Console.WriteLine("	Daylight delta: {0}", rule.DaylightDelta);
			Console.WriteLine("	Daylight start day: {0}", rule.DaylightTransitionStart.Day);
			Console.WriteLine("	Daylight start day of week: {0}", rule.DaylightTransitionStart.DayOfWeek);
			Console.WriteLine("	Daylight start fixed: {0}", rule.DaylightTransitionStart.IsFixedDateRule);
			Console.WriteLine("	Daylight start month: {0}", rule.DaylightTransitionStart.Month);
			Console.WriteLine("	Daylight start timeofday: {0}", rule.DaylightTransitionStart.TimeOfDay);
			Console.WriteLine("	Daylight start week: {0}", rule.DaylightTransitionStart.Week);
			Console.WriteLine("	Daylight end day: {0}", rule.DaylightTransitionEnd.Day);
			Console.WriteLine("	Daylight end day of week: {0}", rule.DaylightTransitionEnd.DayOfWeek);
			Console.WriteLine("	Daylight end fixed: {0}", rule.DaylightTransitionEnd.IsFixedDateRule);
			Console.WriteLine("	Daylight end month: {0}", rule.DaylightTransitionEnd.Month);
			Console.WriteLine("	Daylight end timeofday: {0}", rule.DaylightTransitionEnd.TimeOfDay);
			Console.WriteLine("	Daylight end week: {0}", rule.DaylightTransitionEnd.Week);
		}
	}

	static void Main(string [] argv)
	{
		using (var timezones = Registry.LocalMachine.OpenSubKey("Software\\Microsoft\\Windows NT\\CurrentVersion\\Time Zones"))
		{
			foreach (string id in timezones.GetSubKeyNames())
			{
				Console.WriteLine(id);
				dumptzi(TimeZoneInfo.FindSystemTimeZoneById(id));
			}
		}
	}
}

