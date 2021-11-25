using System;
using System.Resources;

class SystemResources
{
	public static int Main(String [] args)
	{
		try
		{
			var rm = new ResourceManager("System", typeof(Uri).Assembly);
			String s = rm.GetString("Arg_EmptyOrNullArray");
			if (s == null)
			{
				return 2;
			}
		}
		catch (MissingManifestResourceException)
		{
			return 1;
		}
		return 0;
	}
}