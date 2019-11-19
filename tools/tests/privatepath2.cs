
static class TestPrivatePath2
{
    public static int Main()
    {
        if (TestCsLib.Class1.Get5() != 5 || TestCsLib.Class2.Get5() != 5)
			return 1;
		return 0;
    }
}
