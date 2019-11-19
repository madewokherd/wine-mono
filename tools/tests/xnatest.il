.assembly extern Microsoft.Xna.Framework.Game
{
  .ver 4:0:0:0
  .publickeytoken = (84 2C F8 BE 1D E5 05 53 ) // .,.....S
}
.assembly extern Microsoft.Xna.Framework.Graphics
{
  .ver 4:0:0:0
  .publickeytoken = (84 2C F8 BE 1D E5 05 53 ) // .,.....S
}
.assembly extern mscorlib
{
  .ver 4:0:0:0
  .publickeytoken = (B7 7A 5C 56 19 34 E0 89 ) // .z\V.4..
}
.assembly extern System
{
  .ver 4:0:0:0
  .publickeytoken = (B7 7A 5C 56 19 34 E0 89 ) // .z\V.4..
}
.assembly 'xnatest'
{
  .custom instance void class [mscorlib]System.Runtime.CompilerServices.CompilationRelaxationsAttribute::'.ctor'(int32) =  (01 00 08 00 00 00 00 00 ) // ........

  .custom instance void class [mscorlib]System.Runtime.CompilerServices.RuntimeCompatibilityAttribute::'.ctor'() =  (
		01 00 01 00 54 02 16 57 72 61 70 4E 6F 6E 45 78   // ....T..WrapNonEx
		63 65 70 74 69 6F 6E 54 68 72 6F 77 73 01       ) // ceptionThrows.

  .hash algorithm 0x00008004
  .ver  0:0:0:0
}
.module xnatest.exe


  .class public auto ansi beforefieldinit TestGame
  	extends [Microsoft.Xna.Framework.Game]Microsoft.Xna.Framework.Game
  {

    .method public hidebysig specialname rtspecialname 
           instance void '.ctor' ()  cil managed 
    {
		.maxstack 8
		ldarg.0
		call instance void class [Microsoft.Xna.Framework.Game]Microsoft.Xna.Framework.Game::'.ctor'()
		ldarg.0
		newobj instance void [Microsoft.Xna.Framework.Game]Microsoft.Xna.Framework.GraphicsDeviceManager::'.ctor'(class [Microsoft.Xna.Framework.Game]Microsoft.Xna.Framework.Game)
		pop
		ret
    }

    .method family virtual hidebysig 
           instance void Update(class [Microsoft.Xna.Framework.Game]Microsoft.Xna.Framework.GameTime time) cil managed 
    {
	.maxstack 8
	IL_0000:  nop 
	IL_0001:  ldarg.0 
	IL_0002:  call instance void [Microsoft.Xna.Framework.Game]Microsoft.Xna.Framework.Game::Exit()
	IL_0007:  nop 
	IL_0008:  ldarg.0 
	IL_0009:  ldarg.1 
	IL_000a:  call instance void [Microsoft.Xna.Framework.Game]Microsoft.Xna.Framework.Game::Update(class [Microsoft.Xna.Framework.Game]Microsoft.Xna.Framework.GameTime)
	IL_000f:  nop 
	IL_0010:  ret 
    }

  }

  .class public auto ansi beforefieldinit XnaTest
  	extends [mscorlib]System.Object
  {

    .method public static hidebysig 
           void Main ()  cil managed 
    {
	.entrypoint
	.maxstack 8
	.locals init (class TestGame game)
	newobj instance void class TestGame::'.ctor'()
	stloc.0
	ldloc.0
	call instance void [Microsoft.Xna.Framework.Game]Microsoft.Xna.Framework.Game::Run()
	ldloc.0
	callvirt instance void [mscorlib]System.IDisposable::Dispose()
	ret
    }

    .method public hidebysig specialname rtspecialname 
           instance void '.ctor' ()  cil managed 
    {
	.maxstack 8
	IL_0000:  ldarg.0 
	IL_0001:  call instance void object::'.ctor'()
	IL_0006:  ret 
    }

  }
