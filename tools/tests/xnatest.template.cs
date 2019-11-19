// We can't build this properly due to type forwards, so xnatest.il is actually used
using Microsoft.Xna.Framework;

public class TestGame : Game
{
	public TestGame()
	{
		var g = new GraphicsDeviceManager(this);
	}

	protected override void Update(GameTime time)
	{
		Exit();
		base.Update(time);
	}
}

public class XnaTest
{
	public static void Main()
	{
		using (var game = new TestGame())
			game.Run();
	}
}
