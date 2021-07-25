using System;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;
using System.Security;

public class RcwVisibleTest
{

	[ComVisible (false)]
	[Guid ("00000000-0000-0000-0000-000000000001")]
	[InterfaceType (ComInterfaceType.InterfaceIsIUnknown)]
	internal interface ITest
	{
		// properties need to go first since mcs puts them there
		ITest Test
		{
			[return: MarshalAs (UnmanagedType.Interface)]
			[MethodImpl (MethodImplOptions.InternalCall, MethodCodeType = MethodCodeType.Runtime), DispId (5242884)]
			get;
		}

		void SByteIn (sbyte val);
		[MethodImplAttribute (MethodImplOptions.InternalCall, MethodCodeType = MethodCodeType.Runtime)]
		void ByteIn (byte val);
	}

	[DllImport ("libtest")]
	internal static extern int mono_test_marshal_com_object_create (out ITest pUnk);

	public static int Main ()
	{
		mono_test_marshal_com_object_create(out var test_iface);

		test_iface.SByteIn (-100);

		bool bytein_exc = false;
		try
		{
			test_iface.ByteIn (100);
		}
		catch (SecurityException)
		{
			bytein_exc = true;
		}

		if (!bytein_exc)
			return 1;

		return 0;
	}
}
