package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

class SongSelect extends FlxSpriteGroup
{
	public static var lastCategoriesSelected:Array<Null<Int>> = [];
	public static var lastSongsSelected:Array<Null<Int>> = [];
	public static var lastDiff:Array<Null<Int>> = [];
	public static var lastDiffName:Array<String> = [];

	public var songs:Array<SongMetadata> = [];
	public var id:Int = 0;
	public var difficulties:Array<String> = ['Easy', 'Normal', 'Hard'];
	public var ready:Bool = false;
	public var curSongSelected:Int = 0;
	public var curCategorySelected:Int = 0;
	public var curDifficulty:Int = -1;
	public var storyWeek:Int = 0;
	public var selectedRandom:Bool = false;
	public var curSongs:Array<SongMetadata> = [];

	var categories:Array<Array<Dynamic>> = [];
	var isGamepad:Bool = false;
	var lastDifficultyName:String = '';
	var scoreBG:FlxSprite;
	var diffText:FlxText;
	var grpCategories:FlxTypedSpriteGroup<FlxText>;
	var grpCategoryIcons:FlxTypedSpriteGroup<HealthIcon>;
	var grpSongs:FlxTypedSpriteGroup<FlxText>;
	var grpSongIcons:FlxTypedSpriteGroup<HealthIcon>;
	var bg:FlxSprite;
	var intendedColor:Int;
	var colorTween:FlxTween;
	var noGamepadBlack:FlxSprite;
	var noGamepadText:FlxText;
	var noGamepadSine:Float = 0;
	var choosingSong:Bool = false;
	var curGroup(get, never):FlxTypedSpriteGroup<FlxText>;
	var curIconGroup(get, never):FlxTypedSpriteGroup<HealthIcon>;
	var curSelected(get, never):Int;
	var lastCategorySelected:Int = -1;
	var songTextMap:Map<String, FlxText> = new Map();
	var iconMap:Map<String, HealthIcon> = new Map();

	public function new(x:Float = 0, y:Float = 0, songs:Array<SongMetadata>, categories:Array<Array<Dynamic>>, id:Int = 0)
	{
		super(x, y);
		this.songs = songs.copy();
		this.categories = categories.copy();
		this.id = id;
		isGamepad = MultiControls.isPositionGamepad(id);

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		bg.scrollFactor.set();
		var daClipRect = new FlxRect((id > 0 ? FlxG.width / 2 : 0), 0, FlxG.width / 2, bg.frameHeight);
		bg.clipRect = daClipRect;
		add(bg);
		bg.x = 0;

		bg.color = FlxColor.fromRGB(253, 232, 113);

		grpCategories = new FlxTypedSpriteGroup();
		add(grpCategories);
		grpCategoryIcons = new FlxTypedSpriteGroup();
		add(grpCategoryIcons);
		grpSongs = new FlxTypedSpriteGroup();
		add(grpSongs);
		grpSongIcons = new FlxTypedSpriteGroup();
		add(grpSongIcons);

		createCategories();
		createSongs();

		if (lastCategoriesSelected[id] != null)
		{
			curCategorySelected = lastCategoriesSelected[id];
			lastCategorySelected = curCategorySelected;
			if (curCategorySelected > 0)
			{
				curSongs = categories[curCategorySelected - 1][1];
				regenMenu();
			}
		}
		if (lastSongsSelected[id] != null)
			curSongSelected = lastSongsSelected[id];

		scoreBG = new FlxSprite((FlxG.width / 2) * 0.7 - 6, 0).makeGraphic(195, 24, 0xFF000000);
		scoreBG.alpha = 0.6;
		scoreBG.visible = false;
		add(scoreBG);

		diffText = new FlxText(0, 0, 0, "", 24);
		diffText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER);
		diffText.x = Std.int((scoreBG.x + (scoreBG.width / 2)) - (diffText.width / 2));
		diffText.visible = false;
		add(diffText);

		if (isGamepad)
		{
			noGamepadBlack = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width / 2), 720, FlxColor.BLACK);
			noGamepadBlack.scrollFactor.set();
			noGamepadBlack.alpha = 0.8;
			noGamepadBlack.visible = MultiControls.positionActive(id);
			add(noGamepadBlack);

			noGamepadText = new FlxText(0, 360 - 16, FlxG.width / 2, "Waiting for gamepad...", 32);
			noGamepadText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			noGamepadText.scrollFactor.set();
			noGamepadText.borderSize = 2;
			noGamepadText.visible = MultiControls.positionActive(id);
			add(noGamepadText);
		}

		if (lastDiff[id] == null)
		{
			lastDifficultyName = CoolUtil.defaultDifficulty;
			curDifficulty = FlxMath.maxInt(0, CoolUtil.defaultDifficulties.indexOf(lastDifficultyName));
		}
		else
		{
			lastDifficultyName = lastDiffName[id];
			curDifficulty = lastDiff[id];
		}

		setClipRect();
		changeCategorySelection();
	}

	var holdTime:Float = 0;

	override function update(elapsed:Float)
	{
		if (!SongSelectState.exiting)
		{
			var upP = MultiControls.positionCheck(UI_UP_P, id);
			var downP = MultiControls.positionCheck(UI_DOWN_P, id);
			var leftP = MultiControls.positionCheck(UI_LEFT_P, id);
			var rightP = MultiControls.positionCheck(UI_RIGHT_P, id);
			var up = MultiControls.positionCheck(UI_UP, id);
			var down = MultiControls.positionCheck(UI_DOWN, id);
			var accept = MultiControls.positionCheck(ACCEPT, id);
			var back = MultiControls.positionCheck(BACK_P, id);

			if (isGamepad)
			{
				noGamepadBlack.visible = !MultiControls.positionActive(id);
				noGamepadText.visible = !MultiControls.positionActive(id);
			}

			if (choosingSong)
			{
				if (!ready)
				{
					if (grpSongs.length > 1)
					{
						if (upP)
						{
							changeSongSelection(-1);
							holdTime = 0;
						}
						if (downP)
						{
							changeSongSelection(1);
							holdTime = 0;
						}

						if (down || up)
						{
							var checkLastHold:Int = Math.floor((holdTime - 0.5) * 20);
							holdTime += elapsed;
							var checkNewHold:Int = Math.floor((holdTime - 0.5) * 20);

							if (holdTime > 0.5 && checkNewHold - checkLastHold > 0)
							{
								changeSongSelection((checkNewHold - checkLastHold) * (up ? -1 : 1));
							}
						}
					}

					if (grpSongs.length > 0 && difficulties.length > 1)
					{
						if (leftP)
							changeDiff(-1);
						else if (rightP)
							changeDiff(1);
					}
				}

				if (back)
				{
					if (!ready)
					{
						grpCategoryIcons.visible = grpCategories.visible = true;
						scoreBG.visible = diffText.visible = grpSongs.visible = grpSongIcons.visible = false;
						choosingSong = false;
						doColorTween(FlxColor.fromRGB(253, 232, 113));
					}
					else
					{
						playerUnready();
					}
					CoolUtil.playCancelSound();
				}
				else if (curSongs.length > 0 && accept && !ready)
					playerReady();
			}
			else
			{
				if (!ready && grpCategories.length > 1)
				{
					if (upP)
					{
						changeCategorySelection(-1);
						holdTime = 0;
					}
					if (downP)
					{
						changeCategorySelection(1);
						holdTime = 0;
					}

					if (down || up)
					{
						var checkLastHold:Int = Math.floor((holdTime - 0.5) * 20);
						holdTime += elapsed;
						var checkNewHold:Int = Math.floor((holdTime - 0.5) * 20);

						if (holdTime > 0.5 && checkNewHold - checkLastHold > 0)
						{
							changeCategorySelection((checkNewHold - checkLastHold) * (up ? -1 : 1));
						}
					}
				}

				if (back && ready)
				{
					playerUnready();
					selectedRandom = false;
					CoolUtil.playCancelSound();
				}
				else if (grpCategories.length > 0 && accept && !ready)
				{
					if (curCategorySelected == 0)
					{
						playerReady();
						selectedRandom = true;
					}
					else
					{
						choosingSong = true;
						if (lastCategorySelected != curCategorySelected)
						{
							curSongs = categories[curCategorySelected - 1][1];
							regenMenu();
							curSongSelected = 0;
						}
						changeSongSelection(0, false);
						grpCategoryIcons.visible = grpCategories.visible = false;
						scoreBG.visible = diffText.visible = grpSongs.visible = grpSongIcons.visible = true;
						CoolUtil.playScrollSound();
						lastCategorySelected = curCategorySelected;
					}
				}
			}
		}

		var bullShit:Int = 0;
		var lerpVal:Float = CoolUtil.boundTo(elapsed * 9.6, 0, 1);
		for (i in 0...curGroup.length)
		{
			var item = curGroup.members[i];
			var targetY = bullShit - curSelected;
			var scaledY = FlxMath.remapToRange(targetY, 0, 1, 0, 1.3);
			item.y = FlxMath.lerp(item.y, (scaledY * 80) + (FlxG.height * 0.48), lerpVal);
			item.x = FlxMath.lerp(item.x, (targetY * 20) + 90 + (id > 0 ? FlxG.width / 2 : 0), lerpVal);
			bullShit++;

			if (targetY == 0)
				item.alpha = 1;
			else if (!ready)
				item.alpha = 0.6;
			else
				item.alpha = 0;

			curIconGroup.members[i].y = item.y - 15;
		}
		setClipRect();

		if (isGamepad && noGamepadText.visible)
		{
			noGamepadSine += 180 * elapsed;
			noGamepadText.alpha = 1 - Math.sin((Math.PI * noGamepadSine) / 180);
		}

		super.update(elapsed);
	}

	function playerReady()
	{
		ready = true;
		for (i in 0...curGroup.length)
		{
			var item = curGroup.members[i];
			if (item.alpha < 1)
			{
				item.alpha = 0;
				curIconGroup.members[i].alpha = 0;
			}
		}
		CoolUtil.playConfirmSound();
	}

	function playerUnready()
	{
		ready = false;
		for (i in 0...curGroup.length)
		{
			var item = curGroup.members[i];
			var daAlpha = (i == curSelected ? 1 : 0.6);
			curIconGroup.members[i].alpha = item.alpha = daAlpha;
		}
	}

	private function positionHighscore()
	{
		diffText.x = Std.int(scoreBG.x + (scoreBG.width / 2));
		diffText.x -= diffText.width / 2;
	}

	function difficultyString():String
	{
		return difficulties[curDifficulty].toUpperCase();
	}

	function changeDiff(change:Int = 0)
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = difficulties.length - 1;
		if (curDifficulty >= difficulties.length)
			curDifficulty = 0;

		if (curSongs[curSongSelected].random)
		{
			curDifficulty = 0;
			lastDifficultyName = '';
			diffText.text = '';
		}
		else
		{
			lastDifficultyName = difficulties[curDifficulty];

			if (difficulties.length > 1)
			{
				diffText.text = '< ${difficultyString()} >';
			}
			else
			{
				diffText.text = difficultyString();
			}
			positionHighscore();
		}
		lastDiff[id] = curDifficulty;
		lastDiffName[id] = lastDifficultyName;
	}

	function changeSongSelection(change:Int = 0, playSound:Bool = true)
	{
		if (playSound)
			CoolUtil.playScrollSound();

		curSongSelected += change;

		if (curSongSelected < 0)
			curSongSelected = curSongs.length - 1;
		if (curSongSelected >= curSongs.length)
			curSongSelected = 0;

		if (curSongs.length > 0)
		{
			doColorTween(curSongs[curSongSelected].color);

			for (i in 0...curIconGroup.length)
				curIconGroup.members[i].alpha = (curSongs[i].random ? 0 : 0.6);

			if (curIconGroup.members[curSongSelected] != null && !curSongs[curSongSelected].random)
				curIconGroup.members[curSongSelected].alpha = 1;

			storyWeek = curSongs[curSongSelected].week;

			if (curSongs[curSongSelected].difficulties == null)
			{
				CoolUtil.getDifficulties(curSongs[curSongSelected].songName, true);
				difficulties = CoolUtil.difficulties.copy();
			}
			else
				difficulties = curSongs[curSongSelected].difficulties.split(',');
		}

		if (difficulties.contains(CoolUtil.defaultDifficulty))
			curDifficulty = FlxMath.maxInt(0, CoolUtil.defaultDifficulties.indexOf(CoolUtil.defaultDifficulty));
		else
			curDifficulty = 0;

		var newPos:Int = difficulties.indexOf(lastDifficultyName);
		if (newPos < 0)
			newPos = difficulties.indexOf(lastDifficultyName.charAt(0).toUpperCase() + lastDifficultyName.substr(1));
		if (newPos < 0)
			newPos = difficulties.indexOf(lastDifficultyName.toLowerCase());
		if (newPos < 0)
			newPos = difficulties.indexOf(lastDifficultyName.toUpperCase());
		if (newPos > -1)
		{
			curDifficulty = newPos;
		}
		changeDiff();
		lastSongsSelected[id] = curSongSelected;
	}

	function changeCategorySelection(change:Int = 0, playSound:Bool = true)
	{
		if (playSound)
			CoolUtil.playScrollSound();

		curCategorySelected += change;

		if (curCategorySelected < 0)
			curCategorySelected = grpCategories.length - 1;
		if (curCategorySelected >= grpCategories.length)
			curCategorySelected = 0;

		for (i in 0...curIconGroup.length)
			curIconGroup.members[i].alpha = 0.6;

		if (curIconGroup.members[curCategorySelected] != null)
			curIconGroup.members[curCategorySelected].alpha = 1;

		lastCategoriesSelected[id] = curCategorySelected;
	}

	function doColorTween(newColor:Int)
	{
		if (newColor != intendedColor)
		{
			if (colorTween != null)
			{
				colorTween.cancel();
			}
			intendedColor = newColor;
			colorTween = FlxTween.color(bg, 1, bg.color, intendedColor, {
				onComplete: function(twn:FlxTween)
				{
					colorTween = null;
				}
			});
		}
	}

	public function selectRandom()
	{
		curSongs = songs;
		curSongSelected = FlxG.random.int(0, curSongs.length - 1);
		storyWeek = curSongs[curSongSelected].week;
		if (curSongs[curSongSelected].difficulties == null)
		{
			CoolUtil.getDifficulties(curSongs[curSongSelected].songName, true);
			difficulties = CoolUtil.difficulties.copy();
		}
		else
			difficulties = curSongs[curSongSelected].difficulties.split(',');
		curDifficulty = FlxG.random.int(0, difficulties.length - 1);
		trace('selected random: ' + curSongs[curSongSelected].songName);
	}

	function createCategories()
	{
		var fullCategories:Array<Array<Dynamic>> = [['Pick Random', '!random']];
		for (category in categories)
		{
			fullCategories.push([category[0], category[2]]);
		}

		for (i in 0...fullCategories.length)
		{
			var categoryText = new FlxText(0, (35 * i) + 15, 0, fullCategories[i][0]);
			categoryText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
			if (90 + categoryText.width > 640)
			{
				var textScale:Float = (550 / categoryText.width);

				categoryText.size = Math.round(categoryText.size * textScale);
			}
			categoryText.borderSize = 2;
			grpCategories.add(categoryText);

			var icon:HealthIcon = new HealthIcon(fullCategories[i][1]);
			icon.scale.set(0.5, 0.5);
			updateIconHitbox(icon);
			icon.sprTracker = categoryText;
			icon.xAdd = -5;
			icon.yAdd = 15;
			icon.updatePosition();
			grpCategoryIcons.add(icon);
		}

		if (curCategorySelected >= fullCategories.length)
			curCategorySelected = 0;
	}

	function createSongs()
	{
		for (i in 0...songs.length)
		{
			var songText = new FlxText(x, (35 * i) + 15, 0, songs[i].displayName);
			songText.visible = false;
			songText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
			if (170 + songText.width > 640)
			{
				var textScale:Float = (470 / songText.width);
				songText.size = Math.round(songText.size * textScale);
			}
			songText.borderSize = 2;

			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.visible = false;
			icon.scale.set(0.5, 0.5);
			updateIconHitbox(icon);
			icon.sprTracker = songText;
			icon.xAdd = -5;
			icon.yAdd = 15;
			icon.updatePosition();

			songTextMap.set(songs[i].songName, songText);
			iconMap.set(songs[i].songName, icon);
		}
	}

	function regenMenu()
	{
		grpSongs.clear();
		grpSongIcons.clear();
		for (i in 0...curSongs.length)
		{
			var songText = songTextMap.get(curSongs[i].songName);
			grpSongs.add(songText);
			songText.setPosition(x, (35 * i) + 15);

			var icon = iconMap.get(curSongs[i].songName);
			grpSongIcons.add(icon);
			icon.updatePosition();
		}
	}

	function updateIconHitbox(icon:HealthIcon)
	{
		icon.updateHitbox();
		icon.offset.set((-0.5 * (icon.width - icon.frameWidth)) + (icon.iconOffsets[0] * icon.scale.x),
			(-0.5 * (icon.height - icon.frameHeight)) + (icon.iconOffsets[1] * icon.scale.y));
	}

	function setClipRect()
	{
		var sprites:Array<FlxSprite> = [];
		for (spr in curGroup)
			sprites.push(spr);
		for (spr in curIconGroup)
			sprites.push(spr);
		for (spr in sprites)
		{
			var isAttached = false;
			if (Std.isOfType(spr, HealthIcon))
			{
				var spr:HealthIcon = cast spr;
				if (spr.sprTracker != null && spr.sprTracker.active)
					isAttached = true;
			}
			if (!isAttached && (spr.x + spr.width < x || spr.x > x + (FlxG.width / 2)))
			{
				spr.visible = false;
				spr.active = false;
			}
			else
			{
				spr.visible = true;
				spr.active = true;
				var swagRect = new FlxRect(0, 0, spr.frameWidth, spr.frameHeight);
				if (spr.x < x)
				{
					swagRect.x += Math.abs(x - spr.x) / spr.scale.x;
					swagRect.width -= swagRect.x;
				}
				else if (spr.x + spr.width > x + (FlxG.width / 2))
				{
					swagRect.width -= ((spr.x + spr.width) - (x + (FlxG.width / 2))) / spr.scale.x;
				}
				spr.clipRect = swagRect;
			}
		}
	}

	function get_curGroup()
	{
		return choosingSong ? grpSongs : grpCategories;
	}

	function get_curIconGroup()
	{
		return choosingSong ? grpSongIcons : grpCategoryIcons;
	}

	function get_curSelected()
	{
		return choosingSong ? curSongSelected : curCategorySelected;
	}

	override function destroy()
	{
		super.destroy();
		songs = null;
		difficulties = null;
		categories = null;
		curSongs = null;
		lastDifficultyName = null;
		scoreBG = null;
		diffText = null;
		grpCategories = null;
		grpCategoryIcons = null;
		grpSongs = null;
		grpSongIcons = null;
		bg = null;
		if (colorTween != null)
			colorTween.cancel();
		colorTween = null;
		noGamepadBlack = null;
		noGamepadText = null;
	}
}
