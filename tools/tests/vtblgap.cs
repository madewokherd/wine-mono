using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.Runtime.InteropServices;
using System.Runtime.InteropServices.ComTypes;
using System.Runtime.CompilerServices;

namespace comimport
{
    internal static class Program
    {
        [DllImport("vtblgap-lib.dll")]
		[return: MarshalAsAttribute(UnmanagedType.IUnknown)] 
        extern static object get_object();

        [ComImport]
        [Guid("deadbeef-0000-0000-c000-000000000001")]
        [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
        public interface ITest1
        {
            //[SpecialName]
            void _VtblGap1_1();
            int itest1_method1(out int val);
        }

        [ComImport]
        [Guid("deadbeef-0000-0000-c000-000000000002")]
        [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
        public interface ITest2 : ITest1
        {
            //[SpecialName]
            void _VtblGap2_3();

            int method3(out int ret);
        }

        static object test_obj;

        static void Main()
        {
			int ret;
			test_obj = get_object();
			((ITest2)test_obj).itest1_method1(out ret);
			if (ret != 11)
			{
				throw (new Exception(String.Format("Wrong method {0}", ret)));
			}
			((ITest2)test_obj).method3(out ret);
			if (ret != 13)
			{
				throw (new Exception(String.Format("Wrong method {0}", ret)));
			}
        }
    }
}
