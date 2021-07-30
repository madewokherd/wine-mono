
using System;
using System.Runtime.InteropServices;

public static class MixedModeDllImport
{
	[DllImport("mixedmodelibrary.dll", CallingConvention=CallingConvention.Cdecl, EntryPoint="test_mixed_export")]
	public static extern int dllimport_default(int input);

	[DefaultDllImportSearchPaths(0)]
	[DllImport("mixedmodelibrary.dll", CallingConvention=CallingConvention.Cdecl, EntryPoint="test_mixed_export")]
	public static extern int dllimport_0(int input);

	[DefaultDllImportSearchPaths(DllImportSearchPath.AssemblyDirectory)]
	[DllImport("mixedmodelibrary.dll", CallingConvention=CallingConvention.Cdecl, EntryPoint="test_mixed_export")]
	public static extern int dllimport_assemblydirectory(int input);

	[DefaultDllImportSearchPaths(DllImportSearchPath.AssemblyDirectory|DllImportSearchPath.UseDllDirectoryForDependencies)]
	[DllImport("mixedmodelibrary.dll", CallingConvention=CallingConvention.Cdecl, EntryPoint="test_mixed_export")]
	public static extern int dllimport_usedlldirectory(int input);
}
