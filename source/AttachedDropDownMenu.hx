import flixel.addons.ui.StrNameLabel;
import flixel.addons.ui.FlxUIButton;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.FlxSprite;
import flixel.addons.ui.FlxUIDropDownMenu;

class AttachedDropDownMenu extends FlxUIDropDownMenu
{
	public var sprTracker:FlxSprite;
	public var xAdd:Float = 0;
	public var yAdd:Float = 0;

	public var copyVisible:Bool = true;

	public function new(DataList:Array<StrNameLabel>, ?Callback:String->Void, ?Header:FlxUIDropDownHeader,
			?DropPanel:FlxUI9SliceSprite, ?ButtonList:Array<FlxUIButton>)
	{
		super(0, 0, DataList, Callback, Header, DropPanel, ButtonList);
	}

	override function update(elapsed:Float)
	{
		if (sprTracker != null)
		{
			setPosition(sprTracker.x + xAdd, sprTracker.y + yAdd);
			setScrollFactor(sprTracker.scrollFactor.x, sprTracker.scrollFactor.y);

			if (copyVisible)
				visible = sprTracker.visible;
		}

		super.update(elapsed);
	}

	override public function destroy()
	{
		sprTracker = null;
		super.destroy();
	}
}