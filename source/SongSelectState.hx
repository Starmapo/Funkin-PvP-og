package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;

using StringTools;

#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end

class SongSelectState extends MusicBeatState
{
	public static var exiting:Bool = false;

	var songsOG:Array<SongMetadata> = [];
	var categories:Array<Array<Dynamic>> = [];
	var songSelects:Array<SongSelect> = [];
	var returnBar:FlxBar;
	var returnTime:Float = 0;

	override function create()
	{
		super.create();

		exiting = false;
		FlxG.mouse.visible = false;

		persistentUpdate = true;
		WeekData.reloadWeekFiles();
		CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		for (i in 0...WeekData.weeksList.length)
		{
			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			var curSongs:Array<SongMetadata> = [];
			for (song in leWeek.songs)
			{
				var colors:Array<Int> = song[2];
				if (colors == null || colors.length != 3)
					colors = [146, 113, 253];

				var metadata = new SongMetadata(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]), Song.getDisplayName(song[0]));
				songsOG.push(metadata);
				curSongs.push(metadata);
			}
			categories.push([leWeek.weekName, curSongs, leWeek.icon]);
		}
		songsOG.sort(sortAlphabetically);
		trace('song count: ' + songsOG.length);
		categories.unshift(['All Songs', songsOG.copy()]);

		var songSelect1 = new SongSelect(0, 0, songsOG, categories, 0);
		songSelects.push(songSelect1);
		add(songSelect1);
		var songSelect2 = new SongSelect(FlxG.width / 2, 0, songsOG, categories, 1);
		songSelects.push(songSelect2);
		add(songSelect2);

		var line = new FlxSprite().makeGraphic(3, FlxG.height, FlxColor.WHITE);
		line.screenCenter(X);
		add(line);

		#if cpp
		var textBG:FlxSprite = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000);
		textBG.alpha = 0.6;
		add(textBG);

		var leText:String = "Press CTRL to open the Gameplay Changers Menu";
		var text:FlxText = new FlxText(textBG.x, textBG.y + 4, FlxG.width, leText, 16);
		text.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT);
		text.scrollFactor.set();
		add(text);
		#end

		returnBar = new FlxBar(0, 0, LEFT_TO_RIGHT, 200, 40, this, 'returnTime', 0.2, 1.2);
		returnBar.createFilledBar(0xFF000000, 0xFFFFFFFF, true, FlxColor.BLACK);
		returnBar.screenCenter(X);
		returnBar.scrollFactor.set();
		add(returnBar);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (!exiting)
		{
			#if cpp
			var ctrl = FlxG.keys.justPressed.CONTROL;

			var gamepad = FlxG.gamepads.lastActive;
			if (gamepad != null)
			{
				if (gamepad.justPressed.X)
					ctrl = true;
			}

			if (ctrl)
			{
				persistentUpdate = false;
				openSubState(new GameplayChangersSubState());
				return;
			}
			#end

			var go:Bool = !exiting && songSelects[0].ready && songSelects[1].ready;
			if (Main.debug && !MultiControls.playerActive(1))
				go = !exiting && (songSelects[0].ready || songSelects[1].ready);

			if (go)
			{
				for (i in 0...songSelects.length)
				{
					if (songSelects[i].selectedRandom || !songSelects[i].ready)
						songSelects[i].selectRandom();
				}
				var select = FlxG.random.int(0, 1);
				var firstSelect = songSelects[select];
				var secondSelect = songSelects[1 - select];

				var directories = [Paths.getPreloadPath()];
				#if MODS_ALLOWED
				directories.push(Paths.mods());
				#end
				var tiebreakers = [];
				for (directory in directories)
				{
					var daFile = CoolUtil.coolTextFile(directory + 'data/pvpTiebreakers.txt');
					for (i in daFile)
					{
						if (i != firstSelect.curSongs[firstSelect.curSongSelected].songName
							&& i != secondSelect.curSongs[secondSelect.curSongSelected].songName)
							tiebreakers.push(i);
					}
				}
				if (tiebreakers.length < 1)
					tiebreakers.push('stress');

				var chosenTiebreaker = Paths.formatToSongPath(tiebreakers[FlxG.random.int(0, tiebreakers.length - 1)]);
				var tiebreakerWeek = 0;
				var tiebreakerDiffs = '';
				for (i in songsOG)
				{
					if (Paths.formatToSongPath(i.songName) == chosenTiebreaker)
					{
						tiebreakerWeek = i.week;
						if (i.difficulties != null)
							tiebreakerDiffs = i.difficulties;
						break;
					}
				}

				PlayState.storyPlaylist = [
					firstSelect.curSongs[firstSelect.curSongSelected].songName,
					secondSelect.curSongs[secondSelect.curSongSelected].songName,
					chosenTiebreaker
				];
				trace(PlayState.storyPlaylist);
				PlayState.storyDifficulties = [firstSelect.curDifficulty, secondSelect.curDifficulty, -1];
				PlayState.storyWeeks = [firstSelect.storyWeek, secondSelect.storyWeek, tiebreakerWeek];
				PlayState.tiebreakerDiffs = tiebreakerDiffs.split(',');

				PlayState.storyDifficulty = PlayState.storyDifficulties[0];
				PlayState.storyWeek = PlayState.storyWeeks[0];

				persistentUpdate = false;
				var song:String = PlayState.storyPlaylist[0];
				CoolUtil.getDifficulties(song, true);
				var poop:String = CoolUtil.formatSong(song, PlayState.storyDifficulties[0]);
				trace(poop);
				PlayState.SONG = Song.loadFromJson(poop, song);

				trace('CURRENT WEEK: ${WeekData.getWeekFileName()}');

				MusicBeatState.switchState(new CharacterSelectState());
				exiting = true;
			}
			else
			{
				if (MultiControls.anyCheck(BACK))
				{
					returnTime += elapsed;
					if (returnTime >= 0.2)
					{
						returnBar.visible = true;
						if (returnTime >= 1.2)
						{
							exiting = true;
							MusicBeatState.switchState(new PvPState());
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
	}

	override function closeSubState()
	{
		persistentUpdate = true;
		super.closeSubState();
	}

	function sortAlphabetically(a:SongMetadata, b:SongMetadata):Int
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
