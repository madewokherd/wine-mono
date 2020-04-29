using System;

// Test that byte arrays always have a 0 byte after the end.
static class TestArrayPadding
{
    public unsafe static int Main()
    {
		for (int i=0; i<4096; i++)
		{
			for (int j=1; j < 4096; j++)
			{
				byte[] arr = new byte[j];
				for (int k=0; k<j; k++)
					arr[k] = 136;
				fixed (byte* b = arr)
				{
					if (b[j] != 0)
					{
						Console.WriteLine("Bad array end {0} {1} {2}", i, j, b[j]);
						return 1;
					}
				}
			}
		}
		return 0;
    }
}
