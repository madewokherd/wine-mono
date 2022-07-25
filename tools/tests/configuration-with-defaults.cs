/*
 * Copyright 2022 Bernhard Kölbl
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this software
 * and associated documentation files (the “Software”), to deal in the Software without
 * restriction, including without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in all copies or
 * substantial portions of the Software.
 *
 * ===============================================================================================
 *
 * These tests check .NET Framework's behvaior, when user settings with a default settings file
 * are being saved.
 *
 */

using System;
using System.Configuration;
using System.IO;
using System.Xml;

namespace TestApp
{
	public class CustomClass
	{
		public string Field1;
		public string Field2;
		public string Field3;
		public string Field4;
		public string Field5;
	}

	class Program
	{
		public static int Main(string[] args)
		{
			int i = 0;
			//Expected values
			string[] settingNames = new string[] { "SettingBool2",  "SettingInt1", "SettingInt2", "SettingCustomClass1" };
			string[] settingValues = new string[] { "False", "4001", "4002", "abcdefghijklmno" };

			Console.WriteLine($"SettingBool1: {Settings.Default.SettingBool1}, " +
							  $"SettingBool2: {Settings.Default.SettingBool2}, " +
							  $"SettingInt1: {Settings.Default.SettingInt1}, " +
							  $"SettingInt2: {Settings.Default.SettingInt2}, " +
							  $"SettingString1: {Settings.Default.SettingString1}" +
							  $"SettingCustomClass1: {Settings.Default.SettingCustomClass1}");

			// Set modified values
			Settings.Default.SettingBool2 = false;
			Settings.Default.SettingInt1 = 4001;
			Settings.Default.SettingInt2 = 4002;
			Settings.Default.SettingCustomClass1 = new CustomClass() { Field1 = "abc", Field2 = "def", Field3 = "ghi", Field4 = "jkl", Field5 = "mno" };
			Console.WriteLine("Values set!");

			Settings.Default.Save();
			Console.WriteLine("Saved!");

			FileInfo info = new DirectoryInfo(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData) + "/TestApp/").GetDirectories()[0].GetDirectories()[0].GetFiles()[0];

			XmlDocument document = new XmlDocument();
			document.Load(info.FullName);
			XmlNode settingsNode = document.DocumentElement.SelectSingleNode("/configuration/userSettings/TestApp.Settings");

			// Check if correct values were saved
			foreach (XmlNode node in settingsNode.ChildNodes)
			{
				XmlNode valueNode = node.SelectSingleNode("value");
				XmlAttribute attr = node.Attributes["name"];

				if (attr.Value != settingNames[i])
				{
					Console.WriteLine($"Names not matching: {attr.Value} - {settingNames[i]}");
					return 1;
				}

				if (valueNode.InnerText != settingValues[i])
				{
					Console.WriteLine($"Values not matching: {valueNode.InnerText} - {settingValues[i]}");
					return 1;
				}

				i++;
			}

			if (i != 4)
			{
				Console.WriteLine("Wrong amount of values were found!");
				return 1;
			}

			Console.WriteLine($"SettingBool1: {Settings.Default.SettingBool1}, " +
							  $"SettingBool2: {Settings.Default.SettingBool2}, " +
							  $"SettingInt1: {Settings.Default.SettingInt1}, " +
							  $"SettingInt2: {Settings.Default.SettingInt2}, " +
							  $"SettingString1: {Settings.Default.SettingString1}" +
							  $"SettingCustomClass1: {Settings.Default.SettingCustomClass1}");

			Console.WriteLine("Tests successful!");
			return 0;
		}
	}

	class Settings : ApplicationSettingsBase
	{
		private static Settings defaultInstance = (Settings)SettingsBase.Synchronized(new Settings());

		public static Settings Default => defaultInstance;

		[UserScopedSetting]
		public bool SettingBool1
		{
			get
			{
				return (bool)this["SettingBool1"];
			}
			set
			{
				this["SettingBool1"] = value;
			}
		}

		[UserScopedSetting]
		public bool SettingBool2
		{
			get
			{
				return (bool)this["SettingBool2"];
			}
			set
			{
				this["SettingBool2"] = value;
			}
		}

		[UserScopedSetting]
		public int SettingInt1
		{
			get
			{
				return (int)this["SettingInt1"];
			}
			set
			{
				this["SettingInt1"] = value;
			}
		}

		/*
		 * This setting does not have a default value in the XML-File on purpose,
		 * to test mono's behavior on a setting with an in code default value.
		 */
		[UserScopedSetting]
		[DefaultSettingValueAttribute("0")]
		public int SettingInt2
		{
			get
			{
				return (int)this["SettingInt2"];
			}
			set
			{
				this["SettingInt2"] = value;
			}
		}

		[UserScopedSetting]
		public string SettingString1
		{
			get
			{
				return (string)this["SettingString1"];
			}
			set
			{
				this["SettingString1"] = value;
			}
		}

		[UserScopedSetting]
		public CustomClass SettingCustomClass1
		{
			get
			{
				return (CustomClass)this["SettingCustomClass1"];
			}
			set
			{
				this["SettingCustomClass1"] = value;
			}
		}
	}

}
