import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.addons.ui.FlxUIInputText;

class AttachedInputText extends FlxUIInputText
{
	public var sprTracker:FlxSprite;
	public var xAdd:Float = 0;
	public var yAdd:Float = 0;

	public var copyVisible:Bool = true;

	public function new(Width:Int = 150, ?Text:String, size:Int = 8, TextColor:Int = FlxColor.BLACK,
			BackgroundColor:Int = FlxColor.WHITE, EmbeddedFont:Bool = true)
	{
		super(0, 0, Width, Text, size, TextColor, BackgroundColor, EmbeddedFont);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
		{
			setPosition(sprTracker.x + xAdd, sprTracker.y + yAdd);
			scrollFactor.set(sprTracker.scrollFactor.x, sprTracker.scrollFactor.y);

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