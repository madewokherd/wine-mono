.assembly extern mscorlib
{
  .ver 4:0:0:0
  .publickeytoken = (B7 7A 5C 56 19 34 E0 89 ) // .z\V.4..
}
.assembly marshalcopy
{
  .custom instance void class [mscorlib]System.Runtime.CompilerServices.CompilationRelaxationsAttribute::'.ctor'(int32) =  (01 00 08 00 00 00 00 00 )

  .custom instance void class [mscorlib]System.Runtime.CompilerServices.RuntimeCompatibilityAttribute::'.ctor'() =  (
		01 00 01 00 54 02 16 57 72 61 70 4E 6F 6E 45 78   // ....T..WrapNonEx
		63 65 70 74 69 6F 6E 54 68 72 6F 77 73 01	   ) // ceptionThrows.

  .permissionset reqmin = {[mscorlib]System.Security.Permissions.SecurityPermissionAttribute = {property bool 'SkipVerification' = bool(true)}}
  .hash algorithm 0x00008004
  .ver  0:0:0:0
}
.module marshalcopy.exe

.custom instance void class [mscorlib]System.Security.UnverifiableCodeAttribute::'.ctor'() =  (01 00 00 00 )

.module extern 'winemonotest'

  .class public sequential ansi sealed beforefieldinit TestStruct
  	extends [mscorlib]System.ValueType
  {
	.field  public  int32 val
	.field  public static  int32 dtor_val
	.field  public static  int32 copy_val

	.method public specialname static void '<MarshalCopy>' (valuetype TestStruct* a, valuetype TestStruct* b) cil managed 
	{
	  // Console.WriteLine("<MarshalCopy>")
	  ldstr "<MarshalCopy>"
	  call void class [mscorlib]System.Console::WriteLine(string)

	  // Console.WriteLine(a->val) - pointer receiving new struct, seems to be undefined
	  ldarg.0
	  ldfld int32 TestStruct::val
	  call void class [mscorlib]System.Console::WriteLine(int32)

	  // Console.WriteLine(b->val) - pointer to the original struct
	  ldarg.1 
	  ldfld int32 TestStruct::val
	  call void class [mscorlib]System.Console::WriteLine(int32)

	  // copy_val = b->val
	  ldarg.1 
	  ldfld int32 TestStruct::val
	  stsfld int32 TestStruct::copy_val

	  // a->val = 10
	  ldarg.0
	  ldc.i4 10
	  stfld int32 TestStruct::val

	  // b->val = 15
	  ldarg.1 
	  ldc.i4 15
	  stfld int32 TestStruct::val

	  ret 
	}

	.method public specialname static void '<MarshalDestroy>' (valuetype TestStruct* obj) cil managed 
	{
	  // dtor_val = obj->val
	  ldarg.0
	  ldfld int32 TestStruct::val
	  stsfld int32 TestStruct::dtor_val

	  // Console.WriteLine("<MarshalDestroy>")
	  ldstr "<MarshalDestroy>"
	  call void class [mscorlib]System.Console::WriteLine(string)

	  // Console.WriteLine(dtor_val)
	  ldsfld int32 TestStruct::dtor_val
	  call void class [mscorlib]System.Console::WriteLine(int32)

	  // obj->val = 20
	  ldarg.0
	  ldc.i4 20
	  stfld int32 TestStruct::val

	  ret 
	}

  }

  .class public auto ansi beforefieldinit MarshalCopyTest
  	extends [mscorlib]System.Object
  {
	.method private static hidebysig pinvokeimpl ("winemonotest" as "dereference_int" stdcall)
		   default valuetype TestStruct dereference_int (valuetype TestStruct modreq([mscorlib]System.Runtime.CompilerServices.IsCopyConstructed)* ss)  cil managed preservesig 
	{
	}

	.method public static hidebysig 
		   default int32 Main ()  cil managed 
	{
	.entrypoint
	.locals init (
		valuetype TestStruct	s,
		valuetype TestStruct	s1)

	  // s = new TestStruct()
	  ldloca.s 0
	  initobj TestStruct

	  // s.val = 5
	  ldloca.s 0
	  ldc.i4.5 
	  stfld int32 TestStruct::val

	  // s1 = dereference_int(&s)
	  ldloca.s 0
	  conv.u 
	  call valuetype TestStruct class MarshalCopyTest::dereference_int(valuetype TestStruct modreq([mscorlib]System.Runtime.CompilerServices.IsCopyConstructed)*)
	  stloc.1 

	  // if (s1.val != 10) ...
	  // Our copied value is passed into dereference_int (by value on x86, by reference on x64)
	  ldloc.1 
	  ldfld int32 TestStruct::val
	  ldc.i4 10
	  ceq 
	  brtrue.s ok1

		  // Console.WriteLine(s1.val)
		  ldloc.1 
		  ldfld int32 TestStruct::val
		  call void class [mscorlib]System.Console::WriteLine(int32)

		  // return 1
		  ldc.i4.1 
		  ret

	  ok1:

	  // if (s.val != 20) ...
	  // BUG in .NET Framework? <MarshalDestroy> was called on the struct we passed in.
	  ldloc.0 
	  ldfld int32 TestStruct::val
	  ldc.i4 20
	  ceq 
	  brtrue.s ok2

		// Console.WriteLine(s.val)
		ldloc.0 
		ldfld int32 TestStruct::val
		call void class [mscorlib]System.Console::WriteLine(int32)

		// return 2
		ldc.i4.2 
		ret

	  ok2:

	  // if (TestStruct.dtor_val != 15) ...
	  // The struct we passed in was changed to 15 by <MarshalCopy> before <MarshalDestroy> was called
	  ldsfld int32 TestStruct::dtor_val
	  ldc.i4 15
	  ceq 
	  brtrue.s ok3

		// Console.WriteLine(TestStruct.dtor_val)
		ldsfld int32 TestStruct::dtor_val
		call void class [mscorlib]System.Console::WriteLine(int32)

		// return 3
		ldc.i4.3 
		ret

	  ok3:

	  // if (TestStruct.copy_val != 5) ...
	  // Value originally passed into <MarshalCopy> was 5
	  ldsfld int32 TestStruct::copy_val
	  ldc.i4 5
	  ceq 
	  brtrue.s ok4

		// Console.WriteLine(TestStruct.copy_val)
		ldsfld int32 TestStruct::copy_val
		call void class [mscorlib]System.Console::WriteLine(int32)

		// return 4
		ldc.i4.4
		ret

	  ok4:

	  // return 0
	  ldc.i4.0 
	  ret 
	}

	.method public hidebysig specialname rtspecialname 
		   instance default void '.ctor' ()  cil managed 
	{
	  ldarg.0 
	  call instance void object::'.ctor'()
	  ret 
	}

  }

