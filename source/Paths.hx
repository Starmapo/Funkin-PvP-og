package;

import flash.media.Sound;
import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import lime.utils.Assets;
import openfl.system.System;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;

using StringTools;

#if sys
import openfl.display.BitmapData;
import sys.FileSystem;
import sys.io.File;
#end

class Paths
{
	inline public static var SOUND_EXT = #if web "mp3" #else "ogg" #end;
	public static final VIDEO_EXT = ['mp4', 'webm', 'mov', 'wmv', 'avi', 'flv'];

	public static function excludeAsset(key:String)
	{
		if (!dumpExclusions.contains(key))
			dumpExclusions.push(key);
	}

	public static var dumpExclusions:Array<String> = [
		'assets/images/alphabet.png',
		'assets/sounds/scrollMenu.$SOUND_EXT',
		'assets/sounds/confirmMenu.$SOUND_EXT',
		'assets/sounds/cancelMenu.$SOUND_EXT',
		'assets/music/freakyMenu.$SOUND_EXT',
		'shared:assets/shared/music/breakfast.$SOUND_EXT',
		'shared:assets/shared/music/tea-time.$SOUND_EXT'
	];

	/// haya I love you for the base cache dump I took to the max
	public static function clearUnusedMemory(force:Bool = false)
	{
		// clear non local assets in the tracked assets list
		for (key in currentTrackedAssets.keys())
		{
			// if it is not currently contained within the used local assets
			if (force || (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key)))
			{
				// get rid of it
				var obj = currentTrackedAssets.get(key);
				@:privateAccess
				if (obj != null)
				{
					FlxG.bitmap.remove(obj);
					currentTrackedAssets.remove(key);
				}
			}
		}
		// run the garbage collector for good measure lmfao
		System.gc();
	}

	// define the locally tracked assets
	public static var localTrackedAssets:Array<String> = [];

	public static function clearStoredMemory(force:Bool = false)
	{
		// clear anything not in the tracked assets list
		@:privateAccess
		for (key in FlxG.bitmap._cache.keys())
		{
			var obj = FlxG.bitmap._cache.get(key);
			if (obj != null && (force || !currentTrackedAssets.exists(key)))
			{
				FlxG.bitmap.remove(obj);
			}
		}

		// clear all sounds that are cached
		for (key in currentTrackedSounds.keys())
		{
			if (key != null && (force || (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key))))
			{
				Assets.cache.clear(key);
				currentTrackedSounds.remove(key);
			}
		}
		// flags everything to be cleared out next unused memory clear
		localTrackedAssets = [];
		OpenFlAssets.cache.clear("assets/songs/");
	}

	public static function getPath(file:String, type:AssetType = null)
	{
		#if MODS_ALLOWED
		var modPath = mods(file);
		if (FileSystem.exists(modPath))
		{
			return modPath;
		}
		#end

		return getPreloadPath(file);
	}

	inline public static function getPreloadPath(file:String = '')
	{
		return 'assets/$file';
	}

	inline static public function file(file:String, type:AssetType = TEXT)
	{
		return getPath(file, type);
	}

	inline static public function txt(key:String)
	{
		return getPath('data/$key.txt', TEXT);
	}

	inline static public function xml(key:String)
	{
		return getPath('images/$key.xml', TEXT);
	}

	inline static public function json(key:String)
	{
		return getPath('data/$key.json', TEXT);
	}

	static public function video(key:String)
	{
		for (i in VIDEO_EXT)
		{
			var path = 'assets/videos/$key.$i';
			if (exists(path))
			{
				return path;
			}
		}
		return 'assets/videos/$key.mp4';
	}

	static public function sound(key:String):Sound
	{
		var sound:Sound = returnSound('sounds', key);
		return sound;
	}

	inline static public function soundRandom(key:String, min:Int, max:Int)
	{
		return sound(key + FlxG.random.int(min, max));
	}

	inline static public function music(key:String):Sound
	{
		var file:Sound = returnSound('music', key);
		return file;
	}

	inline static public function inst(song:String, ?suffix:String = ''):Sound
	{
		var songKey:String = 'songs/${formatToSongPath(song)}';
		var inst = returnSound(songKey, 'Inst');
		if (suffix.length > 0 && existsPath('$songKey/Inst$suffix.$SOUND_EXT', SOUND))
			inst = returnSound(songKey, 'Inst$suffix');
		return inst;
	}

	inline static public function voices(song:String, ?suffix:String = ''):Sound
	{
		var songKey:String = 'songs/${formatToSongPath(song)}';
		var voices = returnSound(songKey, 'Voices');
		if (suffix.length > 0 && existsPath('$songKey/Voices$suffix.$SOUND_EXT', SOUND))
			voices = returnSound(songKey, 'Voices$suffix');
		return voices;
	}

	static public function voicesDad(song:String, ?suffix:String = ''):Sound
	{
		var songKey:String = 'songs/${formatToSongPath(song)}';
		var suffixes = ['Dad', 'Opponent'];
		for (dadSuffix in suffixes)
		{
			var voices = returnSound(songKey, 'Voices$dadSuffix');
			if (suffix.length > 0 && existsPath('$songKey/Voices$dadSuffix$suffix.$SOUND_EXT', SOUND))
				voices = returnSound(songKey, 'Voices$dadSuffix$suffix');
			if (voices != null)
				return voices;
		}
		return null;
	}

	inline static public function image(key:String):FlxGraphic
	{
		// streamlined the assets process more
		var returnAsset:FlxGraphic = returnGraphic(key);
		return returnAsset;
	}

	static public function getTextFromFile(key:String):String
	{
		if (exists(getPath(key)))
			return getContent(getPath(key));

		return null;
	}

	inline static public function font(key:String)
	{
		return 'assets/fonts/$key';
	}

	inline static public function exists(key:String, type:AssetType = null)
	{
		#if sys
		if (FileSystem.exists(key))
		{
			return true;
		}
		#end

		if (OpenFlAssets.exists(key, type))
		{
			return true;
		}
		return false;
	}

	inline static public function existsPath(key:String, type:AssetType = null)
	{
		#if sys
		if (FileSystem.exists(getPath(key, type)))
		{
			return true;
		}
		#end

		if (OpenFlAssets.exists(getPath(key, type), type))
		{
			return true;
		}
		return false;
	}

	inline static public function getSparrowAtlas(key:String)
	{
		var imageLoaded:FlxGraphic = returnGraphic(key);
		return FlxAtlasFrames.fromSparrow((imageLoaded != null ? imageLoaded : image(key)), getContent(file('images/$key.xml', TEXT)));
	}

	inline static public function getPackerAtlas(key:String)
	{
		var imageLoaded:FlxGraphic = returnGraphic(key);
		return FlxAtlasFrames.fromSpriteSheetPacker((imageLoaded != null ? imageLoaded : image(key)), getContent(file('images/$key.txt', TEXT)));
	}

	inline static public function getTexturePackerAtlas(key:String)
	{
		var imageLoaded:FlxGraphic = returnGraphic(key);
		return FlxAtlasFrames.fromTexturePackerJson((imageLoaded != null ? imageLoaded : image(key)), getContent(file('images/$key.json', TEXT)));
	}

	inline static public function formatToSongPath(path:String)
	{
		return path.toLowerCase().replace(' ', '-');
	}

	// completely rewritten asset loading? fuck!
	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];

	public static function returnGraphic(key:String, unique:Bool = false)
	{
		var path = getPath('images/$key.png', IMAGE);
		#if sys
		if (FileSystem.exists(path))
		{
			var newKey = FlxG.bitmap.generateKey(null, key, unique);
			if (!currentTrackedAssets.exists(newKey))
			{
				var newBitmap:BitmapData = BitmapData.fromFile(path);
				var newGraphic:FlxGraphic = FlxGraphic.fromBitmapData(newBitmap, unique, newKey);
				newGraphic.persist = true;
				currentTrackedAssets.set(newKey, newGraphic);
			}
			if (!localTrackedAssets.contains(newKey))
				localTrackedAssets.push(newKey);
			return currentTrackedAssets.get(newKey);
		}
		#end
		if (OpenFlAssets.exists(path, IMAGE))
		{
			var newKey = FlxG.bitmap.generateKey(null, key, unique);
			if (!currentTrackedAssets.exists(newKey))
			{
				var newGraphic:FlxGraphic = FlxG.bitmap.add(path, unique, newKey);
				newGraphic.persist = true;
				currentTrackedAssets.set(newKey, newGraphic);
			}
			if (!localTrackedAssets.contains(newKey))
				localTrackedAssets.push(newKey);
			return currentTrackedAssets.get(newKey);
		}
		trace('oh no its returning null NOOOO: $path');
		return null;
	}

	public static var currentTrackedSounds:Map<String, Sound> = [];

	public static function returnSound(path:String, key:String)
	{
		var gottenPath:String = getPath('$path/$key.$SOUND_EXT', SOUND);
		if (!existsPath('$path/$key.$SOUND_EXT', SOUND))
		{
			trace('oh no its returning null NOOOO: $gottenPath');
			return null;
		}
		if (!currentTrackedSounds.exists(gottenPath))
			#if sys
			currentTrackedSounds.set(gottenPath, Sound.fromFile('./' + gottenPath));
			#else
			currentTrackedSounds.set(gottenPath, OpenFlAssets.getSound(gottenPath));
			#end
		if (!localTrackedAssets.contains(gottenPath))
			localTrackedAssets.push(gottenPath);
		return currentTrackedSounds.get(gottenPath);
	}

	inline public static function getContent(path:String)
	{
		#if sys
		if (FileSystem.exists(path))
			return File.getContent(path);
		#else
		if (OpenFlAssets.exists(path))
			return OpenFlAssets.getText(path);
		#end
		return null;
	}

	#if MODS_ALLOWED
	inline static public function mods(key:String = '')
	{
		return 'mods/' + key;
	}
	#end
}
