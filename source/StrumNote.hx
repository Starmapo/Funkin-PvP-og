package;

import flixel.util.FlxDestroyUtil;
import flixel.math.FlxPoint;

using StringTools;

class StrumNote extends FNFSprite
{
	private var colorSwap:ColorSwap;
	public var resetAnim:Float = 0;
	public var noteData:Int = 0;
	public var direction:Float = 90;
	public var downScroll:Bool = false;
	public var sustainReduce:Bool = true;

	public var postAdded:Bool = false;

	public var keyAmount:Int = 4;
	public var directions:Array<String> = ['LEFT', 'DOWN', 'UP', 'RIGHT'];
	public var colors:Array<String> = ['left', 'down', 'up', 'right'];
	public var spacing:Float = 0;
	public var xOffset:Float = 0;
	public var noteSize:Float = 0.7;
	public var skinModifier:String = '';

	public var defaultX:Float = 0;
	public var defaultY:Float = 0;

	public var desiredZ:Float = 0;
	public var defaultScale:FlxPoint;
	
	public var texture(default, set):String = null;
	private function set_texture(value:String):String {
		texture = value;
		reloadNote();
		return value;
	}

	public function new(x:Float, y:Float, leData:Int, ?keyAmount:Int = 4) {
		//colorSwap = new ColorSwap();
		//shader = colorSwap.shader;
		noteData = leData;
		this.noteData = leData % keyAmount;
		this.keyAmount = keyAmount;
		super(x, y);

		defaultScale = FlxPoint.get(scale.x, scale.y);

		spacing = Std.parseFloat(CoolUtil.coolTextFile(Paths.txt('note_spacings'))[keyAmount-1]);
		directions = CoolUtil.coolArrayTextFile(Paths.txt('note_directions'))[keyAmount-1];
		colors = CoolUtil.coolArrayTextFile(Paths.txt('note_colors'))[keyAmount-1];
		xOffset = Std.parseFloat(CoolUtil.coolTextFile(Paths.txt('note_offsets'))[keyAmount-1]);
		noteSize = Std.parseFloat(CoolUtil.coolTextFile(Paths.txt('note_sizes'))[keyAmount-1]);

		var skin:String = 'NOTE_assets';
		if(PlayState.SONG != null && PlayState.SONG.arrowSkin != null && PlayState.SONG.arrowSkin.length > 0) skin = PlayState.SONG.arrowSkin;
		texture = skin; //Load texture and anims

		scrollFactor.set();
	}

	public function reloadNote()
	{
		var lastAnim:String = null;
		if (animation.name != null) lastAnim = animation.name;

		if (skinModifier.length < 1) {
			skinModifier = 'base';
			if (PlayState.SONG != null && CoolUtil.inPlayState())
				skinModifier = PlayState.SONG.skinModifier;
		}
		var image = SkinData.getNoteFile(texture, skinModifier);
		if (!Paths.existsPath('images/$image.xml', TEXT)) { //assume it is pixel notes
			loadGraphic(Paths.image(image));
			width = width / 4;
			height = height / 5;
			loadGraphic(Paths.image(image), true, Math.floor(width), Math.floor(height));

			setGraphicSize(Std.int((width * (noteSize / Note.DEFAULT_NOTE_SIZE)) * PlayState.daPixelZoom));
			
			switch (noteData)
			{
				case 0:
					animation.add('static', [0]);
					animation.add('pressed', [4, 8], 12, false);
					animation.add('confirm', [12, 16], 24, false);
				case 1:
					animation.add('static', [1]);
					animation.add('pressed', [5, 9], 12, false);
					animation.add('confirm', [13, 17], 24, false);
				case 2:
					animation.add('static', [2]);
					animation.add('pressed', [6, 10], 12, false);
					animation.add('confirm', [14, 18], 12, false);
				case 3:
					animation.add('static', [3]);
					animation.add('pressed', [7, 11], 12, false);
					animation.add('confirm', [15, 19], 24, false);
			}
		} else {
			frames = Paths.getSparrowAtlas(image);
			animation.addByPrefix('static', 'arrow${directions[noteData].toUpperCase()}0');
			animation.addByPrefix('pressed', '${colors[noteData]} press', 24, false);
			animation.addByPrefix('confirm', '${colors[noteData]} confirm', 24, false);
			if (skinModifier.endsWith('pixel')) {
				setGraphicSize(Std.int((width * (noteSize / Note.DEFAULT_NOTE_SIZE)) * PlayState.daPixelZoom));
			} else {
				setGraphicSize(Std.int(width * noteSize));
			}
		}
		updateHitbox();
		antialiasing = ClientPrefs.globalAntialiasing && !skinModifier.endsWith('pixel');

		if (lastAnim != null)
		{
			playAnim(lastAnim, true);
		}
		defaultScale.set(scale.x, scale.y);
	}

	public function postAddedToGroup() {
		playAnim('static');
		x += (((160 * noteSize) + spacing) * noteData) + xOffset;
		ID = noteData;
		postAdded = true;
	}

	override function update(elapsed:Float) {
		if (resetAnim > 0) {
			resetAnim -= elapsed;
			if (resetAnim <= 0) {
				playAnim('static');
			}
		}
		if (animation.curAnim != null && !skinModifier.endsWith('pixel'))
			centerOrigin();

		super.update(elapsed);
	}

	public function playAnim(anim:String, ?force:Bool = false) {
		animation.play(anim, force);
		centerOffsets();
		centerOrigin();
		if (animation.curAnim == null || animation.name == 'static') {
			if (colorSwap != null)
			{
				colorSwap.hue = 0;
				colorSwap.saturation = 0;
				colorSwap.brightness = 0;
			}
		} else {
			if (colorSwap != null && noteData > -1 && noteData < ClientPrefs.arrowHSV[keyAmount - 1].length)
			{
				colorSwap.hue = ClientPrefs.arrowHSV[keyAmount - 1][noteData][0] / 360;
				colorSwap.saturation = ClientPrefs.arrowHSV[keyAmount - 1][noteData][1] / 100;
				colorSwap.brightness = ClientPrefs.arrowHSV[keyAmount - 1][noteData][2] / 100;
			}

			if(animation.name == 'confirm' && !skinModifier.endsWith('pixel')) {
				centerOrigin();
			}
		}
		resetAnim = 0;
	}

	override function destroy() {
		super.destroy();
		defaultScale = FlxDestroyUtil.put(defaultScale);
	}
}