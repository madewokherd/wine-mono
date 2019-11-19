
static class TestPrivatePath1
{
    public static int Main()
    {
        return (TestCsLib.Class1.Get5() == 5) ? 0 : 1;
    }
}
