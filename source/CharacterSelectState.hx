import flixel.ui.FlxBar;
import CharacterSelect;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.effects.FlxFlicker;
import flixel.util.FlxColor;
import haxe.Json;

using StringTools;

class CharacterSelectState extends MusicBeatState
{
	public static var exiting:Bool = false;

	var charSelect1:CharacterSelect;
	var charSelect2:CharacterSelect;
	var fullCharList:Array<String> = [];
	var returnBar:FlxBar;
	var returnTime:Float = 0;

	override public function create()
	{
		super.create();
		persistentUpdate = true;
		exiting = false;

		var bg = new FlxSprite().loadGraphic(Paths.image('menuBGBlue'));
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		bg.scrollFactor.set();
		bg.screenCenter();
		add(bg);

		var chars = getCharacters();
		charSelect1 = new CharacterSelect(0, 0, chars, 0);
		add(charSelect1);
		charSelect2 = new CharacterSelect(FlxG.width / 2, 0, chars, 1);
		add(charSelect2);

		var line = new FlxSprite().makeGraphic(3, FlxG.height, FlxColor.WHITE);
		line.screenCenter(X);
		add(line);

		returnBar = new FlxBar(0, 0, LEFT_TO_RIGHT, 200, 40, this, 'returnTime', 0.2, 1.2);
		returnBar.createFilledBar(0xFF000000, 0xFFFFFFFF, true, FlxColor.BLACK);
		returnBar.screenCenter(X);
		returnBar.scrollFactor.set();
		add(returnBar);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		var go:Bool = !exiting && charSelect1.ready && charSelect2.ready;
		if (Main.debug && !MultiControls.playerActive(1))
			go = !exiting && (charSelect1.ready || charSelect2.ready);

		if (go)
		{
			charSelect1.fadeStuff();
			charSelect2.fadeStuff();
			FlxFlicker.flicker(charSelect1.readyText, 1, 0.06, false, false);
			FlxFlicker.flicker(charSelect2.readyText, 1, 0.06, false, false, function(flick:FlxFlicker)
			{
				var charSelects = [charSelect1, charSelect2];
				for (charSelect in charSelects)
				{
					if (charSelect.selectedChar == '!random')
						charSelect.selectedChar = fullCharList[FlxG.random.int(0, fullCharList.length - 1)];
					trace(charSelect.selectedChar);
				}

				PlayState.dadMatch = (charSelect1.selectedChar == PlayState.SONG.player2);
				PlayState.boyfriendMatch = (charSelect2.selectedChar == PlayState.SONG.player1);

				PlayState.SONG.player2 = charSelect1.selectedChar;
				PlayState.SONG.player1 = charSelect2.selectedChar;
				PlayState.playerWins = [0, 0];
				MusicBeatState.switchState(new PlayState());
				FlxG.sound.music.stop();
			});
			exiting = true;
		} else if (!exiting) {
			if (MultiControls.anyCheck(BACK))
			{
				returnTime += elapsed;
				if (returnTime >= 0.2)
				{
					returnBar.visible = true;
					if (returnTime >= 1.2)
					{
						exiting = true;
						MusicBeatState.switchState(new SongSelectState());
						CoolUtil.playCancelSound();
					}
				}
				else
				{
					returnBar.visible = false;
				}
			}
			else
			{
				returnTime = 0;
				returnBar.visible = false;
			}
		}
	}

	function getCharacters()
	{
		var rawJson = Paths.getContent(Paths.json('pvpCharacters')).trim();
		var stuff:Dynamic = Json.parse(rawJson);
		var daList:Array<Array<Dynamic>> = Reflect.getProperty(stuff, "characters");

		var charDataList:Array<CharacterData> = [];
		charDataList.push({
			name: '!random',
			displayName: 'Random',
			alternateForms: []
		});
		for (char in daList)
		{
			var charData:CharacterData = {
				name: char[0],
				displayName: char[1],
				alternateForms: []
			};
			fullCharList.push(charData.name);
			Paths.image('pvp/char/${charData.name}');
			if (char[2] != null)
			{
				for (i in 0...char[2].length)
				{
					var altData:AlternateForm = {
						name: char[2][i][0],
						displayName: char[2][i][1]
					};
					charData.alternateForms.push(altData);
					fullCharList.push(altData.name);
					Paths.image('pvp/char/${altData.name}');
				}
			}
			charDataList.push(charData);
		}

		trace('character count: ' + fullCharList.length);
		return charDataList;
	}

	static function sortChars(a:CharacterData, b:CharacterData):Int
	{
		var val1 = a.displayName.toUpperCase();
		var val2 = b.displayName.toUpperCase();
		if (val1 < val2)
		{
			return -1;
		}
		else if (val1 > val2)
		{
			return 1;
		}
		else
		{
			return 0;
		}
	}
}
