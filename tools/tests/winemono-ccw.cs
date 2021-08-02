
using System;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;

[ComImport]
[Guid("209706eb-0a9c-4651-bcb8-582f19fbfbd8")]
[InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
public interface ICCWTest
{
	[PreserveSig]
	[MethodImplAttribute(MethodImplOptions.InternalCall, MethodCodeType = MethodCodeType.Runtime)]
	int in_safearrayvariant_array([MarshalAs(UnmanagedType.SafeArray)] object[] sa);

	[PreserveSig]
	[MethodImplAttribute(MethodImplOptions.InternalCall, MethodCodeType = MethodCodeType.Runtime)]
	int in_safearrayi4_array(int[] sa);
}

public class WineMonoCcwTest : ICCWTest
{
	public int in_safearrayvariant_array(object[] sa)
	{
		if (sa.GetType() != typeof(object[]))
			return 1;
		if (sa.Rank != 1)
			return 2;
		if (sa.Length != 3)
			return 3;
		if (sa[0] as int? != 2)
			return 4;
		return 0;
	}

	public int in_safearrayi4_array(int[] sa)
	{
		if (sa.Length != 3)
			return 1;
		if (sa[0] != 2)
			return 2;
		return 0;
	}

	[DllImport("winemonotest", CallingConvention=CallingConvention.Cdecl)]
	extern static int do_ccw_tests([MarshalAs(UnmanagedType.IUnknown)] object unk);

	public static int Main()
	{
		return do_ccw_tests(new WineMonoCcwTest ());
	}
}
