package;

import haxe.Json;
import haxe.io.Path;

using StringTools;

#if sys
import sys.FileSystem;
#end

typedef WeekFile =
{
	// JSON variables
	var songs:Array<Array<Dynamic>>;
	var weekName:String;
	var ?difficulties:String;
	var ?icon:String;
}

class WeekData
{
	public static var weeksLoaded:Map<String, WeekData> = new Map();
	public static var weeksList:Array<String> = [];

	// JSON variables
	public var songs:Array<Array<Dynamic>>;
	public var weekName:String;
	public var difficulties:String;
	public var icon:String;

	public var fileName:String;

	public static function createWeekFile():WeekFile
	{
		var weekFile:WeekFile = {
			songs: [
				["Bopeebo", "dad", [146, 113, 253]],
				["Fresh", "dad", [146, 113, 253]],
				["Dad Battle", "dad", [146, 113, 253]]
			],
			weekName: 'Custom Week',
			difficulties: '',
			icon: 'bf'
		};
		return weekFile;
	}

	public function new(weekFile:WeekFile, fileName:String)
	{
		var template = createWeekFile();
		for (i in Reflect.fields(weekFile))
		{
			if (Reflect.hasField(template, i))
			{ // just doing Reflect.hasField on itself doesnt work for some reason so we are doing it on a template
				Reflect.setProperty(this, i, Reflect.field(weekFile, i));
			}
		}

		this.fileName = fileName;
	}

	public static function reloadWeekFiles()
	{
		weeksList = [];
		weeksLoaded.clear();

		var directories:Array<String> = [];
		#if MODS_ALLOWED
		directories.push(Paths.mods());
		#end
		var originalLength:Int = directories.length;

		var sexList:Array<String> = CoolUtil.coolTextFile(Paths.getPreloadPath('weeks/weekList.txt'));
		for (i in 0...sexList.length)
		{
			var fileToCheck:String = '${Paths.getPreloadPath()}weeks/${sexList[i]}.json';
			addWeek(sexList[i], fileToCheck);
		}

		#if sys
		for (i in 0...directories.length)
		{
			var directory:String = '${directories[i]}weeks/';
			if (FileSystem.exists(directory))
			{
				var listOfWeeks:Array<String> = CoolUtil.coolTextFile('${directory}weekList.txt');
				for (daWeek in listOfWeeks)
				{
					var path:String = '${directory}${daWeek}.json';
					if (FileSystem.exists(path))
					{
						addWeek(daWeek, path);
					}
				}

				for (file in FileSystem.readDirectory(directory))
				{
					var path = Path.join([directory, file]);
					if (!FileSystem.isDirectory(path) && file.endsWith('.json'))
					{
						addWeek(file.substr(0, file.length - 5), path);
					}
				}
			}
		}
		#end
	}

	private static function addWeek(weekToCheck:String, path:String)
	{
		if (!weeksLoaded.exists(weekToCheck))
		{
			var week:WeekFile = getWeekFile(path);
			if (week != null)
			{
				var weekFile:WeekData = new WeekData(week, weekToCheck);
				weeksLoaded.set(weekToCheck, weekFile);
				weeksList.push(weekToCheck);
			}
		}
	}

	private static function getWeekFile(path:String):WeekFile
	{
		try
		{
			var rawJson:String = null;
			if (Paths.exists(path))
				rawJson = Paths.getContent(path);

			if (rawJson != null && rawJson.length > 0)
				return cast Json.parse(rawJson);
		}
		catch (e:Dynamic)
			trace(e);

		return null;
	}

	//   FUNCTIONS YOU WILL PROBABLY NEVER NEED TO USE
	public static function getWeekFileName():String
	{
		return weeksList[PlayState.storyWeek];
	}

	public static function getCurrentWeek():WeekData
	{
		return weeksLoaded.get(weeksList[PlayState.storyWeek]);
	}
}
