package;

import Type.ValueType;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import haxe.io.Path;
import lime.app.Application;
import lime.graphics.Image;
import sys.FileSystem;

using StringTools;

class CoolUtil
{
	public static var defaultDifficulties:Array<String> = ['Easy', 'Normal', 'Hard'];
	public static var defaultDifficulty:String = 'Normal'; // The chart that has no suffix and starting difficulty on Freeplay/Story Mode

	public static var difficulties:Array<String> = [];

	inline public static function quantize(f:Float, snap:Float)
	{
		// changed so this actually works lol
		var m:Float = Math.fround(f * snap);
		return (m / snap);
	}

	public static function getDifficultyFilePath(?num:Int = null)
	{
		if (num == null)
			num = PlayState.storyDifficulty;
		if (num >= difficulties.length)
			num = difficulties.length - 1;

		var fileSuffix:String = difficulties[num];
		if (fileSuffix == null)
		{
			fileSuffix = '';
		}
		else
		{
			if (fileSuffix != defaultDifficulty)
			{
				fileSuffix = '-$fileSuffix';
			}
			else
			{
				fileSuffix = '';
			}
		}
		return Paths.formatToSongPath(fileSuffix);
	}

	public static function difficultyString():String
	{
		return difficulties[PlayState.storyDifficulty].toUpperCase();
	}

	public static function formatSong(song:String, ?diff:Int):String
	{
		return Paths.formatToSongPath(song) + getDifficultyFilePath(diff);
	}

	public static function floorDecimal(value:Float, decimals:Int):Float
	{
		if (decimals < 1)
		{
			return Math.floor(value);
		}

		var tempMult:Float = 1;
		for (i in 0...decimals)
		{
			tempMult *= 10;
		}
		var newValue:Float = Math.floor(value * tempMult);
		return newValue / tempMult;
	}

	public static function setVarInArray(instance:Dynamic, variable:String, value:Dynamic):Any
	{
		var shit:Array<String> = variable.split('[');
		if (shit.length > 1)
		{
			var blah:Dynamic = Reflect.getProperty(instance, shit[0]);
			for (i in 1...shit.length)
			{
				var leNum:Dynamic = shit[i].substr(0, shit[i].length - 1);
				if (i >= shit.length - 1) // Last array
					blah[leNum] = value;
				else // Anything else
					blah = blah[leNum];
			}
			return blah;
		}

		// fixes for html5
		switch (Type.typeof(Reflect.getProperty(instance, variable)))
		{
			case ValueType.TInt:
				if (Std.isOfType(value, String))
				{
					Reflect.setProperty(instance, variable, Std.parseInt(value));
				}
				else
				{
					Reflect.setProperty(instance, variable, value);
				}
			case ValueType.TFloat:
				if (Std.isOfType(value, String))
				{
					Reflect.setProperty(instance, variable, Std.parseFloat(value));
				}
				else
				{
					Reflect.setProperty(instance, variable, value);
				}
			case ValueType.TBool:
				if (Std.isOfType(value, String))
				{
					Reflect.setProperty(instance, variable, (value == 'true'));
				}
				else
				{
					Reflect.setProperty(instance, variable, value);
				}
			default:
				Reflect.setProperty(instance, variable, value);
		}
		return true;
	}

	public static function getPropertyLoopThingWhatever(killMe:Array<String>, ?checkForTextsToo:Bool = true, ?getProperty:Bool = true):Dynamic
	{
		var coverMeInPiss:Dynamic = getObjectDirectly(killMe[0], checkForTextsToo);
		var end = killMe.length;
		if (getProperty)
			end = killMe.length - 1;

		for (i in 1...end)
		{
			coverMeInPiss = getVarInArray(coverMeInPiss, killMe[i]);
		}
		return coverMeInPiss;
	}

	public static function getObjectDirectly(objectName:String, ?checkForTextsToo:Bool = true):Dynamic
	{
		var coverMeInPiss:Dynamic = getVarInArray(PlayState.instance, objectName);
		return coverMeInPiss;
	}

	public static function getVarInArray(instance:Dynamic, variable:String):Any
	{
		var shit:Array<String> = variable.split('[');
		if (shit.length > 1)
		{
			var blah:Dynamic = Reflect.getProperty(instance, shit[0]);
			for (i in 1...shit.length)
			{
				var leNum:Dynamic = shit[i].substr(0, shit[i].length - 1);
				blah = blah[leNum];
			}
			return blah;
		}
		return Reflect.getProperty(instance, variable);
	}

	inline public static function boundTo(value:Float, min:Float, max:Float):Float
	{
		return Math.max(min, Math.min(max, value));
	}

	public static function coolTextFile(path:String)
	{
		var daList:Array<String> = [];
		if (Paths.exists(path, TEXT))
			daList = Paths.getContent(path).trim().split('\n');

		for (i in 0...daList.length)
		{
			daList[i] = daList[i].trim();
		}

		return daList;
	}

	public static function coolArrayTextFile(path:String)
	{
		var daList:Array<String> = [];
		var daArray:Array<Array<String>> = [];
		if (Paths.exists(path, TEXT))
			daList = Paths.getContent(path).trim().split('\n');

		for (i in 0...daList.length)
		{
			daList[i] = daList[i].trim();
		}

		for (i in daList)
		{
			daArray.push(i.split(' '));
		}

		return daArray;
	}

	public static function dominantColor(sprite:FlxSprite):Int
	{
		var countByColor:Map<Int, Int> = [];
		for (col in 0...sprite.frameWidth)
		{
			for (row in 0...sprite.frameHeight)
			{
				var colorOfThisPixel:Int = sprite.pixels.getPixel32(col, row);
				if (colorOfThisPixel != 0)
				{
					if (countByColor.exists(colorOfThisPixel))
					{
						countByColor[colorOfThisPixel] = countByColor[colorOfThisPixel] + 1;
					}
					else if (countByColor[colorOfThisPixel] != 13520687 - (2 * 13520687))
					{
						countByColor[colorOfThisPixel] = 1;
					}
				}
			}
		}
		var maxCount = 0;
		var maxKey:Int = 0; // after the loop this will store the max color
		countByColor[FlxColor.BLACK] = 0;
		for (key in countByColor.keys())
		{
			if (countByColor[key] >= maxCount)
			{
				maxCount = countByColor[key];
				maxKey = key;
			}
		}
		return maxKey;
	}

	public static function numberArray(max:Int, ?min = 0):Array<Int>
	{
		var dumbArray:Array<Int> = [];
		for (i in min...max)
			dumbArray.push(i);
		return dumbArray;
	}

	public static function browserLoad(site:String)
	{
		#if linux
		Sys.command('/usr/bin/xdg-open', [site]);
		#else
		FlxG.openURL(site);
		#end
	}

	public static function getDifficulties(?song:String = '', ?remove:Bool = false)
	{
		song = Paths.formatToSongPath(song);
		difficulties = defaultDifficulties.copy();
		var diffStr:String = WeekData.getCurrentWeek().difficulties;

		var meta = Song.getMetaFile(song);
		if (meta.freeplayDifficulties != null && meta.freeplayDifficulties.length > 0)
			diffStr = meta.freeplayDifficulties;

		if (diffStr == null || diffStr.length == 0)
			diffStr = 'Easy,Normal,Hard';
		diffStr = diffStr.trim(); // Fuck you HTML5

		if (diffStr != null && diffStr.length > 0)
		{
			var diffs:Array<String> = diffStr.split(',');
			var i = 0;
			var len = diffs.length;
			while (i < len)
			{
				if (diffs[i] != null)
				{
					diffs[i] = diffs[i].trim();
					if (diffs[i].length < 1 || diffs[i] == null)
					{
						diffs.remove(diffs[i]);
					}
					else
					{
						i++;
					}
				}
				else
				{
					diffs.remove(diffs[i]);
				}
				len = diffs.length;
			}

			if (remove && song.length > 0)
			{
				var i = 0;
				var len = diffs.length;
				while (i < len)
				{
					if (diffs[i] != null)
					{
						var suffix = '-${Paths.formatToSongPath(diffs[i])}';
						if (diffs[i] == defaultDifficulty)
						{
							suffix = '';
						}
						var poop:String = song + suffix;
						if (!Paths.existsPath('data/$song/$poop.json', TEXT))
						{
							diffs.remove(diffs[i]);
						}
						else
						{
							i++;
						}
					}
					else
					{
						diffs.remove(diffs[i]);
					}
					len = diffs.length;
				}
			}

			if (diffs.length > 0 && diffs[0].length > 0)
			{
				difficulties = diffs;
			}
		}
	}

	public static function setWindowIcon(image:String = 'iconOG')
	{
		Image.loadFromFile(Paths.getPath('images/$image.png', IMAGE)).onComplete(function(img)
		{
			Application.current.window.setIcon(img);
		});
	}

	public static function playMenuMusic(volume:Float = 1)
	{
		FlxG.sound.playMusic(Paths.music('freakyMenu'), volume * ClientPrefs.menuMusicVolume);
	}

	public static function playPvPMusic(volume:Float = 1)
	{
		var songs:Array<String> = [];
		var directories = [Paths.getPreloadPath()];
		#if MODS_ALLOWED
		directories.push(Paths.mods());
		#end
		for (i in 0...directories.length)
		{
			var path = Path.join([directories[i], 'music/pvp/']);
			if (FileSystem.exists(path) && FileSystem.isDirectory(path))
			{
				for (j in FileSystem.readDirectory(path))
				{
					if (j.endsWith('.ogg'))
						songs.push('pvp/' + j.substring(0, j.length - 4));
				}
			}
		}
		FlxG.sound.playMusic(Paths.music(songs[FlxG.random.int(0, songs.length - 1)]), volume * ClientPrefs.menuMusicVolume);
	}

	public static function playScrollSound(volume:Float = 1)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), volume);
	}

	public static function playConfirmSound(volume:Float = 1)
	{
		FlxG.sound.play(Paths.sound('confirmMenu'), volume);
	}

	public static function playCancelSound(volume:Float = 1)
	{
		FlxG.sound.play(Paths.sound('cancelMenu'), volume);
	}

	public static function sortAlphabetically(a:String, b:String):Int
	{
		var val1 = a.toUpperCase();
		var val2 = b.toUpperCase();
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

	public static function inPlayState()
	{
		return PlayState.instance != null;
	}

	public static function getPlayState():Dynamic
	{
		return PlayState.instance;
	}

	public static function alert(message:String, title:String = 'Error!')
	{
		if (!FlxG.fullscreen)
			Application.current.window.alert(message, title);
		trace(title + ': ' + message);
	}

	public static function getCamFollowCharacter(char:Character):Dynamic
	{
		return {
			x: (char.x * char.scrollFactor.x) + (char.width / 2),
			y: (char.y * char.scrollFactor.y) + (char.height / 4)
		};
	}

	public static function scrollSpeedFromBPM(bpm:Float, denominator:Int = 4, noteSize:Float = 112)
	{
		var stepCrochet = (((60 / bpm) * 4000) / denominator) / 4;
		var noteY = 0.45 * stepCrochet;
		return FlxMath.roundDecimal(noteSize / noteY, 2);
	}

	public static function existsVoices(song:String)
	{
		song = Paths.formatToSongPath(song);
		return Paths.existsPath('songs/$song/Voices.${Paths.SOUND_EXT}', MUSIC)
			|| Paths.existsPath('songs/$song/Voices${CoolUtil.getDifficultyFilePath()}.${Paths.SOUND_EXT}', MUSIC);
	}

	public static function cancelMusicFadeTween()
	{
		if (FlxG.sound.music.fadeTween != null)
			FlxG.sound.music.fadeTween.cancel();

		FlxG.sound.music.fadeTween = null;
	}

	public static function removeSpriteGraphic(spr:FlxSprite)
	{
		var graphic = spr.graphic;
		@:privateAccess
		if (graphic.useCount <= 1)
		{
			var key = graphic.key;
			FlxG.bitmap.remove(graphic);
			Paths.localTrackedAssets.remove(key);
			Paths.currentTrackedAssets.remove(key);
			spr.frames = null;
		}
	}
}
