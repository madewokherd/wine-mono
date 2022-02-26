using System;
using Microsoft.DirectX.Direct3D;

class AdapterTest
{
    static void Main(string [] argv)
    {
        foreach (AdapterInformation adapter in Manager.Adapters)
        {
            Console.WriteLine("adapter {0}", adapter.Adapter);
            Console.WriteLine(adapter.Information);
            foreach (DisplayMode mode in adapter.SupportedDisplayModes[Format.X8R8G8B8])
            {
                Console.WriteLine("  {0}x{1}", mode.Width, mode.Height);
            }
        }
    }
}

