import flixel.text.FlxText;
import flixel.FlxSprite;

class AttachedFlxText extends FlxText
{
	public var sprTracker:FlxSprite;
	public var xAdd:Float = 0;
	public var yAdd:Float = 0;
	public var angleAdd:Float = 0;
	public var alphaMult:Float = 1;

	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;
	public var copyVisible:Bool = false;

	public function new(FieldWidth:Float = 0, ?Text:String, Size:Int = 8, EmbeddedFont:Bool = true)
	{
		super(0, 0, FieldWidth, Text, Size, EmbeddedFont);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
		{
			setPosition(sprTracker.x + xAdd, sprTracker.y + yAdd);
			scrollFactor.set(sprTracker.scrollFactor.x, sprTracker.scrollFactor.y);

			if (copyAngle)
				angle = sprTracker.angle + angleAdd;
			if (copyAlpha)
				alpha = sprTracker.alpha * alphaMult;
			if (copyVisible)
				visible = sprTracker.visible;
		}
	}

	override public function destroy()
	{
		sprTracker = null;
		super.destroy();
	}
}