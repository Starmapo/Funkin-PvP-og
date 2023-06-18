package;

import flixel.tweens.misc.NumTween;
import flixel.math.FlxAngle;
import Character.CharacterGroupFile;
import Conductor.Rating;
import Discord.DiscordClient;
import Note.EventNote;
import Shaders.HighEffect;
import StageData.StageFile;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.effects.FlxTrail;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import lime.media.openal.AL;
import openfl.events.KeyboardEvent;
import openfl.filters.ShaderFilter;

using StringTools;

class PlayState extends MusicBeatState
{
	public static var ratingStuff:Array<Array<Dynamic>> = [
		['You Suck!', 0.2], // From 0% to 19%
		['Shit', 0.4], // From 20% to 39%
		['Bad', 0.5], // From 40% to 49%
		['Bruh', 0.6], // From 50% to 59%
		['Meh', 0.69], // From 60% to 68%
		['Nice', 0.7], // 69%
		['Good', 0.8], // From 70% to 79%
		['Great', 0.9], // From 80% to 89%
		['Sick!', 1], // From 90% to 99%
		['Perfect!!', 1] // The value on this one isn't used actually, since Perfect is always "1"
	];

	public var tweenManager:FlxTweenManager = new FlxTweenManager();
	public var timerManager:FlxTimerManager = new FlxTimerManager();

	// event variables
	private var isCameraOnForcedPos:Bool = false;

	public var boyfriendMap:Map<String, Character> = new Map();
	public var dadMap:Map<String, Character> = new Map();
	public var gfMap:Map<String, Character> = new Map();

	public var stage:Stage;
	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;

	public var boyfriendGroup:FlxTypedSpriteGroup<Character>;
	public var dadGroup:FlxTypedSpriteGroup<Character>;
	public var gfGroup:FlxTypedSpriteGroup<Character>;

	public static var curStage:String = '';
	public static var isPixelStage:Bool = false;
	public static var SONG:SwagSong = null;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulties:Array<Int> = [];
	public static var storyDifficulty:Int = 1;
	public static var storyWeeks:Array<Int> = [];
	public static var storyWeek:Int = 0;

	public var noteKillOffset:Float = 350;
	public var spawnTime:Float = 2000;

	public var vocals:FlxSound;
	public var vocalsDad:FlxSound;

	var foundDadVocals:Bool = false;

	public var dad(get, never):Character;
	public var gf(get, never):Character;
	public var boyfriend(get, never):Character;

	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<EventNote> = [];

	private var strumLine:FlxSprite;

	// Handles the new epic mega sexy cam code that i've done
	public var camFollow:Array<FlxPoint> = [];
	public var camFollowPos:Array<FlxObject> = [];

	private static var prevCamFollow:Array<FlxPoint> = [];
	private static var prevCamFollowPos:Array<FlxObject> = [];

	public var strumLineNotes:FlxTypedGroup<StrumLine>;
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;
	public var grpRatings:FlxTypedGroup<FlxSprite>;

	public var camZooming:Bool = false;
	public var camZoomingMult:Float = 1;
	public var camZoomingDecay:Float = 1;
	public var camBop:Bool = false;
	public var curSong:String = "";
	public var curSongDisplayName:String = "";

	public var health:Float = 1;
	public var shownHealth:Float = 1;
	public var combo:Array<Int> = [0, 0];

	private var healthBarBG:AttachedSprite;

	public var healthBar:FlxBar;

	private var songPercent:Float = 0;

	public var ratingsData:Array<Rating> = [];
	public var sicks:Array<Int> = [0, 0];
	public var goods:Array<Int> = [0, 0];
	public var bads:Array<Int> = [0, 0];
	public var shits:Array<Int> = [0, 0];

	private var generatedMusic:Bool = false;

	public var endingSong:Bool = false;
	public var startingSong:Bool = true;

	private var updateTime:Bool = true;

	// Gameplay settings
	public var playbackRate:Float = 1;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var camHUD:FlxCamera;
	public var camHUD2:FlxCamera;
	public var camNotes:FlxCamera;
	public var camGames:Array<FlxCamera> = [];
	public var camBorder:FlxCamera;
	public var camOther:FlxCamera;
	public var cameraSpeed:Float = 1;
	public var iconBopSpeed:Int = 1;

	public var songScore:Array<Float> = [0, 0];
	public var songMisses:Array<Int> = [0, 0];
	public var scoreTxt:Array<FlxText> = [];

	var timeTxt:FlxText;
	var scoreTxtTween:Array<FlxTween> = [null, null];

	public var ratingTxtGroup:Array<FlxTypedGroup<FlxText>> = [];
	public var ratingTxtTweens:Array<Array<FlxTween>> = [[], []];

	public var defaultCamZoom:Float = 1.05;
	public var defaultCamHudZoom:Float = 1;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;

	public var camMove:Bool = true;
	public var skipCountdown:Bool = false;
	public var songLength:Float = 0;

	public var boyfriendCameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;
	public var girlfriendCameraOffset:Array<Float> = null;

	#if DISCORD_ALLOWED
	// Discord RPC variables
	public var storyDifficultyText:String = "";
	public var detailsText:String = "";
	public var detailsPausedText:String = "";
	#end

	// Lua shit
	public static var instance:PlayState;

	// Less laggy controls
	private var keysArray:Array<Array<FlxKey>>;

	var bfGroupFile:CharacterGroupFile = null;
	var dadGroupFile:CharacterGroupFile = null;
	var gfGroupFile:CharacterGroupFile = null;

	public var strumMaps:Array<Map<Int, StrumLine>> = [];

	var startTimer:FlxTimer;
	var endingTimer:FlxTimer = null;

	public var countdownReady:FlxSprite;
	public var countdownSet:FlxSprite;
	public var countdownGo:FlxSprite;
	public var introSoundsSuffix = '';

	var precacheList:Map<String, String> = new Map<String, String>();

	public var paused:Bool = false;

	var startedCountdown:Bool = false;
	var canPause:Bool = true;

	public var totalPlayed:Array<Int> = [0, 0];
	public var totalNotesHit:Array<Float> = [0.0, 0.0];

	public var showRating:Bool = true;

	public var ratingName:Array<String> = ['?', '?'];
	public var ratingPercent:Array<Float> = [0, 0];
	public var ratingFC:Array<String> = ['', ''];
	public var transitioning = false;

	public static var boyfriendMatch:Bool = false;
	public static var dadMatch:Bool = false;
	public static var skipStage:Bool = false;

	var boyfriendScoreMult:Float = 1;
	var dadScoreMult:Float = 1;
	var dadCamX:Float = 0;
	var dadCamY:Float = 0;
	var boyfriendCamX:Float = 0;
	var boyfriendCamY:Float = 0;
	var gfCamX:Float = 0;
	var gfCamY:Float = 0;

	var winTxt:FlxText;
	var winBG:FlxSprite;

	private var shakeCam2:Array<Bool> = [false, false, false];
	var floatY:Float = 0;

	// var creditsMap:Map<String, String> = new Map();
	var songDetails:String = '';

	public static var playerWins:Array<Int> = [0, 0];

	var winGraphics:Array<FlxSprite> = [];

	public static var tiebreakerDiffs:Array<String> = CoolUtil.defaultDifficulties.copy();
	public static var doubleCamMode:Bool = false;

	var readyGroup:FlxTypedGroup<FlxSprite> = new FlxTypedGroup();

	public static var sliderVelocities:Array<VelocityChange>;
	public static var velocityMarkers:Array<Float> = [];
	var timersToStart:Array<FlxTimer> = [];

	var dadbattleBlack:BGSprite;
	var dadbattleLight:BGSprite;
	var dadbattleSmokes:FlxSpriteGroup;

	var blammedLightsBlack:FlxSprite;
	var phillyWindowEvent:BGSprite;
	var phillyGlowGradient:PhillyGlow.PhillyGlowGradient;
	var phillyGlowParticles:FlxTypedGroup<PhillyGlow.PhillyGlowParticle>;
	var curLightEvent:Int = -1;

	var pshaggyLegs:Map<Character, FlxSprite> = new Map();
	var pshaggyLegT:Map<Character, FlxTrail> = new Map();

	var guyFlipped:Array<Bool> = [true, true];
	var guyFlippedIdle:Array<Bool> = [false, true];

	var highShader:HighEffect;
	var tfb_haloRadiusX:Float = 0;
	var tfb_haloRadiusZ:Float = 0;
	var tfb_haloSpeed:Float = 0;
	var tfb_hudCamZoom:Float = 1;
	var tfb_noteCamZoom:Float = 1;
	var tfb_hudCamAngle:Float = 0;
	var tfb_noteCamAngle:Float = 0;
	var tfb_introBFNotes:Array<Null<Int>> = [
		144, 148, 152, 156, 160, 176, 180, 184, 188, 192, 208, 212, 216, 220, 224, 1200, 1204, 1208, 1212, 1216, 1232, 1236, 1240, 1244, 1248, 1264, 1268,
		1272, 1276, 1280, 1328, 1332, 1336, 1340, 1344, 1360, 1364, 1368, 1372, 1376, 1392, 1396, 1400, 1404, 1408];
	var tfb_introBFTween:FlxTween;
	var tfb_shit1 = 1;
	var tfb_spinBursts:Array<Array<Int>> = [
		[2018, 0, 0], [2029, 1, 0], [2034, 0, 0], [2050, 0, 0], [2061, 1, 0], [2064, 2, 0], [2066, 3, 0], [2082, 0, 0], [2093, 1, 0], [2098, 0, 0],
		[2114, 0, 0], [2125, 1, 0], [2128, 2, 0], [2130, 3, 0]];
	var tfb_offsets:Map<Int, Array<Float>> = [
		0 => [0, 0.5, 1, 2],
		1 => [0, 1, 1.5, 2],
		2 => [0, 0.5, 1],
		3 => [0, 0.5, 1]
	];
	var tfb_receptors:Map<Int, Array<Int>> = [
		0 => [3, 2, 1, 0],
		1 => [3, 2, 1, 0],
		2 => [3, 2, 1],
		3 => [2, 1, 0]
	];
	var tfb_alt:Int = 0;
	var tfb_confusionTweens:Array<Array<NumTween>> = [[null, null, null, null], [null, null, null, null]];
	var tfb_invertTween:NumTween;

	function get_boyfriend()
	{
		return boyfriendGroup.members[0];
	}

	function get_dad()
	{
		return dadGroup.members[0];
	}

	function get_gf()
	{
		return gfGroup.members[0];
	}

	function set_songSpeed(value:Float):Float
	{
		var ratio:Float = value / songSpeed; // funny word huh

		songSpeed = value;
		if (SONG != null)
			SONG.initialSpeed = songSpeed * .45;

		if (generatedMusic)
		{
			for (strumLine in strumLineNotes)
			{
				for (note in strumLine.allNotes) {
					note.resizeByRatio(ratio);
					note.initialPos = getPosFromTime(note.strumTime, note.multSpeed);
				}
			}
			for (note in unspawnNotes) {
				note.resizeByRatio(ratio);
				note.initialPos = getPosFromTime(note.strumTime, note.multSpeed);
			}
		}
		return value;
	}

	override public function create()
	{
		instance = this;
		
		if (SONG == null)
			SONG = Song.loadFromJson('test', 'test');

		if (skipStage)
			SONG.stage = 'stage';
		SONG.arrowSkin = SONG.splashSkin = '';
		SONG.skinModifier = 'base';

		/*var creditPaths = [Paths.getPreloadPath()];
			#if MODS_ALLOWED
			creditPaths.push(Paths.mods());
			#end
			for (path in creditPaths) {
				var creditsPath = path + 'data/pvpCredits.txt';
				var daCredits = CoolUtil.coolTextFile(creditsPath);
				for (credit in daCredits) {
					var splitCredit = credit.split('::');
					creditsMap.set(splitCredit[0], splitCredit[1]);
				}
		}*/

		curSong = Paths.formatToSongPath(SONG.song);
		curSongDisplayName = Song.getDisplayName(SONG.song);

		// songDetails = '$curSongDisplayName\n' + (creditsMap.exists(WeekData.getWeekFileName()) ? creditsMap.get(WeekData.getWeekFileName()) : creditsMap.get('default'));
		songDetails = '$curSongDisplayName\n' + WeekData.getCurrentWeek().weekName;

		var directories = [Paths.getPreloadPath()];
		#if MODS_ALLOWED
		directories.push(Paths.mods());
		#end
		var doubleCam = [];
		for (directory in directories)
		{
			var daFile = CoolUtil.coolTextFile(directory + 'data/pvpDoubleCam.txt');
			for (i in daFile)
				doubleCam.push(i);
		}
		if (doubleCam.contains(curSong))
			doubleCamMode = true;
		else
			doubleCamMode = false;

		var camPlayerBorder:FlxCamera = null;
		if (doubleCamMode)
		{
			for (i in 0...2)
				camGames[i] = new FlxCamera(Std.int((FlxG.width / 2) * i), 0, Std.int(FlxG.width / 2));
			camPlayerBorder = new FlxCamera(639, 0, 3, FlxG.height);
			camBorder = new FlxCamera(560 - 2, 0 - 2, 160 + 4, 160 + 4);
			camGames[2] = new FlxCamera(560, 0, 160, 160);
		}
		else
			camGames[0] = new FlxCamera();

		camNotes = new FlxCamera();
		camHUD = new FlxCamera();
		camHUD2 = new FlxCamera();
		camOther = new FlxCamera();
		camNotes.bgColor.alpha = 0;
		camHUD.bgColor.alpha = 0;
		camHUD2.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camGames[0]);
		if (doubleCamMode)
		{
			for (i in 1...camGames.length)
			{
				if (i == 2)
				{
					FlxG.cameras.add(camPlayerBorder, false);
					FlxG.cameras.add(camBorder, false);
				}
				FlxG.cameras.add(camGames[i], true);
			}
		}
		FlxG.cameras.add(camNotes, false);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camHUD2, false);
		FlxG.cameras.add(camOther, false);

		CustomFadeTransition.nextCamera = camOther;
		super.create();

		FlxG.timeScale = 1;

		PauseSubState.songName = null; // Reset to default

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		playbackRate = ClientPrefs.getGameplaySetting('songspeed', 1);
		Conductor.playbackRate = playbackRate;

		updateTime = (ClientPrefs.timeBarType != 'Disabled');

		persistentUpdate = true;

		// Ratings
		ratingsData.push(new Rating('sick')); // default rating

		var rating:Rating = new Rating('good');
		rating.displayName = 'Good!';
		rating.ratingMod = 0.7;
		rating.score = 200;
		rating.noteSplash = false;
		ratingsData.push(rating);

		var rating:Rating = new Rating('bad');
		rating.displayName = 'Bad';
		rating.ratingMod = 0.4;
		rating.score = 100;
		rating.noteSplash = false;
		ratingsData.push(rating);

		var rating:Rating = new Rating('shit');
		rating.displayName = 'Shit';
		rating.ratingMod = 0;
		rating.score = 50;
		rating.noteSplash = false;
		rating.causesMiss = ClientPrefs.shitMisses;
		ratingsData.push(rating);

		for (arr in 0...ratingTxtTweens.length)
		{
			for (i in ratingsData)
			{
				ratingTxtTweens[arr].push(null);
			}
		}

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);
		Conductor.changeSignature(SONG.timeSignature);

		if (storyDifficulty > CoolUtil.difficulties.length - 1)
		{
			storyDifficulty = CoolUtil.difficulties.indexOf('Normal');
			if (storyDifficulty == -1)
				storyDifficulty = 0;
		}

		#if DISCORD_ALLOWED
		storyDifficultyText = CoolUtil.difficulties[storyDifficulty];
		detailsText = "PvP";
		detailsPausedText = 'Paused - $detailsText';
		#end

		curStage = SONG.stage;
		if (curStage == null || curStage.length < 1)
		{
			curStage = StageData.getStageFromSong(curSong);
		}
		SONG.stage = curStage;

		var stageData:StageFile = StageData.getStageFile(curStage);
		if (stageData == null)
		{
			curStage = '!VOID!';
			stageData = StageData.getStageFile(curStage);
			SONG.gfVersion = 'gf';
		}

		defaultCamZoom = stageData.defaultZoom;
		isPixelStage = stageData.isPixelStage;
		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];

		if (stageData.camera_speed != null)
			cameraSpeed = stageData.camera_speed;

		// boyfriendCameraOffset = stageData.camera_boyfriend;
		if (boyfriendCameraOffset == null) // Fucks sake should have done it since the start :rolling_eyes:
			boyfriendCameraOffset = [0, 0];

		// opponentCameraOffset = stageData.camera_opponent;
		if (opponentCameraOffset == null)
			opponentCameraOffset = [0, 0];

		// girlfriendCameraOffset = stageData.camera_girlfriend;
		if (girlfriendCameraOffset == null)
			girlfriendCameraOffset = [0, 0];

		boyfriendGroup = new FlxTypedSpriteGroup(BF_X, BF_Y);
		if (doubleCamMode)
			boyfriendGroup.cameras = [camGames[0], camGames[1]];
		dadGroup = new FlxTypedSpriteGroup(DAD_X, DAD_Y);
		if (doubleCamMode)
			dadGroup.cameras = [camGames[0], camGames[1]];
		gfGroup = new FlxTypedSpriteGroup(GF_X, GF_Y);

		stage = new Stage(curStage, this);
		add(stage.background);

		if (isPixelStage)
			introSoundsSuffix = '-pixel';

		add(gfGroup);
		add(stage.overGF);
		add(dadGroup);
		add(stage.overDad);
		add(boyfriendGroup);
		add(stage.foreground);

		var gfVersion:String = SONG.gfVersion;
		if (gfVersion == null || gfVersion.length < 1 || !Paths.existsPath('characters/$gfVersion.json'))
		{
			gfVersion = Song.getGFVersion(curSong, curStage);
			SONG.gfVersion = gfVersion; // Fix for the Chart Editor
		}

		if (stageData.hide_girlfriend == false)
		{
			gfGroupFile = Character.getFile(gfVersion);
			if (gfGroupFile != null && gfGroupFile.characters != null && gfGroupFile.characters.length > 0)
			{
				for (i in 0...gfGroupFile.characters.length)
				{
					addCharacter(gfGroupFile.characters[i].name, i, false, gfGroup, gfGroupFile.characters[i].position[0] + gfGroupFile.position[0],
						gfGroupFile.characters[i].position[1] + gfGroupFile.position[1], 0.95, 0.95);
					checkPicoSpeaker(gfGroup.members[i]);
				}
			}
			else
			{
				gfGroupFile = null;
				addCharacter(gfVersion, 0, false, gfGroup, 0, 0, 0.95, 0.95);
				checkPicoSpeaker(gfGroup.members[0]);
			}
		}

		dadGroupFile = Character.getFile(SONG.player2);
		if (dadGroupFile != null && dadGroupFile.characters != null && dadGroupFile.characters.length > 0)
		{
			for (i in 0...dadGroupFile.characters.length)
			{
				addCharacter(dadGroupFile.characters[i].name, i, false, dadGroup, dadGroupFile.characters[i].position[0] + dadGroupFile.position[0],
					dadGroupFile.characters[i].position[1] + dadGroupFile.position[1]);
			}
		}
		else
		{
			dadGroupFile = null;
			addCharacter(SONG.player2, 0, false, dadGroup);
			addCharacterToList(dad.curCharacter, 1);
		}

		bfGroupFile = Character.getFile(SONG.player1);
		if (bfGroupFile != null && bfGroupFile.characters != null && bfGroupFile.characters.length > 0)
		{
			for (i in 0...bfGroupFile.characters.length)
			{
				addCharacter(bfGroupFile.characters[i].name, i, true, boyfriendGroup, bfGroupFile.characters[i].position[0] + bfGroupFile.position[0],
					bfGroupFile.characters[i].position[1] + bfGroupFile.position[1]);
			}
		}
		else
		{
			bfGroupFile = null;
			addCharacter(SONG.player1, 0, true, boyfriendGroup);
			addCharacterToList(boyfriend.curCharacter, 0);
		}

		var camPos:FlxPoint = new FlxPoint(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if (gf != null)
		{
			camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
			camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
		}

		stage.onCharacterInit();

		Conductor.songPosition = -5000;

		strumLine = new FlxSprite(0, 50).makeGraphic(FlxG.width, 10);
		if (ClientPrefs.downScroll)
			strumLine.y = FlxG.height - 162;
		strumLine.scrollFactor.set();

		healthBarBG = new AttachedSprite(getUIFile('healthBar'));
		healthBarBG.y = FlxG.height * 0.89;
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		healthBarBG.visible = !ClientPrefs.hideHud;
		healthBarBG.xAdd = -4;
		healthBarBG.yAdd = -4;
		healthBarBG.cameras = [camHUD];
		add(healthBarBG);
		if (ClientPrefs.downScroll)
			healthBarBG.y = 0.11 * FlxG.height;

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'shownHealth', 0, 2);
		healthBar.scrollFactor.set();
		healthBar.visible = !ClientPrefs.hideHud;
		healthBar.alpha = ClientPrefs.healthBarAlpha;
		healthBar.numDivisions = Std.int(healthBarBG.width - 8);
		healthBar.cameras = [camHUD];
		add(healthBar);
		healthBarBG.sprTracker = healthBar;

		if (bfGroupFile != null)
		{
			iconP1 = new HealthIcon(bfGroupFile.healthicon, true);
		}
		else
		{
			iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		}
		iconP1.y = healthBar.y - 75;
		iconP1.visible = !ClientPrefs.hideHud;
		iconP1.alpha = ClientPrefs.healthBarAlpha;
		iconP1.cameras = [camHUD];
		add(iconP1);

		if (dadGroupFile != null)
		{
			iconP2 = new HealthIcon(dadGroupFile.healthicon);
		}
		else
		{
			iconP2 = new HealthIcon(dad.healthIcon);
		}
		iconP2.y = healthBar.y - 75;
		iconP2.visible = !ClientPrefs.hideHud;
		iconP2.alpha = ClientPrefs.healthBarAlpha;
		iconP2.cameras = [camHUD];
		add(iconP2);

		reloadHealthBarColors();

		grpRatings = new FlxTypedGroup();
		add(grpRatings);
		var dummyRating = new FlxSprite();
		dummyRating.kill();
		grpRatings.add(dummyRating);
		strumLineNotes = new FlxTypedGroup();
		strumLineNotes.cameras = [camNotes];
		add(strumLineNotes);
		grpNoteSplashes = new FlxTypedGroup();
		grpNoteSplashes.cameras = [camNotes];
		add(grpNoteSplashes);

		var splash:NoteSplash = new NoteSplash(100, 100, null);
		grpNoteSplashes.add(splash);
		splash.alphaMult = 0.00001;

		generateStaticArrows(0, 4, false);
		generateStaticArrows(1, 4, true);
		strumLineNotes.add(strumMaps[0].get(4));
		strumLineNotes.add(strumMaps[1].get(4));
		setKeysArray();

		// SONG.speed = CoolUtil.boundTo(CoolUtil.scrollSpeedFromBPM(SONG.bpm, SONG.timeSignature[1]), 0.1, 3.5);
		songSpeed = SONG.speed;

		sliderVelocities = [];
		velocityMarkers = [];
		sliderVelocities.push({
			startTime: -5000,
			multiplier: 1
		});
		if (SONG.sliderVelocities != null) {
			for (shit in SONG.sliderVelocities)
				sliderVelocities.push(shit);
			sliderVelocities.sort((a, b) -> Std.int(a.startTime - b.startTime));
		}
		mapVelocityChanges();

		generateSong();

		timeTxt = new FlxText(0, 2, 1270, songDetails, 16);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0.00001;
		timeTxt.borderSize = 1;
		if (ClientPrefs.downScroll)
			timeTxt.y = FlxG.height - 66;
		timeTxt.screenCenter(X);
		timeTxt.cameras = [camHUD];
		add(timeTxt);
		updateTimeTxt();

		for (i in 0...camGames.length)
		{
			var daCamFollow = new FlxPoint();
			var daCamFollowPos = new FlxObject(0, 0, 1, 1);
			camFollow.push(daCamFollow);
			camFollowPos.push(daCamFollowPos);

			snapCamFollowToPos(i, camPos.x, camPos.y);
			if (prevCamFollow[i] != null)
			{
				daCamFollow.set(prevCamFollow[i].x, prevCamFollow[i].y);
				prevCamFollow[i] = null;
			}
			if (prevCamFollowPos[i] != null)
			{
				daCamFollowPos.setPosition(prevCamFollowPos[i].x, prevCamFollowPos[i].y);
				prevCamFollowPos[i] = null;
			}
			add(daCamFollowPos);

			camGames[i].follow(daCamFollowPos, LOCKON, 1);
			camGames[i].zoom = defaultCamZoom;
			if (i == 2)
				camGames[i].zoom = Math.min(defaultCamZoom, 0.5);
			camGames[i].focusOn(daCamFollow);
		}
		camNotes.zoom = camHUD.zoom = defaultCamHudZoom;

		updateCameras();

		for (player in 0...2)
		{
			var winGraphic = new FlxSprite(20, 410).loadGraphic(Paths.image('pvp/wins$player'), true, 73, 34);
			if (player == 1)
				winGraphic.x = FlxG.width - winGraphic.width - 20;
			for (i in 0...3)
				winGraphic.animation.add('$i', [i], 0, false);
			winGraphic.animation.play('${playerWins[player]}');
			winGraphic.cameras = [camHUD];
			winGraphic.scrollFactor.set();
			winGraphic.antialiasing = ClientPrefs.globalAntialiasing;
			winGraphics.push(winGraphic);
			add(winGraphic);

			var playerScoreTxt = new FlxText(FlxG.width / 2 * player, FlxG.height * 0.89 + 36, 640, "", 20);
			if (ClientPrefs.downScroll)
				playerScoreTxt.y = 0.11 * FlxG.height + 36;
			playerScoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			playerScoreTxt.scrollFactor.set();
			playerScoreTxt.borderSize = 1.25;
			playerScoreTxt.cameras = [camHUD];
			scoreTxt.push(playerScoreTxt);
			add(playerScoreTxt);

			var playerRatingTxtGroup = new FlxTypedGroup<FlxText>();
			playerRatingTxtGroup.visible = !ClientPrefs.hideHud && ClientPrefs.showRatings;
			for (i in 0...5)
			{
				var ratingTxt = new FlxText(20, FlxG.height * 0.5 - 8 + (16 * (i - 2)), FlxG.width, "", 16);
				if (player == 1)
				{
					ratingTxt.x = -20;
					ratingTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				}
				else
					ratingTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				ratingTxt.scrollFactor.set();
				playerRatingTxtGroup.add(ratingTxt);
			}
			playerRatingTxtGroup.cameras = [camHUD];
			ratingTxtGroup.push(playerRatingTxtGroup);
			add(playerRatingTxtGroup);
		}

		switch (curSong)
		{
			case 'sunshine':
				var vcr = new Shaders.VCRDistortionShader();
				var daStatic:FlxSprite = new FlxSprite(0, 0);
				daStatic.frames = Paths.getSparrowAtlas('sonicexe/daSTAT');
				daStatic.setGraphicSize(FlxG.width, FlxG.height);
				daStatic.alpha = 0.05;
				daStatic.screenCenter();
				daStatic.cameras = [camHUD];
				daStatic.animation.addByPrefix('static', 'staticFLASH', 24, true);
				daStatic.animation.play('static');
				add(daStatic);
				for (camera in camGames)
					camera.setFilters([new ShaderFilter(vcr)]);
				camHUD.setFilters([new ShaderFilter(vcr)]);
				camNotes.setFilters([new ShaderFilter(vcr)]);

			case 'high-shovel':
				highShader = new HighEffect();
				for (camera in camGames)
					camera.setFilters([new ShaderFilter(highShader.shader)]);
				camNotes.setFilters([new ShaderFilter(highShader.shader)]);
				flashR = flashG = flashB = 128;
				justHowHighAreYou = 0.25;

			case 'taste-for-blood':
				suddenOffset = 0.55;
				hiddenOffset = -0.25;

				for (i in 0...tfb_spinBursts.length) {
					var burst = tfb_spinBursts[i];
					var step = burst[0] - 2016;
					var type = burst[1];
					tfb_spinBursts.push([2144 + step, type, 1]);
					tfb_spinBursts.push([656 + step, type, 0]);
					tfb_spinBursts.push([784 + step, type, 1]);
				}
				tfb_spinBursts.sort((a, b) -> Std.int(a[0] - b[0]));

			case 'tsuraran-fox':
				highShader = new HighEffect();
				for (camera in camGames)
					camera.setFilters([new ShaderFilter(highShader.shader)]);
				camNotes.setFilters([new ShaderFilter(highShader.shader)]);
		}

		winTxt = new FlxText(0, 0, 1270, "", 64);
		winTxt.setFormat(Paths.font("vcr.ttf"), 64, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		winTxt.borderSize = 2;
		winTxt.scrollFactor.set();
		winTxt.visible = false;
		winTxt.cameras = [camOther];

		winBG = new FlxSprite().makeGraphic(FlxG.width, Std.int(winTxt.height), FlxColor.BLACK);
		winBG.screenCenter();
		winBG.alpha = 0.5;
		winBG.scrollFactor.set();
		winBG.visible = false;
		winBG.cameras = [camOther];

		add(winBG);
		add(winTxt);

		for (i in 0...2)
		{
			var readySprite = new FlxSprite().loadGraphic(Paths.image('uiskins/default/base/ready'));
			readySprite.scale.set(0.5, 0.5);
			readySprite.updateHitbox();
			readySprite.x = ((FlxG.width / 2) - readySprite.width) / 2;
			if (i > 0)
				readySprite.x += (FlxG.width / 2);
			readySprite.screenCenter(Y);
			readySprite.scrollFactor.set();
			readySprite.cameras = [camHUD];
			readyGroup.add(readySprite);
		}

		add(readyGroup);

		for (i in 0...2)
			recalculateRating(false, i);

		precacheList.set('missnote1', 'sound');
		precacheList.set('missnote2', 'sound');
		precacheList.set('missnote3', 'sound');

		if (PauseSubState.songName != null)
			precacheList.set(PauseSubState.songName, 'music');
		else if (ClientPrefs.pauseMusic != 'None')
			precacheList.set(Paths.formatToSongPath(ClientPrefs.pauseMusic), 'music');

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, '$curSongDisplayName ($storyDifficultyText)', iconP2.char);
		#end

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

		Conductor.safeZoneOffset = (ClientPrefs.safeFrames / 60) * 1000 * playbackRate;

		windowNameSuffix = ' | ${WeekData.getCurrentWeek().weekName} | $curSongDisplayName [${CoolUtil.difficultyString()}]';

		cacheCountdown();
		cachePopUpScore();

		for (key => type in precacheList)
		{
			switch (type)
			{
				case 'image':
					Paths.image(key);
				case 'sound':
					Paths.sound(key);
				case 'music':
					Paths.music(key);
			}
		}
		Paths.clearUnusedMemory();

		CustomFadeTransition.nextCamera = camOther;
	}

	var sh_r:Float = 300;
	var rotInd:Float = 0;

	override public function update(elapsed:Float)
	{
		tweenManager.update(elapsed);
		timerManager.update(elapsed);
		updatePositions(); //doing this before super.update so curStep and curBeat can be updated immediately
		super.update(elapsed);

		if (!startedCountdown && (readyGroup.members[0].visible || readyGroup.members[1].visible))
		{
			var count = 0;
			for (i in 0...2)
			{
				if (readyGroup.members[i].visible && (MultiControls.positionCheck(ACCEPT, i) || strumLineNotes.members[i].botPlay))
				{
					readyGroup.members[i].visible = false;
					CoolUtil.playScrollSound();
				}
				if (!readyGroup.members[i].visible)
					count++;
			}
			if (count == readyGroup.length)
			{
				CoolUtil.playConfirmSound();
				new FlxTimer(timerManager).start(0.5, function(_)
				{
					startCountdown();
					readyGroup.kill();
					remove(readyGroup);
					readyGroup.destroy();
				});
			}
		}

		var pause = MultiControls.anyCheck(PAUSE);

		if (FlxG.sound.music != null && FlxG.sound.music.playing)
			setSongPitch();

		if (playbackRate != 1
			&& startedCountdown
			&& !endingSong
			&& !transitioning
			&& FlxG.sound.music != null
			&& FlxG.sound.music.length - Conductor.songPosition <= 20)
		{
			Conductor.songPosition = FlxG.sound.music.length;
			finishSong(false);
		}

		stage.onUpdate(elapsed);

		if (phillyGlowParticles != null)
		{
			var i:Int = phillyGlowParticles.members.length - 1;
			while (i > 0)
			{
				var particle = phillyGlowParticles.members[i];
				if (particle.alpha < 0)
				{
					particle.kill();
					phillyGlowParticles.remove(particle, true);
					particle.destroy();
				}
				--i;
			}
		}

		for (i in 0...shakeCam2.length)
		{
			if (shakeCam2[i])
				camGames[i].shake(0.0025, 0.10);
		}

		if (camMove)
		{
			var lerpVal:Float = CoolUtil.boundTo(elapsed * 2.4 * cameraSpeed, 0, 1);
			for (i in 0...camGames.length)
				camFollowPos[i].setPosition(FlxMath.lerp(camFollowPos[i].x, camFollow[i].x, lerpVal),
					FlxMath.lerp(camFollowPos[i].y, camFollow[i].y, lerpVal));
		}

		floatY += elapsed * 1.8;
		rotInd += elapsed * 60;

		var grps = [dadGroup, boyfriendGroup];
		var icons = [iconP2, iconP1];
		for (i in 0...grps.length)
		{
			var grp = grps[i];
			var mult = (i > 0 ? -1 : 1);
			for (char in grp)
			{
				switch (char.curCharacter)
				{
					case 'TDoll' | 'TDollAlt':
						char.addX += Math.cos(floatY) * 1.3 * mult;
						char.addY += Math.sin(floatY) * 1.3;
					case 'fleetway' | 'Sarah':
						char.addY += Math.sin(floatY) * 1.3;
					case 'pshaggy':
						var rotRateSh = (curStep / 9.5) * 1.2;
						var sh_tox = char.defaultX - (Math.cos(rotRateSh) * sh_r) * mult;
						var sh_toy = char.defaultY - Math.sin(rotRateSh * 2) * sh_r * 0.45;
						char.addX += (sh_tox - char.x) / 12;
						char.addY += (sh_toy - char.y) / 12;
						if (char.state == Default)
						{
							var pene = 0.07;
							char.angle = Math.sin(rotRateSh) * sh_r * pene / 4;

							pshaggyLegs.get(char).alpha = 1;
							pshaggyLegs.get(char).angle = Math.sin(rotRateSh) * sh_r * pene;

							pshaggyLegs.get(char).x = char.x + 120 + Math.cos((pshaggyLegs.get(char).angle + 90) * (Math.PI / 180)) * 150;
							pshaggyLegs.get(char).y = char.y + 300 + Math.sin((pshaggyLegs.get(char).angle + 90) * (Math.PI / 180)) * 150;
						}
						else
						{
							char.angle = 0;
							pshaggyLegs.get(char).alpha = 0;
						}
						pshaggyLegT.get(char).visible = (pshaggyLegs.get(char).alpha > 0);
					case 'wbshaggy':
						var rot = rotInd / 6;
						char.addX = (Math.cos(rot / 3) * 20) * mult;
						char.addY = Math.cos(rot / 5) * 40;
					case 'guy':
						if ((i == 0 && healthBar.percent > 80) || (i == 1 && healthBar.percent < 20))
							icons[i].angle = FlxG.random.int(-5, 5);
						else
							icons[i].angle = 0;
				}
				char.x = char.defaultX + char.addX;
				char.y = char.defaultY + char.addY;
			}
		}

		if (startedCountdown && SONG.notes[curSection] != null && !endingSong && !isCameraOnForcedPos)
			updateCameras();

		if (pause && startedCountdown && canPause)
			openPauseMenu();

		if (ClientPrefs.smoothHealth)
			shownHealth = FlxMath.lerp(shownHealth, health, CoolUtil.boundTo(elapsed * 7, 0, 1));
		else
			shownHealth = health;

		var mult:Float = FlxMath.lerp(1, iconP1.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
		iconP1.scale.set(mult, mult);
		iconP1.updateHitbox();

		var mult:Float = FlxMath.lerp(1, iconP2.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
		iconP2.scale.set(mult, mult);
		iconP2.updateHitbox();

		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 1, 0))) + ((150 * iconP1.scale.x - 150) / 2);
		iconP2.x = healthBar.x
			+ (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 1, 0)))
			- 150
			- ((150 * iconP2.scale.x - 150) / 2);

		if (health > 2)
			health = 2;
		else if (health < 0)
			health = 0;

		if (healthBar.percent < 20)
		{
			iconP1.playAnim('losing');
			iconP2.playAnim('winning');
		}
		else if (healthBar.percent > 80)
		{
			iconP1.playAnim('winning');
			iconP2.playAnim('losing');
		}
		else
		{
			iconP1.playAnim('normal');
			iconP2.playAnim('normal');
		}

		updateTimeTxt();

		if (camZooming)
		{
			var lerp = CoolUtil.boundTo(1 - (elapsed * 3.125 * camZoomingDecay), 0, 1);
			for (i in 0...camGames.length)
			{
				if (i == 2)
					camGames[i].zoom = FlxMath.lerp(Math.min(defaultCamZoom, 0.5), camGames[i].zoom,
						lerp);
				else
					camGames[i].zoom = FlxMath.lerp(defaultCamZoom, camGames[i].zoom, lerp);
			}
			camHUD.zoom = FlxMath.lerp(defaultCamHudZoom, camHUD.zoom, lerp);
		}

		FlxG.watch.addQuick("secShit", curSection);
		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		camNotes.zoom = camHUD.zoom;

		switch (curSong)
		{
			case 'high-shovel':
				var time = Conductor.songPosition / 1000;
				for (i in 0...2)
				{
					for (j in 0...4)
					{
						transformXNotes[i][j] = (drunkC * (Math.cos(time + j * 0.2) * Note.swagWidth * 0.4));
						transformYNotes[i][j] = (tipsyC * (Math.cos(time * 1.2 + j * 1.8) * Note.swagWidth * 0.5));
					}
				}

			case 'taste-for-blood':
				camNotes.angle = tfb_noteCamAngle;
				camHUD.angle = tfb_hudCamAngle;
				
				camNotes.zoom = tfb_noteCamZoom;
				camHUD.zoom = tfb_hudCamZoom;

				if (curStep >= 912 && curStep <= 1168)
				{
					for (i in 0...2)
					{
						for (j in 0...4)
						{
							transformXNotes[i][j] = 32 * Math.sin((curDecBeat + j * 0.25) * 0.25 * Math.PI);
							transformYNotes[i][j] = 32 * Math.cos((curDecBeat + j * 0.25) * 0.25 * Math.PI);
						}
					}
				}
				else if (curStep >= 2272 && curStep <= 2364)
				{
					for (j in 0...4)
					{
						var input = (j + 1 + curDecBeat) * FlxAngle.asRadians(360 / 4);
						transformXNotes[0][j] = tfb_haloRadiusX * Math.sin(input) * tfb_haloSpeed;
						transformZNotes[0][j] = tfb_haloRadiusZ * Math.cos(input) * tfb_haloSpeed;
					}
				}
		}

		if (highShader != null)
			highShader.setHigh(justHowHighAreYou);

		for (i in 0...2) {
			var strumLine = strumLineNotes.members[i];
			for (j in 0...4) {
				updateReceptorAngle(strumLine.getReceptor(j), i);
				updateReceptorAlpha(strumLine.getReceptor(j), i);
				updateReceptorPath(strumLine.getReceptor(j), i);
				updateReceptorScale(strumLine.getReceptor(j), i);
			}
		}

		while (unspawnNotes[0] != null)
		{
			var time:Float = spawnTime;
			if (songSpeed < 1)
				time /= songSpeed;
			if (unspawnNotes[0].multSpeed < 1)
				time /= unspawnNotes[0].multSpeed;
			if (camNotes.zoom < 1)
				time /= camNotes.zoom;

			if (unspawnNotes[0].initialPos - Conductor.currentTrackPos < time)
			{
				var dunceNote:Note = unspawnNotes[0];

				// Change the selected strumline here!
				var strumID = (dunceNote.isOpponent ? 0 : 1);

				strumLineNotes.members[strumID].push(dunceNote);
				dunceNote.spawned = true;

				unspawnNotes.shift();
			} else {
				break;
			}
		}

		if (!endingSong)
			noteFunctions();

		for (i in 0...strumLineNotes.length)
			strumLineNotes.members[i].receptorsGroup.sort(sortByZ);

		for (arr in 0...ratingTxtGroup.length)
		{
			for (i in 0...ratingTxtGroup[arr].members.length)
			{
				var rating = ratingTxtGroup[arr].members[i];
				if (i < ratingsData.length)
					rating.text = '${ratingsData[i].displayName}: ${Reflect.field(this, ratingsData[i].counter)[arr]}';
				else
					rating.text = 'Fails: ${songMisses[arr]}';
			}
		}

		if (!endingSong && !startingSong)
		{
			if (FlxG.keys.justPressed.TWO)
			{
				killNotes();
				FlxG.sound.music.onComplete();
			}
			if (FlxG.keys.justPressed.THREE)
			{ // Go 10 seconds into the future :O
				setSongTime(Conductor.songPosition + 10000 * playbackRate);
				clearNotesBefore(Conductor.songPosition);
			}
		}
		if (FlxG.keys.justPressed.FOUR)
			strumLineNotes.members[0].botPlay = !strumLineNotes.members[0].botPlay;
		if (FlxG.keys.justPressed.FIVE)
			strumLineNotes.members[1].botPlay = !strumLineNotes.members[1].botPlay;

		if (highShader != null)
		{
			highShader.update(elapsed);
		}
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused && !persistentUpdate)
		{
			FlxG.timeScale = 1;

			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
				vocalsDad.pause();
			}

			tweenManager.forEach(function(twn)
			{
				if (!twn.finished)
					twn.active = false;
			});
			timerManager.forEach(function(tmr)
			{
				if (!tmr.finished)
					tmr.active = false;
			});
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (!persistentUpdate)
			{
				FlxG.timeScale = playbackRate;

				if (FlxG.sound.music != null && !startingSong)
					resyncVocals();

				tweenManager.forEach(function(twn)
				{
					if (!twn.finished)
						twn.active = true;
				});
				timerManager.forEach(function(tmr)
				{
					if (!tmr.finished)
						tmr.active = true;
				});

				#if DISCORD_ALLOWED
				if (startTimer != null && startTimer.finished)
					DiscordClient.changePresence(detailsText, '$curSongDisplayName ($storyDifficultyText)', iconP2.char, true,
						(songLength - Conductor.songPosition) / playbackRate - ClientPrefs.noteOffset);
				else
					DiscordClient.changePresence(detailsText, '$curSongDisplayName ($storyDifficultyText)', iconP2.char);
				#end

				persistentUpdate = true;
			}

			paused = false;
		}

		super.closeSubState();
	}

	override public function onFocus():Void
	{
		if (!paused)
		{
			if (FlxG.sound.music != null && !startingSong && !endingSong)
				resyncVocals();

			#if DISCORD_ALLOWED
			if (Conductor.songPosition > 0.0)
				DiscordClient.changePresence(detailsText, '$curSongDisplayName ($storyDifficultyText)', iconP2.char, true,
					(songLength - Conductor.songPosition) / playbackRate - ClientPrefs.noteOffset);
			else
				DiscordClient.changePresence(detailsText, '$curSongDisplayName ($storyDifficultyText)', iconP2.char);
			#end
		}

		super.onFocus();
	}

	override public function onFocusLost():Void
	{
		if (ClientPrefs.focusLostPause && !paused && startedCountdown && canPause)
		{
			openPauseMenu();
			FlxG.sound.music.pause();
			vocals.pause();
			vocalsDad.pause();
		}
		else if (ClientPrefs.autoPause)
		{
			#if DISCORD_ALLOWED
			DiscordClient.changePresence(detailsPausedText, '$curSongDisplayName ($storyDifficultyText)', iconP2.char);
			#end
		}

		super.onFocusLost();
	}

	var lastStepHit:Int = -1;
	var zoomed:Bool = false;
	var shotTimes:Array<Float> = [
		16000,
		85000,
		90000,
		90333.3333333333,
		146000,
		146333.333333333,
		148000,
		148333.333333333,
		148666.666666667, 149000, 151333.333333333,
		151666.666666667, 152666.666666667, 153000, 153333.333333333, 153583.333333333, 153833.333333333, 154000, 154333.333333333];
	var drunkC:Float = 0;
	var tipsyC:Float = 0;
	var justHowHighAreYou:Float = 0;

	override function stepHit()
	{
		super.stepHit();
		if (generatedMusic
			&& (Math.abs(FlxG.sound.music.time - Conductor.songPosition) > 20 * playbackRate)
			|| (vocals.length > 0 && Math.abs(vocals.time - Conductor.songPosition) > 20 * playbackRate)
			|| (vocalsDad.length > 0 && Math.abs(vocalsDad.time - Conductor.songPosition) > 20 * playbackRate))
			resyncVocals();

		if (curStep == lastStepHit)
			return;

		var grps = [dadGroup, boyfriendGroup];
		var icons = [iconP2, iconP1];
		for (i in 0...grps.length)
		{
			var grp = grps[i];
			var mult = (i > 0 ? -1 : 1);
			for (char in grp)
			{
				switch (char.curCharacter)
				{
					case 'guy':
						if (curStep % 2 == 0 && (i == 0 && healthBar.percent > 80) || (i == 1 && healthBar.percent < 20))
						{
							guyFlipped[i] = !guyFlipped[i];
							icons[i].flipX = guyFlipped[i];
						}
				}
			}
		}

		if (ClientPrefs.gameQuality != 'Crappy' && curStep >= 0)
			stage.onStepHit();

		switch (curSong)
		{
			case 'no-villains', 'no-bitches-(matasaki)', 'no-bitches-(penkaru)':
				if (curStep >= 1664 && curStep < 1920 && !zoomed)
				{
					zoomed = true;
					tweenManager.tween(this, {defaultCamZoom: 1.6}, 1.5, {ease: FlxEase.quadInOut});
				}
				else if (curStep >= 1920 && zoomed)
				{
					zoomed = false;
					tweenManager.tween(this, {defaultCamZoom: 1}, 1.5, {ease: FlxEase.quadInOut});
				}

			case 'die-batsards':
				if (curStep >= 1719 && curStep < 1984 && !zoomed)
				{
					zoomed = true;
					tweenManager.tween(this, {defaultCamZoom: 1.6}, 1.5, {ease: FlxEase.quadInOut});
				}
				else if (curStep >= 1984 && zoomed)
				{
					zoomed = false;
					tweenManager.tween(this, {defaultCamZoom: 0.765}, 1.5, {ease: FlxEase.quadInOut});
				}
				for (i in 0...shotTimes.length) {
					if (Conductor.songPosition >= shotTimes[i]) {
						for (camGame in camGames) {
							camGame.zoom *= 1.1;
							camGame.shake(0.025,0.05);
						}
						shotTimes.remove(shotTimes[i]);
					}
				}

			case 'high-shovel':
				if (curStep == 1152) {
					stage.smonk1.x -= 600;
					stage.smonk2.x += 600;
					stage.smonk3.x -= 300;
					stage.smonk4.x += 300;
					tweenManager.tween(stage.smokeOverlay, {alpha: 0.35}, (Conductor.stepCrochet * 64) / 1000, {ease: FlxEase.quartInOut});
					tweenManager.tween(stage.smonk1, {x: stage.smonk1.x + 600, alpha: 1}, (Conductor.stepCrochet * 48) / 1000, {ease: FlxEase.quadInOut});
					tweenManager.tween(stage.smonk2, {x: stage.smonk2.x - 600, alpha: 1}, (Conductor.stepCrochet * 48) / 1000, {ease: FlxEase.quadInOut});
					tweenManager.tween(stage.smonk3, {x: stage.smonk3.x + 300, alpha: 0.5}, (Conductor.stepCrochet * 64) / 1000, {ease: FlxEase.quadInOut});
					tweenManager.tween(stage.smonk4, {x: stage.smonk4.x - 300, alpha: 0.5}, (Conductor.stepCrochet * 64) / 1000, {ease: FlxEase.quadInOut});
					tweenManager.tween(this, {sudden: 1, suddenOffset: 0.25, justHowHighAreYou: 1}, (Conductor.stepCrochet * 68) / 1000, {ease: FlxEase.quadOut});
					tweenManager.tween(this, {tipsyC: 0.25, drunkC: 0.25}, (Conductor.stepCrochet * 4) / 1000, {ease: FlxEase.quadOut});
				}

			case 'taste-for-blood':
				for (i in 0...tfb_introBFNotes.length) {
					if (tfb_introBFNotes[i] != null)
					{
						if (curStep >= tfb_introBFNotes[i]) {
							var shit = i % 2 == 0 ? -1 : 1;
							transformX = 25 * shit;
							tfb_hudCamZoom = 1.1;
							tfb_noteCamZoom = 1.1;
							tfb_noteCamAngle = 5 * shit;

							if (tfb_introBFTween != null)
								tfb_introBFTween.cancel();
							tfb_introBFTween = tweenManager.tween(this, {
								transformX: 0,
								tfb_noteCamAngle: 0,
								tfb_hudCamZoom: 1,
								tfb_noteCamZoom: 1
							}, (Conductor.stepCrochet * 4) / 1000, {ease: FlxEase.quartOut, onComplete: function(_) {
									tfb_introBFTween = null;
							}});

							tfb_introBFNotes[i] = null;
						} else
							break;
					}
				}
				for (i in 0...tfb_spinBursts.length)
				{
					var burst = tfb_spinBursts[i];
					if (burst != null) {
						var step = burst[0];
						if (curStep >= step) {
							var type = burst[1];
							var pn = burst[2];
							var affectedOffsets = tfb_offsets[type];
							var affectedReceptors = tfb_receptors[type];
							if (step >= 2016)
							{
								var cameras = [camHUD, camHUD2, camNotes];
								for (camGame in camGames)
									cameras.push(camGame);

								for (camera in cameras)
									camera.shake(0.025, 0.1);
							}
							for (i in 0...affectedOffsets.length)
							{
								if (affectedOffsets[i] > 0) {
									new FlxTimer(timerManager).start((Conductor.stepCrochet * affectedOffsets[i]) / 1000, function(_) {
										spinBurst(pn, affectedReceptors[i]);
									});
								}
								else
									spinBurst(pn, affectedReceptors[i]);
							}
							tfb_spinBursts.remove(burst);
						} else
							break;
					}
				}
				if (curStep >= 656 && curStep <= 912 && curStep % 8 == 0) {
					tfb_shit1 *= -1;
					drunk = -0.5;
					tipsy = 0.5;
					flip[0] = flip[1] = 0.15 * tfb_shit1;
					tipsySpeed = Math.cos(curStep) * 0.5;
					drunkSpeed = Math.cos(curStep) * 0.35;
					confusion[0] = confusion[1] = 15 * tfb_shit1;
					tweenManager.tween(this, {drunk: 0, tipsy: 0}, (Conductor.stepCrochet * 4) / 1000, {ease: FlxEase.quartInOut});
					tweenArrayNum(flip, 0, 0, (Conductor.stepCrochet * 4) / 1000, {ease: FlxEase.quartInOut});
					tweenArrayNum(flip, 1, 0, (Conductor.stepCrochet * 4) / 1000, {ease: FlxEase.quartInOut});
					tweenArrayNum(confusion, 0, 0, (Conductor.stepCrochet * 2) / 1000, {ease: FlxEase.quartInOut});
					tweenArrayNum(confusion, 1, 0, (Conductor.stepCrochet * 2) / 1000, {ease: FlxEase.quartInOut});
				} else if (curStep >= 1970 && curStep <= 1980 && curStep % 2 == 0) {
					tfb_alt += 1;
					for (i in 0...2) {
						tweenArrayNumInArray(confusionNotes, i, 0, (tfb_alt % 2) * -90, (Conductor.stepCrochet * 2) / 1000, {ease: FlxEase.quartOut});
						tweenArrayNumInArray(confusionNotes, i, 1, (tfb_alt % 2) * 90, (Conductor.stepCrochet * 2) / 1000, {ease: FlxEase.quartOut});
						tweenArrayNumInArray(confusionNotes, i, 2, (tfb_alt % 2) * -90, (Conductor.stepCrochet * 2) / 1000, {ease: FlxEase.quartOut});
						tweenArrayNumInArray(confusionNotes, i, 3, (tfb_alt % 2) * 90, (Conductor.stepCrochet * 2) / 1000, {ease: FlxEase.quartOut});
						tweenArrayNum(invert, i, (tfb_alt % 2), (Conductor.stepCrochet * 2) / 1000, {ease: FlxEase.quartOut});
					}
				}
				switch (curStep)
				{
					case 144, 1200:
						introPart(curStep);
					case 356:
						confusion[0] = 360;
						confusion[1] = -360;
						tweenArrayNum(confusion, 0, 0, (Conductor.stepCrochet * 6) / 1000, {ease: FlxEase.quadOut});
						tweenArrayNum(confusion, 1, 0, (Conductor.stepCrochet * 6) / 1000, {ease: FlxEase.quadOut});
						tweenArrayNum(opponentSwap, 0, 0, (Conductor.stepCrochet * 6) / 1000, {ease: FlxEase.quadOut});
						tweenArrayNum(opponentSwap, 1, 0, (Conductor.stepCrochet * 6) / 1000, {ease: FlxEase.quadOut});
					case 528:
						tweenArrayNum(opponentSwap, 0, 0.5, (Conductor.stepCrochet * 6) / 1000, {ease: FlxEase.quadOut});
						tweenArrayNum(opponentSwap, 1, 0.5, (Conductor.stepCrochet * 6) / 1000, {ease: FlxEase.quadOut});
						tweenArrayNum(flip, 0, -1.25, (Conductor.stepCrochet * 6) / 1000, {ease: FlxEase.quadOut});
						tweenArrayNum(invert, 0, 1.25, (Conductor.stepCrochet * 6) / 1000, {ease: FlxEase.quadOut});
					case 596:
						tweenArrayNum(flip, 0, 0, (Conductor.stepCrochet * 6) / 1000, {ease: FlxEase.quadOut});
						tweenArrayNum(invert, 0, 0, (Conductor.stepCrochet * 6) / 1000, {ease: FlxEase.quadOut});
						tweenArrayNumInArray(transformXNotes, 0, 0, -Note.swagWidth * 2, (Conductor.stepCrochet * 6) / 1000, {ease: FlxEase.quadOut});
						tweenArrayNumInArray(transformXNotes, 1, 0, -Note.swagWidth, (Conductor.stepCrochet * 6) / 1000, {ease: FlxEase.quadOut});
						tweenArrayNumInArray(transformXNotes, 0, 1, -Note.swagWidth, (Conductor.stepCrochet * 6) / 1000, {ease: FlxEase.quadOut});
						tweenArrayNumInArray(transformXNotes, 1, 2, Note.swagWidth, (Conductor.stepCrochet * 6) / 1000, {ease: FlxEase.quadOut});
						tweenArrayNumInArray(transformXNotes, 0, 3, Note.swagWidth, (Conductor.stepCrochet * 6) / 1000, {ease: FlxEase.quadOut});
						tweenArrayNumInArray(transformXNotes, 1, 3, Note.swagWidth * 2, (Conductor.stepCrochet * 6) / 1000, {ease: FlxEase.quadOut});
					case 656:
						tweenArrayNum(opponentSwap, 0, 0, (Conductor.stepCrochet * 4) / 1000, {ease: FlxEase.quadOut});
						tweenArrayNum(opponentSwap, 1, 0, (Conductor.stepCrochet * 4) / 1000, {ease: FlxEase.quadOut});
						tweenArrayNumInArray(transformXNotes, 0, 0, 0, (Conductor.stepCrochet * 4) / 1000, {ease: FlxEase.quadOut});
						tweenArrayNumInArray(transformXNotes, 1, 0, 0, (Conductor.stepCrochet * 4) / 1000, {ease: FlxEase.quadOut});
						tweenArrayNumInArray(transformXNotes, 0, 1, 0, (Conductor.stepCrochet * 4) / 1000, {ease: FlxEase.quadOut});
						tweenArrayNumInArray(transformXNotes, 1, 2, 0, (Conductor.stepCrochet * 4) / 1000, {ease: FlxEase.quadOut});
						tweenArrayNumInArray(transformXNotes, 0, 3, 0, (Conductor.stepCrochet * 4) / 1000, {ease: FlxEase.quadOut});
						tweenArrayNumInArray(transformXNotes, 1, 3, 0, (Conductor.stepCrochet * 4) / 1000, {ease: FlxEase.quadOut});
					case 1168:
						for (i in 0...2) {
							for (j in 0...4) {
								tweenArrayNumInArray(transformXNotes, i, j, 0, (Conductor.stepCrochet * 2) / 1000, {ease: FlxEase.quadOut});
								tweenArrayNumInArray(transformYNotes, i, j, 0, (Conductor.stepCrochet * 2) / 1000, {ease: FlxEase.quadOut});
							}
						}
					case 1172:
						tweenArrayNum(flip, 0, 1, (Conductor.stepCrochet * 3) / 1000, {ease: FlxEase.quadOut});
						tweenArrayNum(flip, 1, 1, (Conductor.stepCrochet * 3) / 1000, {ease: FlxEase.quadOut});
					case 1180:
						tweenArrayNum(flip, 0, 0, (Conductor.stepCrochet * 3) / 1000, {ease: FlxEase.quadOut});
						tweenArrayNum(flip, 1, 0, (Conductor.stepCrochet * 3) / 1000, {ease: FlxEase.quadOut});
						tweenArrayNum(invert, 0, 1, (Conductor.stepCrochet * 3) / 1000, {ease: FlxEase.quadOut});
						tweenArrayNum(invert, 1, 1, (Conductor.stepCrochet * 3) / 1000, {ease: FlxEase.quadOut});
					case 1188:
						tweenArrayNum(invert, 0, 0, (Conductor.stepCrochet * 3) / 1000, {ease: FlxEase.quadOut});
						tweenArrayNum(invert, 1, 0, (Conductor.stepCrochet * 3) / 1000, {ease: FlxEase.quadOut});
					case 1196:
						tweenManager.tween(this, {hidden: 0.85}, (Conductor.stepCrochet * 4) / 1000, {ease: FlxEase.quadOut});
					case 1412:
						confusion[0] = -360;
						confusion[1] = 360;
						tweenArrayNum(confusion, 0, 0, (Conductor.stepCrochet * 6) / 1000, {ease: FlxEase.quadOut});
						tweenArrayNum(confusion, 1, 0, (Conductor.stepCrochet * 6) / 1000, {ease: FlxEase.quadOut});
						tweenArrayNum(opponentSwap, 0, 0, (Conductor.stepCrochet * 6) / 1000, {ease: FlxEase.quadOut});
						tweenArrayNum(opponentSwap, 1, 0, (Conductor.stepCrochet * 6) / 1000, {ease: FlxEase.quadOut});
					case 1474:
						hidden = 0;
					case 1612:
						tweenManager.tween(this, {sudden: 0.85}, (Conductor.stepCrochet * 4) / 1000, {ease: FlxEase.quadOut});
					case 1852:
						tweenManager.tween(this, {sudden: 0}, (Conductor.stepCrochet * 8) / 1000, {ease: FlxEase.quadOut});
					case 1854:
						tweenManager.tween(this, {tipsy: 0.5}, (Conductor.stepCrochet * 6) / 1000, {ease: FlxEase.quadOut});
						confusion[0] = 360;
						confusion[1] = -360;
						tweenArrayNum(confusion, 0, 0, (Conductor.stepCrochet * 6) / 1000, {ease: FlxEase.quadOut});
						tweenArrayNum(confusion, 1, 0, (Conductor.stepCrochet * 6) / 1000, {ease: FlxEase.quadOut});
					case 2016:
						confusion[0] = -360;
						confusion[1] = 360;
						tweenArrayNum(confusion, 0, 0, (Conductor.stepCrochet * 4) / 1000, {ease: FlxEase.quadOut});
						tweenArrayNum(confusion, 1, 0, (Conductor.stepCrochet * 4) / 1000, {ease: FlxEase.quadOut});
						tweenManager.tween(this, {tipsy: 0}, (Conductor.stepCrochet * 4) / 1000, {ease: FlxEase.quadOut});
					case 2268:
						tweenArrayNum(opponentSwap, 0, 0.5, (Conductor.stepCrochet * 4) / 1000, {ease: FlxEase.quadOut});
						tweenArrayNum(flip, 0, 0.5, (Conductor.stepCrochet * 4) / 1000, {ease: FlxEase.quadOut});
					case 2270:
						var goToY = ClientPrefs.downScroll ? -1280 : 1280;
						for (i in 0...4) {
							new FlxTimer(timerManager).start((Conductor.stepCrochet * (i * 0.5)) / 1000, function(_) {
								tweenArrayNumInArray(transformYNotes, 1, i, goToY, (Conductor.stepCrochet * 10) / 1000, {ease: FlxEase.backIn});
							});
						}
					case 2272:
						tweenManager.tween(this, {tfb_haloRadiusX: 128, tfb_haloRadiusZ: 0.1, tfb_haloSpeed: 1}, (Conductor.stepCrochet * 36) / 1000, {ease: FlxEase.quartOut});
					case 2308:
						tweenArrayNum(modAlpha, 0, 1, (Conductor.stepCrochet * 32) / 1000);
						tweenManager.tween(this, {tfb_haloRadiusX: 2048, tfb_haloRadiusZ: 0.8, tfb_haloSpeed: 3}, (Conductor.stepCrochet * 46) / 1000, {ease: FlxEase.quadIn});
				}

			case 'tsuraran-fox':
				switch (curStep) {
					case 1536:
						tweenManager.tween(stage.overlay, {alpha: 1}, (Conductor.stepCrochet * 16) / 1000, {ease: FlxEase.quartOut});
						tweenManager.tween(this, {defaultCamZoom: 1.4, justHowHighAreYou: 0.35}, (Conductor.stepCrochet * 16) / 1000, {ease: FlxEase.quartOut});
						stage.smonk1.x -= 600;
						stage.smonk2.x += 600;
						tweenManager.tween(stage.smonk1, {x: stage.smonk1.x + 600, alpha: 1}, (Conductor.stepCrochet * 32) / 1000, {ease: FlxEase.quadInOut});
						tweenManager.tween(stage.smonk2, {x: stage.smonk2.x - 600, alpha: 1}, (Conductor.stepCrochet * 32) / 1000, {ease: FlxEase.quadInOut});
						var chars = [dad, boyfriend, gf];
						for (char in chars)
							tweenManager.color(char, (Conductor.stepCrochet * 16) / 1000, -1, 0xff31a2fd, {ease: FlxEase.quartOut});
					case 1664:
						tweenManager.tween(stage.overlay, {alpha: 0}, (Conductor.stepCrochet * 16) / 1000, {ease: FlxEase.quartOut});
						tweenManager.tween(this, {defaultCamZoom: 1, justHowHighAreYou: 0.15}, (Conductor.stepCrochet * 16) / 1000, {ease: FlxEase.quartOut});
					case 1936:
						tweenManager.tween(this, {justHowHighAreYou: 0}, (Conductor.stepCrochet * 16) / 1000, {ease: FlxEase.quartOut});
						var chars = [dad, boyfriend, gf];
						for (char in chars)
							tweenManager.color(char, (Conductor.stepCrochet * 16) / 1000, char.color, -1, {ease: FlxEase.quartOut});
				}

			case 'no-heroes':
				if (curStep >= 1440 && curStep < 1696 && !zoomed)
				{
					zoomed = true;
					tweenManager.tween(this, {defaultCamZoom: 1.6}, 1.5, {ease: FlxEase.quadInOut});
				}
				else if (curStep >= 1696 && zoomed)
				{
					zoomed = false;
					tweenManager.tween(this, {defaultCamZoom: 1}, 1.5, {ease: FlxEase.quadInOut});
				}
		}

		lastStepHit = curStep;
	}

	function charDance(char:Character, group:FlxTypedSpriteGroup<Character>)
	{
		char.dance();
		char.keysPressed = null;

		if (group == boyfriendGroup)
		{
			boyfriendCamX = 0;
			boyfriendCamY = 0;
		}
		else if (group == dadGroup)
		{
			dadCamX = 0;
			dadCamY = 0;
		}
		else if (group == gfGroup)
		{
			gfCamX = 0;
			gfCamY = 0;
		}

		var player = (group == dadGroup ? 0 : 1);
		switch (char.curCharacter)
		{
			case 'guy':
				guyFlippedIdle[player] = !guyFlippedIdle[player];
				char.flipX = guyFlippedIdle[player];
				char.addY = 20;
				tweenManager.tween(char, {addY: 0}, 0.15, {ease: FlxEase.cubeOut});
		}
	}

	var lastBeatHit:Int = -1;

	override function beatHit()
	{
		super.beatHit();

		if (lastBeatHit >= curBeat)
			return;

		var curNumeratorBeat = Conductor.getCurNumeratorBeat(SONG, curBeat);

		var grps = [dadGroup, boyfriendGroup];
		var icons = [iconP2, iconP1];

		if (iconBopSpeed > 0 && curBeat % Math.round(Conductor.normalize(iconBopSpeed)) == 0)
		{
			iconP1.scale.set(1.2, 1.2);
			iconP2.scale.set(1.2, 1.2);
			iconP1.updateHitbox();
			iconP2.updateHitbox();

			for (i in 0...grps.length)
			{
				var grp = grps[i];
				for (char in grp)
				{
					switch (char.curCharacter)
					{
						case 'guy':
							if ((i == 0 && healthBar.percent < 80) || (i == 1 && healthBar.percent > 20))
							{
								guyFlipped[i] = !guyFlipped[i];
								icons[i].flipX = guyFlipped[i];
							}
					}
				}
			}
		}

		if (curBeat >= 0 && !endingSong)
		{
			var chars = [boyfriendGroup, dadGroup, gfGroup];
			for (group in chars)
			{
				for (char in group)
				{
					if (char.danceEveryNumBeats > 0
						&& curNumeratorBeat % (Math.round(Conductor.normalize(char.danceEveryNumBeats))) == 0 && !char.stunned && char.state == Default)
					{
						charDance(char, group);
					}
				}
			}
		}

		if (ClientPrefs.gameQuality != 'Crappy' && curBeat >= 0)
			stage.onBeatHit();

		lastBeatHit = curBeat;
	}

	override function sectionHit()
	{
		super.sectionHit();

		var songSection = SONG.notes[curSection];
		if (songSection != null)
		{
			if (ClientPrefs.camZooms && camZooming && camBop)
			{
				for (i in 0...camGames.length)
				{
					if (camGames[i].zoom < 1.35)
						camGames[i].zoom += 0.015 * camZoomingMult;
				}
				camHUD.zoom += 0.03 * camZoomingMult;
			}

			if (songSection.changeBPM && songSection.bpm != Conductor.bpm)
				Conductor.changeBPM(songSection.bpm);
			if (songSection.changeSignature
				&& (songSection.timeSignature[0] != Conductor.timeSignature[0]
					|| songSection.timeSignature[1] != Conductor.timeSignature[1]))
				Conductor.changeSignature(songSection.timeSignature);
		}
	}

	override function destroy()
	{
		FlxG.timeScale = 1;
		Conductor.playbackRate = 1;

		vocals.stop();
		vocals.destroy();
		vocalsDad.stop();
		vocalsDad.destroy();

		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

		super.destroy();

		instance = null;
	}

	public function killNotes()
	{
		for (strumLine in strumLineNotes)
		{
			while (strumLine.allNotes.length > 0)
			{
				var daNote:Note = strumLine.allNotes.members[0];
				daNote.active = false;
				daNote.visible = false;

				daNote.kill();
				strumLine.removeNote(daNote);
				daNote.destroy();
			}
		}
		unspawnNotes = [];
		eventNotes = [];
	}

	public function addBehindGF(obj:FlxObject)
	{
		stage.background.add(obj);
	}

	public function addBehindBF(obj:FlxObject)
	{
		stage.overDad.add(obj);
	}

	public function addBehindDad(obj:FlxObject)
	{
		stage.overGF.add(obj);
	}

	public function clearNotesBefore(time:Float)
	{
		var i:Int = unspawnNotes.length - 1;
		while (i >= 0)
		{
			var daNote:Note = unspawnNotes[i];
			if (daNote.strumTime - noteKillOffset < time)
			{
				if (!daNote.ignoreNote)
				{
					camZooming = true;
					camBop = true;
				}
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				daNote.kill();
				unspawnNotes.remove(daNote);
				daNote.destroy();
			}
			--i;
		}

		for (strumLine in strumLineNotes)
		{
			i = strumLine.allNotes.length - 1;
			while (i >= 0)
			{
				var daNote:Note = strumLine.allNotes.members[i];
				if (daNote.strumTime - noteKillOffset < time)
				{
					if (!daNote.ignoreNote)
					{
						camZooming = true;
						camBop = true;
					}
					daNote.active = false;
					daNote.visible = false;
					daNote.ignoreNote = true;

					daNote.kill();
					strumLine.removeNote(daNote);
					daNote.destroy();
				}
				--i;
			}
		}
	}

	function resyncVocals():Void
	{
		if (FlxG.sound.music == null || vocals == null || startingSong || endingSong || endingTimer != null)
			return;

		if (playbackRate < 1)
			FlxG.sound.music.pause();
		vocals.pause();
		vocalsDad.pause();

		if (playbackRate >= 1)
		{
			FlxG.sound.music.play();
			Conductor.songPosition = FlxG.sound.music.time;
		}
		else
		{
			FlxG.sound.music.time = Conductor.songPosition;
			FlxG.sound.music.play();
		}
		if (Conductor.songPosition <= vocals.length)
		{
			vocals.time = Conductor.songPosition;
			vocals.play();
		}
		if (Conductor.songPosition <= vocalsDad.length)
		{
			vocalsDad.time = Conductor.songPosition;
			vocalsDad.play();
		}

		setSongPitch();
	}

	function setSongPitch()
	{
		#if cpp
		if (playbackRate != 1 && !startingSong && !endingSong && !transitioning)
		{
			@:privateAccess
			{
				var audio = [FlxG.sound.music, vocals, vocalsDad];
				for (i in audio)
				{
					if (i != null
						&& i.playing
						&& i._channel != null
						&& i._channel.__source != null
						&& i._channel.__source.__backend != null
						&& i._channel.__source.__backend.handle != null)
					{
						AL.sourcef(i._channel.__source.__backend.handle, AL.PITCH, playbackRate);
					}
				}
			}
		}
		#end
	}

	function noteFunctions()
	{
		if (generatedMusic)
		{
			checkEventNote(); //doing this before setting note positions cause scroll speed event might happen!
			for (i in 0...strumLineNotes.length)
			{
				strumLineNotes.members[i].notesGroup.sort(sortByOrder);
				strumLineNotes.members[i].holdsGroup.sort(sortByOrder);
				strumLineNotes.members[i].allNotes.forEachAlive(function(daNote:Note)
				{
					var strumLine = strumLineNotes.members[i];
					var daStrum = strumLine.getReceptor(daNote.noteData);
					if (daStrum != null)
					{
						var strumX:Float = daStrum.x;
						var strumY:Float = daStrum.y;
						var strumAngle:Float = daStrum.angle;
						var strumDirection:Float = daStrum.direction;
						var strumAlpha:Float = daStrum.alpha;
						var strumScroll:Bool = (!ClientPrefs.downScroll && reverse >= 0.5) || (ClientPrefs.downScroll && reverse < 0.5);
						var strumHeight:Float = daStrum.height;
						var noteSpeed = songSpeed * daNote.multSpeed;

						daNote.z = daStrum.z;
						updateNoteScale(daNote);

						if (daNote.isSustainNote && strumScroll)
							daNote.flipY = true;

						strumX += daNote.offsetX;
						strumY += daNote.offsetY;
						strumAngle += daNote.offsetAngle;
						strumAlpha *= daNote.multAlpha;
						if (Conductor.songPosition < 0)
							strumAlpha = daNote.multAlpha;
						if (daNote.tooLate)
							strumAlpha *= 0.3;

						var diff:Float = (daNote.initialPos - Conductor.currentTrackPos);
						daNote.distance = diff;
						updateNotePath(daNote);

						if (daNote.copyAngle)
							daNote.angle = strumDirection - 90 + strumAngle;
						
						if (daNote.copyAlpha)
							daNote.alpha = strumAlpha;
						updateNoteAlpha(daNote);

						if (daNote.isSustainNote)
							daNote.flipY = strumScroll;

						var angleDir = strumDirection * Math.PI / 180;

						if (daNote.copyX)
							daNote.x = strumX + Math.cos(angleDir) * daNote.distance;

						if (daNote.copyY)
						{
							daNote.y = strumY + Math.sin(angleDir) * daNote.distance;

							if (daNote.isSustainNote && strumScroll)
							{
								if (daNote.animation.name != null && daNote.animation.name.endsWith('end'))
								{
									daNote.y += 10.5 * (daNote.stepCrochet * 4 / 400) * 1.5 * noteSpeed + (46 * (noteSpeed - 1));
									daNote.y -= 46 * (1 - (daNote.stepCrochet * 4 / 600)) * noteSpeed;
									if (SONG.skinModifier.endsWith('pixel'))
									{
										daNote.y += 8 + (6 - daNote.originalHeightForCalcs) * daPixelZoom;
									}
									else
									{
										daNote.y -= 19;
									}
								}

								daNote.y += (strumHeight / 2) - (60.5 * (noteSpeed - 1));
								daNote.y += 27.5 * ((daNote.bpm / 100) - 1) * (noteSpeed - 1);
							}
						}

						if (!daNote.mustPress && strumLine.botPlay && daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
						{
							goodNoteHit(daNote, i);
						}

						if (!daNote.blockHit && daNote.mustPress && strumLine.botPlay && daNote.canBeHit)
						{
							if (daNote.strumTime <= Conductor.songPosition || daNote.isSustainNote)
							{
								goodNoteHit(daNote, i);
							}
						}

						if (daStrum.sustainReduce
							&& daNote.isSustainNote
							&& (daNote.mustPress || !daNote.ignoreNote)
							&& (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
						{
							var center:Float = strumY + strumHeight / 2;
							if (strumScroll)
							{
								if (daNote.y + daNote.height >= center)
								{
									if (daNote.clipRect != null)
										daNote.clipRect = null;
									var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
									swagRect.height = (center - daNote.y) / daNote.scale.y;
									swagRect.y = daNote.frameHeight - swagRect.height;

									daNote.clipRect = swagRect;
								}
							}
							else
							{
								if (daNote.y <= center)
								{
									if (daNote.clipRect != null)
										daNote.clipRect = null;
									var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
									swagRect.y = (center - daNote.y) / daNote.scale.y;
									swagRect.height -= swagRect.y;

									daNote.clipRect = swagRect;
								}
							}
						}

						// Kill extremely late notes and cause misses
						if (daNote.exists
							&& Conductor.songPosition > daNote.strumTime + (noteKillOffset / noteSpeed)
							&& (daNote.isSustainNote || !strumLine.botPlay))
						{
							if (daNote.mustPress && !daNote.ignoreNote && (daNote.tooLate || !daNote.wasGoodHit))
								noteMiss(daNote, i);

							daNote.active = false;
							daNote.visible = false;

							daNote.kill();
							strumLine.removeNote(daNote);
							daNote.destroy();
						}
					}
				});
			}
		}
		keyShit();
	}

	public function openPauseMenu()
	{
		persistentUpdate = false;
		paused = true;

		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.pause();
			vocals.pause();
			vocalsDad.pause();
			@:privateAccess { // This is so hiding the debugger doesn't play the music again
				FlxG.sound.music._alreadyPaused = true;
				vocals._alreadyPaused = true;
				vocalsDad._alreadyPaused = true;
			}
		}
		openSubState(new PauseSubState());

		#if DISCORD_ALLOWED
		DiscordClient.changePresence(detailsPausedText, '$curSongDisplayName ($storyDifficultyText)', iconP2.char);
		#end
	}

	function startSong():Void
	{
		startingSong = false;

		FlxG.sound.playMusic(Paths.inst(curSong, CoolUtil.getDifficultyFilePath()), 1, false);
		if (playbackRate == 1)
			FlxG.sound.music.onComplete = finishSong.bind(false);
		vocals.play();
		vocalsDad.play();

		setSongPitch();

		if (paused)
		{
			FlxG.sound.music.pause();
			vocals.pause();
			vocalsDad.pause();
		}

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
		tweenManager.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, '$curSongDisplayName ($storyDifficultyText)', iconP2.char, true, songLength / playbackRate);
		#end
	}

	public function finishSong(?ignoreNoteOffset:Bool = false):Void
	{
		var finishCallback:Void->Void = endSong; // In case you want to change it in a specific song.

		updateTime = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		vocals.pause();
		vocalsDad.volume = 0;
		vocalsDad.pause();
		if (ClientPrefs.noteOffset <= 0 || ignoreNoteOffset)
		{
			finishCallback();
		}
		else
		{
			endingTimer = new FlxTimer(timerManager).start(ClientPrefs.noteOffset / 1000, function(tmr:FlxTimer)
			{
				finishCallback();
			});
		}
	}

	public function endSong():Void
	{
		timeTxt.visible = false;
		canPause = false;
		endingSong = true;
		camZooming = false;
		camBop = false;
		updateTime = false;

		FlxG.timeScale = 1;

		var icons = [iconP2, iconP1];
		var groups = [dadGroup, boyfriendGroup];
		for (i in 0...2)
		{
			icons[i].flipX = false;
			for (char in groups[i])
			{
				switch (char.curCharacter)
				{
					case 'guy':
						char.addY = 0;
						char.y = char.defaultY;
						guyFlippedIdle[i] = char.flipped;
						char.flipX = char.flipped;
				}
			}
		}

		isCameraOnForcedPos = true;
		for (i in 0...songScore.length)
		{
			songScore[i] = Math.round(songScore[i]);
			updateScore(true, i);
		}
		var charGroup = boyfriendGroup;
		if (songScore[1] > songScore[0])
		{
			winTxt.text = 'Player ${MultiControls.playerFromPosition(1) + 1} wins!';
			if (doubleCamMode)
			{
				tweenCamIn(1);
				camGames[0].fade(FlxColor.BLACK, 1);
			}
			else
			{
				moveCamera(false);
			}
			playerWins[1]++;
		}
		else if (songScore[0] > songScore[1])
		{
			winTxt.text = 'Player ${MultiControls.playerFromPosition(0) + 1} wins!';
			charGroup = dadGroup;
			if (doubleCamMode)
			{
				tweenCamIn(0);
				camGames[1].fade(FlxColor.BLACK, 1);
			}
			else
			{
				moveCamera(true);
			}
			playerWins[0]++;
		}
		else
		{
			winTxt.text = "Tie!";
			charGroup = null;
			if (storyPlaylist.length != 2 || playerWins[0] != playerWins[1])
			{
				playerWins[0]++;
				playerWins[1]++;
			}
		}
		winTxt.screenCenter();
		winBG.visible = winTxt.visible = true;
		winGraphics[0].animation.play('${playerWins[0]}');
		winGraphics[1].animation.play('${playerWins[1]}');
		if (charGroup != null)
		{
			for (char in charGroup)
			{
				if (char.animation.exists('hey'))
					char.playAnim('hey', true);
				else
					char.playAnim('singUP', true);
			}
			for (char in gfGroup)
			{
				if (char.animation.exists('cheer'))
					char.playAnim('cheer', true);
			}
		}
		new FlxTimer(timerManager).start(4, function(tmr)
		{
			storyPlaylist.shift();
			storyDifficulties.shift();
			storyWeeks.shift();
			if (storyPlaylist.length <= 0 || (storyPlaylist.length == 1 && playerWins[0] != playerWins[1]))
				exit();
			else
			{
				var tiebreakerNext = (storyPlaylist.length == 1);

				CoolUtil.getDifficulties(storyPlaylist[0], true);
				if (tiebreakerNext)
				{
					storyDifficulty = CoolUtil.difficulties.length - 1;
				}
				else
				{
					storyDifficulty = storyDifficulties[0];
				}
				storyWeek = storyWeeks[0];
				var difficulty:String = CoolUtil.getDifficultyFilePath();

				trace('LOADING NEXT SONG');
				trace(Paths.formatToSongPath(storyPlaylist[0]) + difficulty);

				if (tiebreakerNext)
				{
					var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
						-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
					blackShit.scrollFactor.set();
					add(blackShit);
					camHUD.visible = false;
					camHUD2.visible = false;
					camNotes.visible = false;

					FlxG.sound.play(Paths.sound('Lights_Shut_off'));
				}

				for (i in 0...camFollow.length)
				{
					prevCamFollow[i] = camFollow[i];
					prevCamFollowPos[i] = camFollowPos[i];
				}

				var oldP1 = SONG.player1;
				var oldP2 = SONG.player2;
				SONG = Song.loadFromJson(storyPlaylist[0] + difficulty, storyPlaylist[0]);
				SONG.player1 = oldP1;
				SONG.player2 = oldP2;
				FlxG.sound.music.stop();

				if (tiebreakerNext)
				{
					new FlxTimer(timerManager).start(1.5, function(tmr:FlxTimer)
					{
						CoolUtil.cancelMusicFadeTween();
						MusicBeatState.resetState();
					});
				}
				else
				{
					CoolUtil.cancelMusicFadeTween();
					MusicBeatState.resetState();
				}
			}
		});
	}

	function exit()
	{
		CoolUtil.cancelMusicFadeTween();
		if (FlxTransitionableState.skipNextTransIn)
			CustomFadeTransition.nextCamera = null;
		MusicBeatState.switchState(new SongSelectState());
		CoolUtil.playPvPMusic();
		#if cpp
		@:privateAccess
		AL.sourcef(FlxG.sound.music._channel.__source.__backend.handle, AL.PITCH, 1);
		#end
		transitioning = true;
	}

	var cachedImages:Map<String, Bool> = new Map();

	function cacheImage(image:String)
	{
		if (!cachedImages.exists(image))
		{
			var fuck = new FlxSprite().loadGraphic(Paths.image(image));
			fuck.scrollFactor.set();
			fuck.alpha = 0.00001;
			fuck.cameras = [camHUD];
			add(fuck);
			new FlxTimer(timerManager).start(1, function(tmr)
			{
				fuck.kill();
				remove(fuck);
				fuck.destroy();
			});
			cachedImages.set(image, true);
		}
	}

	private function generateSong():Void
	{
		if (CoolUtil.existsVoices(curSong))
		{
			vocals = new FlxSound().loadEmbedded(Paths.voices(curSong, CoolUtil.getDifficultyFilePath()));

			vocalsDad = new FlxSound();
			var file = Paths.voicesDad(curSong, CoolUtil.getDifficultyFilePath());
			if (file != null)
			{
				foundDadVocals = true;
				vocalsDad.loadEmbedded(file);
			}
		}
		else
		{
			vocals = new FlxSound();
			vocalsDad = new FlxSound();
		}

		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(vocalsDad);

		var inst = new FlxSound().loadEmbedded(Paths.inst(curSong, CoolUtil.getDifficultyFilePath()));
		FlxG.sound.list.add(inst);
		songLength = inst.length;

		trace('generated music');

		unspawnNotes = Song.generateNotes(SONG, strumLineNotes.members[0], strumLineNotes.members[1], onNotePush, true);
		trace('generated notes');

		var daEventNotes = Song.generateEventNotes(SONG, eventPushed, eventNoteEarlyTrigger);
		for (note in daEventNotes)
		{
			trace(note.event, note.event == 'Change Scroll Speed');
			if (note.event == 'Change Scroll Speed')
				eventNotes.push(note);
		}
		trace(eventNotes);
		/*var curBPM = SONG.bpm;
			var curDenominator = SONG.timeSignature[1];
			for (i in 0...Conductor.bpmChangeMap.length)
			{
				var bpmChange = Conductor.bpmChangeMap[i];
				if (curBPM != bpmChange.bpm || curDenominator != bpmChange.timeSignature[1])
				{
					var scrollSpeed = CoolUtil.boundTo(CoolUtil.scrollSpeedFromBPM(bpmChange.bpm, bpmChange.timeSignature[1]), 0.1, 3.5);
					var subEvent:EventNote = {
						strumTime: bpmChange.songTime,
						event: 'Change Scroll Speed',
						value1: '${scrollSpeed / songSpeed}',
						value2: '0.5'
					};
					eventNotes.push(subEvent);
					curBPM = bpmChange.bpm;
					curDenominator = bpmChange.timeSignature[1];
				}
		}*/
		trace('generated events');

		if (unspawnNotes.length > 1)
			unspawnNotes.sort(sortByShit);

		if (eventNotes.length > 1)
			eventNotes.sort(sortByTime);

		Paths.image(getNoteFile('noteSplashes'));
		if (boyfriendNotes > dadNotes && boyfriendNotes > 0)
		{
			dadScoreMult = (boyfriendNotes / dadNotes);
		}
		else if (dadNotes > boyfriendNotes && dadNotes > 0)
		{
			boyfriendScoreMult = (dadNotes / boyfriendNotes);
		}
		trace(dadNotes, boyfriendNotes);
		trace(dadScoreMult, boyfriendScoreMult);

		checkEventNote();
		generatedMusic = true;
	}

	var noteTypeMap:Map<String, Bool> = new Map();
	var boyfriendNotes:Int = 0;
	var dadNotes:Int = 0;

	function onNotePush(array:Array<Note>)
	{
		var note = array[array.length - 1];
		if (note.strumTime >= songLength)
		{
			note.kill();
			array.remove(note);
			note.destroy();
		}
		else if (note.noteData > -1)
		{
			note.characters = [];
			note.initialPos = getPosFromTime(note.strumTime, note.multSpeed);
			if (ClientPrefs.noteSplashes && note.noteSplashTexture != null && note.noteSplashTexture.length > 0 && !note.noteSplashDisabled)
				cacheImage(getNoteFile(note.noteSplashTexture));
			if (!note.isSustainNote && !note.ignoreNote && !note.hitCausesMiss)
			{
				if (note.isOpponent)
					dadNotes += 1;
				else
					boyfriendNotes += 1;
			}
			if (!noteTypeMap.exists(note.noteType))
			{
				switch (note.noteType)
				{
					case 'Static Note':
						var dummyStatic = new FlxSprite();
						dummyStatic.frames = Paths.getSparrowAtlas('sonicexe/hitStatic');
						dummyStatic.animation.addByPrefix('static', 'staticANIMATION', 24, false);
						dummyStatic.animation.play('static');
						dummyStatic.alpha = 0.00001;
						dummyStatic.cameras = [camHUD2];
						add(dummyStatic);
						Paths.sound('sonicexe/hitStatic1');
				}
				noteTypeMap.set(note.noteType, true);
			}
		}
	}

	function cacheCountdown()
	{
		var introAlts:Array<String> = ['ready', 'set', 'go'];
		for (asset in introAlts)
			cacheImage(getUIFile(asset));

		precacheList.set('intro3' + introSoundsSuffix, 'sound');
		precacheList.set('intro2' + introSoundsSuffix, 'sound');
		precacheList.set('intro1' + introSoundsSuffix, 'sound');
		precacheList.set('introGo' + introSoundsSuffix, 'sound');
	}

	public function startCountdown():Void
	{
		if (startedCountdown)
			return;

		FlxG.timeScale = playbackRate;
		if (skipCountdown)
			skipArrowStartTween = true;

		startedCountdown = true;

		Conductor.songPosition = 0;
		Conductor.songPosition -= 2500;

		var swagCounter:Int = 0;

		if (skipCountdown)
		{
			setSongTime(0);
			return;
		}
		startTimer = new FlxTimer(timerManager).start(0.5, function(tmr:FlxTimer)
		{
			switch (swagCounter)
			{
				case 0:
					FlxG.sound.play(Paths.sound('intro3$introSoundsSuffix'), 0.6);
				case 1:
					countdownReady = new FlxSprite().loadGraphic(Paths.image(getUIFile('ready')));
					countdownReady.cameras = [camHUD];
					countdownReady.scrollFactor.set();

					if (SONG.skinModifier.endsWith('pixel'))
						countdownReady.setGraphicSize(Std.int(countdownReady.width * daPixelZoom));

					countdownReady.screenCenter();
					countdownReady.antialiasing = ClientPrefs.globalAntialiasing && !SONG.skinModifier.endsWith('pixel');
					insert(members.indexOf(strumLineNotes), countdownReady);
					tweenManager.tween(countdownReady, {alpha: 0}, 0.5, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							remove(countdownReady);
							countdownReady.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('intro2$introSoundsSuffix'), 0.6);
				case 2:
					countdownSet = new FlxSprite().loadGraphic(Paths.image(getUIFile('set')));
					countdownSet.cameras = [camHUD];
					countdownSet.scrollFactor.set();

					if (SONG.skinModifier.endsWith('pixel'))
						countdownSet.setGraphicSize(Std.int(countdownSet.width * daPixelZoom));

					countdownSet.screenCenter();
					countdownSet.antialiasing = ClientPrefs.globalAntialiasing && !SONG.skinModifier.endsWith('pixel');
					insert(members.indexOf(strumLineNotes), countdownSet);
					tweenManager.tween(countdownSet, {alpha: 0}, 0.5, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							remove(countdownSet);
							countdownSet.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('intro1$introSoundsSuffix'), 0.6);
				case 3:
					countdownGo = new FlxSprite().loadGraphic(Paths.image(getUIFile('go')));
					countdownGo.cameras = [camHUD];
					countdownGo.scrollFactor.set();

					if (SONG.skinModifier.endsWith('pixel'))
						countdownGo.setGraphicSize(Std.int(countdownGo.width * daPixelZoom));

					countdownGo.screenCenter();
					countdownGo.antialiasing = ClientPrefs.globalAntialiasing && !SONG.skinModifier.endsWith('pixel');
					insert(members.indexOf(strumLineNotes), countdownGo);
					tweenManager.tween(countdownGo, {alpha: 0}, 0.5, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							remove(countdownGo);
							countdownGo.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('introGo$introSoundsSuffix'), 0.6);
			}

			swagCounter += 1;
		}, 5);
	}

	private function getKeyFromEvent(key:FlxKey):Int
	{
		if (key != NONE)
		{
			for (i in 0...keysArray.length)
			{
				for (j in 0...keysArray[i].length)
				{
					if (key == keysArray[i][j])
						return i;
				}
			}
		}
		return -1;
	}

	private function onKeyPress(event:KeyboardEvent):Void
	{
		if (!paused && startedCountdown && !endingSong)
		{
			var eventKey:FlxKey = event.keyCode;
			var key:Int = getKeyFromEvent(eventKey);

			if (key > -1 && FlxG.keys.checkStatus(eventKey, JUST_PRESSED) && !groupFromPlayer(0).members[0].stunned)
			{
				strumPressed(key, MultiControls.playerPosition(0), [eventKey]);
			}
		}
	}

	private function onKeyRelease(event:KeyboardEvent):Void
	{
		if (!paused && startedCountdown && !endingSong)
		{
			var eventKey:FlxKey = event.keyCode;
			var key:Int = getKeyFromEvent(eventKey);
			if (key > -1)
			{
				var spr:StrumNote = strumLineNotes.members[MultiControls.playerPosition(0)].getReceptor(key);
				if (spr != null)
					spr.playAnim('static');
			}
		}
	}

	// Hold notes + controller input
	private function keyShit():Void
	{
		if (startedCountdown && !endingSong) {
			// HOLDING
			var controlHoldArray:Array<Bool> = [];
			if (!strumLineFromPlayer(0).botPlay)
			{
				for (i in keysArray)
					controlHoldArray.push(FlxG.keys.anyPressed(i));

				if (controlHoldArray.contains(true) && !groupFromPlayer(0).members[0].stunned && generatedMusic)
				{
					// rewritten inputs???
					strumLineFromPlayer(0).allNotes.forEachAlive(function(daNote:Note)
					{
						// hold note functions
						if (daNote.isSustainNote && controlHoldArray[daNote.noteData] && daNote.canBeHit && daNote.mustPress && !daNote.tooLate
							&& !daNote.wasGoodHit && !daNote.blockHit)
							goodNoteHit(daNote, MultiControls.playerPosition(0), keysArray[daNote.noteData]);
					});
				}
				else
				{
					for (char in groupFromPlayer(0))
					{
						if (char.holdTimer > Conductor.normalizedStepCrochet * 0.0011 * char.singDuration
							&& !char.stunned
							&& char.state == Sing)
						{
							charDance(char, groupFromPlayer(0));
						}
					}
				}
			}
			else
			{
				for (char in groupFromPlayer(0))
				{
					if (char.holdTimer > Conductor.normalizedStepCrochet * 0.0011 * char.singDuration && !char.stunned && char.state == Sing)
					{
						charDance(char, groupFromPlayer(0));
					}
				}
			}

			if (!strumLineFromPlayer(1).botPlay)
			{
				// ALL OPPONENT INPUTS HERE
				var controlArray:Array<Bool> = [
					MultiControls.playerCheck(NOTE_LEFT_P, 1),
					MultiControls.playerCheck(NOTE_DOWN_P, 1),
					MultiControls.playerCheck(NOTE_UP_P, 1),
					MultiControls.playerCheck(NOTE_RIGHT_P, 1)
				];
				if (controlArray.contains(true))
				{
					for (i in 0...controlArray.length)
					{
						if (controlArray[i])
							strumPressed(i, MultiControls.playerPosition(1), null, true);
					}
				}

				controlHoldArray = [
					MultiControls.playerCheck(NOTE_LEFT, 1),
					MultiControls.playerCheck(NOTE_DOWN, 1),
					MultiControls.playerCheck(NOTE_UP, 1),
					MultiControls.playerCheck(NOTE_RIGHT, 1)
				];
				if (controlHoldArray.contains(true) && generatedMusic)
				{
					// rewritten inputs???
					strumLineFromPlayer(1).holdsGroup.forEachAlive(function(daNote:Note)
					{
						// hold note functions
						if (controlHoldArray[daNote.noteData] && daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.blockHit)
							goodNoteHit(daNote, MultiControls.playerPosition(1), keysArray[daNote.noteData], true);
					});
				}
				else
				{
					for (char in groupFromPlayer(1))
					{
						if (char.holdTimer > Conductor.normalizedStepCrochet * 0.0011 * char.singDuration
							&& !char.stunned
							&& char.state == Sing)
						{
							charDance(char, groupFromPlayer(1));
						}
					}
				}

				var controlReleaseArray:Array<Bool> = [
					MultiControls.playerCheck(NOTE_LEFT_R, 1),
					MultiControls.playerCheck(NOTE_DOWN_R, 1),
					MultiControls.playerCheck(NOTE_UP_R, 1),
					MultiControls.playerCheck(NOTE_RIGHT_R, 1)
				];
				if (controlReleaseArray.contains(true))
				{
					for (i in 0...controlReleaseArray.length)
					{
						if (controlReleaseArray[i])
						{
							var spr:StrumNote = strumLineFromPlayer(1).getReceptor(i);
							if (spr != null)
							{
								spr.playAnim('static');
							}
						}
					}
				}
			}
			else
			{
				for (char in groupFromPlayer(1))
				{
					if (char.holdTimer > Conductor.normalizedStepCrochet * 0.0011 * char.singDuration && !char.stunned && char.state == Sing)
					{
						charDance(char, groupFromPlayer(1));
					}
				}
			}
		}
	}

	function strumPressed(key:Int = 0, id:Int = 0, ?eventKey:Array<FlxKey>, isGamepad:Bool = false)
	{
		var strumGroup = strumLineNotes.members[id];
		if (strumGroup.botPlay)
			return;
		var lastTime:Float = Conductor.songPosition;
		// more accurate hit time for the ratings?
		Conductor.songPosition = FlxG.sound.music.time;

		// heavily based on my own code LOL if it aint broke dont fix it
		var pressNotes:Array<Note> = [];
		var notesStopped:Bool = false;
		var foundNote:Bool = false;

		var sortedNotesList:Array<Note> = [];
		strumGroup.allNotes.forEachAlive(function(daNote:Note)
		{
			if (daNote.noteData == key && daNote.canBeHit && !daNote.tooLate && !daNote.wasGoodHit && !daNote.blockHit)
			{
				foundNote = true; // needed to detect sustain notes and not cause a mispress
				if (!daNote.isSustainNote)
					sortedNotesList.push(daNote);
			}
		});
		sortedNotesList.sort(sortHitNotes);

		if (sortedNotesList.length > 0)
		{
			for (epicNote in sortedNotesList)
			{
				for (doubleNote in pressNotes)
				{
					if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 1)
					{
						songScore[id] += ratingsData[0].score * (doubleNote.isOpponent ? dadScoreMult : boyfriendScoreMult);
						doubleNote.kill();
						strumGroup.removeNote(doubleNote);
						doubleNote.destroy();
					}
					else
						notesStopped = true;
				}

				// eee jack detection before was not super good
				if (!notesStopped)
				{
					goodNoteHit(epicNote, id, eventKey, isGamepad);
					pressNotes.push(epicNote);
				}
			}
		}
		else if (!foundNote)
		{
			noteMispress(key, id, eventKey);
		}

		// more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
		Conductor.songPosition = lastTime;

		var spr:StrumNote = strumGroup.getReceptor(key);
		if (spr != null && spr.animation.name != 'confirm')
		{
			spr.playAnim('pressed');
		}
	}

	function sortHitNotes(a:Note, b:Note):Int
	{
		if (a.lowPriority && !b.lowPriority)
			return 1;
		else if (!a.lowPriority && b.lowPriority)
			return -1;

		return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime);
	}

	function goodNoteHit(note:Note, id:Int = 0, ?keys:Array<FlxKey>, isGamepad:Bool = false):Void
	{
		if (keys == null)
			keys = [];
		if (!note.mustPress || !note.wasGoodHit)
		{
			var strumGroup = strumLineNotes.members[id];
			if (strumGroup.botPlay && (note.ignoreNote || note.hitCausesMiss))
				return;

			var charGroup = note.gfNote ? gfGroup : (note.isOpponent ? dadGroup : boyfriendGroup);

			var characters = note.characters.copy();
			if (characters.length < 1)
			{
				for (i in 0...charGroup.length)
				{
					characters.push(i);
				}
			}

			if (!strumGroup.botPlay)
			{
				var spr = strumGroup.getReceptor(note.noteData);
				if (spr != null)
				{
					spr.playAnim('confirm', true);
				}
			}

			if (note.hitCausesMiss)
			{
				noteMiss(note, id);
				if (!note.noteSplashDisabled && !note.isSustainNote)
				{
					spawnNoteSplashOnNote(note, strumGroup);
				}

				if (note.playAnim != null && note.playAnim.length > 0)
				{
					for (i in characters)
					{
						if (charGroup.members[i] != null && charGroup.members[i].animation.exists(note.playAnim))
						{
							charGroup.members[i].playAnim(note.playAnim, true);
							charGroup.members[i].specialAnim = true;
						}
					}
				}

				note.wasGoodHit = true;
				if (!strumGroup.getReceptor(note.noteData).sustainReduce || !note.isSustainNote)
				{
					note.kill();
					strumGroup.removeNote(note);
					note.destroy();
				}
				return;
			}

			camZooming = true;
			camBop = true;

			if (!note.isSustainNote)
			{
				combo[id] += 1;
				if (combo[id] > 9999)
					combo[id] = 9999;
				health += note.hitHealth * (note.isOpponent ? -1 : 1);
				popUpScore(note, id);
			}

			if (!note.noAnimation)
			{
				var altAnim:String = note.animSuffix;

				var ogAnim:String = strumGroup.animations[note.noteData];
				if (note.playAnim != null && note.playAnim.length > 0)
					ogAnim = note.playAnim;

				var xAdd:Float = 0;
				var yAdd:Float = 0;
				switch (ogAnim)
				{
					case 'singLEFT':
						xAdd = -30;
					case 'singDOWN':
						yAdd = 30;
					case 'singUP':
						yAdd = -30;
					case 'singRIGHT':
						xAdd = 30;
				}

				if (!note.gfNote)
				{
					if (note.isOpponent)
					{
						dadCamX = xAdd;
						dadCamY = yAdd;
					}
					else
					{
						boyfriendCamX = xAdd;
						boyfriendCamY = yAdd;
					}
				}
				else
				{
					gfCamX = xAdd;
					gfCamY = yAdd;
				}

				if (note.noteType == 'Hey!')
				{
					for (i in characters)
					{
						if (i < charGroup.members.length
							&& charGroup.members[i] != null
							&& charGroup.members[i].animation.exists('hey')
							&& !charGroup.members[i].skipSing)
						{
							if (!note.isSustainNote || charGroup.members[i].repeatHoldAnimation)
								charGroup.members[i].playAnim('hey', true);
							charGroup.members[i].specialAnim = true;
							charGroup.members[i].heyTimer = 0.6;
						}
					}

					for (gf in gfGroup)
					{
						if (gf.animation.exists('cheer'))
						{
							if (!note.isSustainNote || gf.repeatHoldAnimation)
								gf.playAnim('cheer', true);
							gf.specialAnim = true;
							gf.heyTimer = 0.6;
						}
					}
				}
				else
				{
					for (i in characters)
					{
						if (charGroup.members[i] != null && !charGroup.members[i].skipSing)
						{
							var didSing = false;
							var char = charGroup.members[i];

							var animToPlay:String = ogAnim + altAnim;
							if ((note.isOpponent && !dadMatch)
								|| (!note.isOpponent && !boyfriendMatch)
								|| !char.animation.exists(animToPlay))
								animToPlay = ogAnim;

							if (char.animation.exists(animToPlay))
							{
								if (!note.isSustainNote || char.repeatHoldAnimation)
									char.playAnim(animToPlay, true);
								char.holdTimer = 0;
								didSing = true;
								if (ogAnim != note.playAnim)
								{
									char.state = Sing;
								}
							}

							if (didSing)
							{
								switch (char.curCharacter)
								{
									case 'guy':
										char.addY = 0;
										char.y = char.defaultY;
										guyFlippedIdle[id] = char.flipped;
										char.flipX = char.flipped;
								}
							}
						}
					}
				}
			}

			if (strumGroup.botPlay)
			{
				var time:Float = 0.15;
				if (note.isSustainNote && note.animation.name != null && !note.animation.name.endsWith('end'))
				{
					time += 0.15;
				}

				var spr = strumGroup.getReceptor(note.noteData);
				if (spr != null)
				{
					spr.playAnim('confirm', true);
					spr.resetAnim = time;
				}

				if (!note.noteSplashDisabled && !note.isSustainNote)
				{
					spawnNoteSplashOnNote(note, strumGroup);
				}
			}
			note.wasGoodHit = true;

			if (!note.mustPress)
				note.hitByOpponent = true;

			if (!strumGroup.getReceptor(note.noteData).sustainReduce || !note.isSustainNote)
			{
				note.kill();
				strumGroup.removeNote(note);
				note.destroy();
			}
		}
	}

	function noteMiss(daNote:Note, id:Int = 0):Void
	{ // You didn't hit the key and let it go offscreen, also used by Hurt Notes
		var strumGroup = strumLineNotes.members[id];
		// Dupe note remove
		strumGroup.allNotes.forEachAlive(function(note:Note)
		{
			if (daNote != note
				&& daNote.noteData == note.noteData
				&& daNote.isSustainNote == note.isSustainNote
				&& Math.abs(daNote.strumTime - note.strumTime) < 1)
			{
				if (!note.isSustainNote)
					songScore[id] += ratingsData[0].score * (note.isOpponent ? dadScoreMult : boyfriendScoreMult);
				note.kill();
				strumGroup.removeNote(note);
				note.destroy();
			}
		});

		if (!daNote.isSustainNote)
		{
			combo[id] = 0;
			health -= daNote.missHealth * (daNote.isOpponent ? -1 : 1);
			songMisses[id]++;
			doRatingTween(ratingTxtGroup[id].members.length - 1, id);
		}

		switch (daNote.noteType)
		{
			case 'Static Note':
				songScore[id] -= 350;
			case 'Phantom Note':
				songScore[id] -= 100;
			default:
				songScore[id] -= daNote.missScore;
		}

		totalPlayed[id]++;
		recalculateRating(true, id);

		var charGroup = strumGroup.isBoyfriend ? boyfriendGroup : dadGroup;
		if (daNote.gfNote)
		{
			charGroup = gfGroup;
		}

		var characters = daNote.characters.copy();
		if (characters.length < 1)
		{
			for (i in 0...boyfriendGroup.length)
			{
				characters.push(i);
			}
		}
		for (i in characters)
		{
			if (i < charGroup.members.length
				&& charGroup.members[i] != null
				&& charGroup.members[i].hasMissAnimations
				&& !charGroup.members[i].skipSing)
			{
				var char = charGroup.members[i];
				var animToPlay:String = '${strumGroup.animations[daNote.noteData]}miss${daNote.animSuffix}';
				if ((daNote.isOpponent && !dadMatch) || (!daNote.isOpponent && !boyfriendMatch) || !char.animation.exists(animToPlay))
					animToPlay = '${strumGroup.animations[daNote.noteData]}miss';
				if (char.animation.exists(animToPlay))
				{
					char.playAnim(animToPlay, true);
					char.state = Miss;
				}
			}
		}

		camZooming = true;
		camBop = true;

		switch (daNote.noteType)
		{
			case 'Static Note':
				var daNoteStatic = new FlxSprite(0, 0);
				if (id > 0)
					daNoteStatic.x = FlxG.width / 2;
				daNoteStatic.frames = Paths.getSparrowAtlas('sonicexe/hitStatic');
				daNoteStatic.setGraphicSize(Std.int(FlxG.width / 2), FlxG.height);
				daNoteStatic.updateHitbox();
				daNoteStatic.screenCenter(Y);
				daNoteStatic.cameras = [camHUD2];
				daNoteStatic.animation.addByPrefix('static', 'staticANIMATION', 24, false);
				daNoteStatic.animation.play('static', true);
				shakeCam2[id] = true;

				new FlxTimer(timerManager).start(0.8, function(tmr:FlxTimer)
				{
					shakeCam2[id] = false;
				});

				FlxG.sound.play(Paths.sound("sonicexe/hitStatic1"));

				add(daNoteStatic);

				new FlxTimer(timerManager).start(.38, function(trol:FlxTimer) // fixed lmao
				{
					daNoteStatic.kill();
					remove(daNoteStatic);
					daNoteStatic.destroy();
				});
		}
	}

	function noteMispress(direction:Int = 1, id:Int = 0, ?eventKey:Array<FlxKey>):Void // You pressed a key when there was no notes to press for this key
	{
		var charGroup = id == 0 ? dadGroup : boyfriendGroup;
		var animToPlay = '${strumLineNotes.members[id].animations[direction]}miss';
		for (char in charGroup)
		{
			if (!char.specialAnim && !char.skipSing)
			{
				if (char.hasMissAnimations && char.animation.exists(animToPlay))
				{
					char.playAnim(animToPlay, true);
				}
				else
				{
					char.playAnim(strumLineNotes.members[id].animations[direction], true);
					char.holdTimer = 0;
				}
				char.state = Sing;
				switch (char.curCharacter)
				{
					case 'guy':
						char.addY = 0;
						char.y = char.defaultY;
						guyFlippedIdle[id] = char.flipped;
						char.flipX = char.flipped;
				}
			}
		}
		if (ClientPrefs.ghostTapping || !startedCountdown)
			return; // fuck it

		if (!charGroup.members[0].stunned)
		{
			if (combo[id] > 5)
			{
				for (gf in gfGroup)
				{
					if (gf.animation.exists('sad'))
					{
						gf.playAnim('sad');
					}
				}
			}
			combo[id] = 0;
			health -= 0.05 * (id == 0 ? -1 : 1);

			songScore[id] -= 10;
			songMisses[id]++;
			totalPlayed[id]++;
			recalculateRating(true, id);
			doRatingTween(ratingTxtGroup[id].members.length - 1, id);

			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
		}
	}

	function spawnNoteSplashOnNote(note:Note, strumGroup:StrumLine)
	{
		if (note != null && ClientPrefs.noteSplashes)
		{
			var strum:StrumNote = strumGroup.getReceptor(note.noteData);
			if (strum != null)
			{
				spawnNoteSplash(strum.x, strum.y, note, strumGroup);
			}
		}
	}

	public function spawnNoteSplash(x:Float, y:Float, note:Note, strumGroup:StrumLine)
	{
		var skin:String = 'noteSplashes';
		var keys = strumGroup.keys;

		var hue:Float = 0;
		var sat:Float = 0;
		var brt:Float = 0;
		if (note.noteData > -1 && note.noteData < ClientPrefs.arrowHSV[keys - 1].length)
		{
			hue = ClientPrefs.arrowHSV[keys - 1][note.noteData][0] / 360;
			sat = ClientPrefs.arrowHSV[keys - 1][note.noteData][1] / 100;
			brt = ClientPrefs.arrowHSV[keys - 1][note.noteData][2] / 100;
			if (note != null)
			{
				skin = note.noteSplashTexture;
				hue = note.noteSplashHue;
				sat = note.noteSplashSat;
				brt = note.noteSplashBrt;
			}
		}

		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, note, skin, hue, sat, brt, keys);
		grpNoteSplashes.add(splash);
	}

	public function setSongTime(time:Float)
	{
		if (time < 0)
			time = 0;

		FlxG.sound.music.pause();
		vocals.pause();
		vocalsDad.pause();

		FlxG.sound.music.time = time;
		FlxG.sound.music.play();

		if (time <= vocals.length)
		{
			vocals.time = time;
			vocals.play();
		}
		if (time <= vocalsDad.length)
		{
			vocalsDad.time = time;
			vocalsDad.play();
		}
		setSongPitch();
		Conductor.songPosition = time;

		updateCurStep();
		Conductor.getLastBPM(SONG, curStep);
	}

	function startCharacterPos(char:Character, gfCheck:Bool = false)
	{
		if (gfCheck && char.curCharacter.startsWith('gf'))
		{ // IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	function addCharacter(name:String, index:Int = 0, flipped:Bool = false, ?group:FlxTypedSpriteGroup<Character>, xOffset:Float = 0, yOffset:Float = 0,
			scrollX:Float = 1, scrollY:Float = 1):Character
	{
		var char = new Character(0, 0, name, flipped);
		startCharacterPos(char);
		char.x += xOffset;
		char.y += yOffset;
		char.scrollFactor.set(scrollX, scrollY);
		if (group != null)
		{
			group.add(char);
			char.addedToGroup = true;
			if (group == gfGroup)
				char.isGF = true;
		}
		if (!char.isGF)
			char.isPlayer = true;
		cacheImage(char.imageFile);
		switch (char.curCharacter)
		{
			case 'spirit':
				var evilTrail = new FlxTrail(char, null, 4, 24, 0.3, 0.069); // nice
				evilTrail.scrollFactor.copyFrom(char.scrollFactor);
				addBehindChar(char, evilTrail);
				char.associatedSprites.push(evilTrail);

			case 'TDoll', 'TDollAlt':
				var ezTrail = new FlxTrail(char, null, 2, 5, 0.3, 0.04);
				ezTrail.scrollFactor.copyFrom(char.scrollFactor);
				addBehindChar(char, ezTrail);
				char.associatedSprites.push(ezTrail);

			case 'sshaggy':
				var shaggyT = new FlxTrail(char, null, 3, 6, 0.3, 0.002);
				shaggyT.scrollFactor.copyFrom(char.scrollFactor);
				addBehindChar(char, shaggyT);
				char.associatedSprites.push(shaggyT);

			case 'pshaggy':
				var legs = new FlxSprite();
				legs.frames = Paths.getSparrowAtlas('characters/pshaggy');
				legs.animation.addByPrefix('legs', "solo_legs", 30);
				legs.animation.play('legs');
				legs.antialiasing = ClientPrefs.globalAntialiasing;
				legs.updateHitbox();
				legs.offset.set(legs.frameWidth / 2, 10);
				if (flipped)
					legs.offset.x -= 25;
				legs.flipX = char.flipX;
				legs.scrollFactor.copyFrom(char.scrollFactor);
				pshaggyLegs.set(char, legs);
				char.associatedSprites.push(legs);

				var shaggyT = new FlxTrail(char, null, 5, 7, 0.3, 0.001);
				shaggyT.scrollFactor.copyFrom(char.scrollFactor);
				addBehindChar(char, shaggyT);
				char.associatedSprites.push(shaggyT);
				var legT = new FlxTrail(legs, null, 5, 7, 0.3, 0.001);
				legT.scrollFactor.copyFrom(char.scrollFactor);
				pshaggyLegT.set(char, legT);
				char.associatedSprites.push(legT);
				addBehindChar(char, legT);
				addBehindChar(char, legs);
		}
		if (group == null)
		{
			for (spr in char.associatedSprites)
			{
				if (Std.isOfType(spr, FlxTrail))
					spr.visible = false;
				else
					spr.alpha = 0.00001;
			}
		}
		char.defaultX = char.x;
		char.defaultY = char.y;
		if (flipped)
			boyfriendMap.set(name, char);
		else
			dadMap.set(name, char);
		return char;
	}

	function addBehindChar(char:Character, obj:FlxObject)
	{
		if (char.flipped)
			addBehindBF(obj);
		else
			addBehindDad(obj);
	}

	function checkPicoSpeaker(char:Character)
	{
		if (char.curCharacter == 'pico-speaker' && ClientPrefs.gameQuality == 'Normal')
		{
			var firstTank:TankmenBG = new TankmenBG(20, 500, true);
			firstTank.resetShit(20, 600, true);
			firstTank.strumTime = 10;
			stage.tankmanRun.add(firstTank);

			for (i in 0...char.animationNotes.length)
			{
				if (FlxG.random.bool(16))
				{
					var tankBih = stage.tankmanRun.recycle(TankmenBG);
					tankBih.strumTime = char.animationNotes[i][0];
					tankBih.resetShit(500, 200 + FlxG.random.int(50, 100), char.animationNotes[i][1] < 2);
					stage.tankmanRun.add(tankBih);
				}
			}
		}
	}

	function updateTimeTxt()
	{
		var txt = songDetails;
		if (updateTime)
		{
			var curTime:Float = Conductor.songPosition - ClientPrefs.noteOffset;
			if (curTime < 0)
				curTime = 0;
			songPercent = (curTime / songLength);

			if (ClientPrefs.timeBarType == 'Percentage Passed')
			{ // geometry dash moment
				txt += '\n' + Math.floor(songPercent * 100) + '%';
			}
			else if (ClientPrefs.timeBarType != 'Song Name')
			{
				var songCalc:Float = (songLength - curTime) / playbackRate;
				if (ClientPrefs.timeBarType == 'Time Elapsed')
					songCalc = curTime / playbackRate;

				var secondsTotal:Int = Math.floor(songCalc / 1000);
				if (secondsTotal < 0)
					secondsTotal = 0;

				txt += '\n' + FlxStringUtil.formatTime(secondsTotal, false);
			}
		}
		timeTxt.text = txt;
	}

	function getUIFile(file:String)
	{
		return SkinData.getUIFile(file, SONG.skinModifier);
	}

	function getNoteFile(file:String)
	{
		return SkinData.getNoteFile(file, SONG.skinModifier);
	}

	function setKeysArray(keys:Int = 4)
	{
		keysArray = [];
		for (i in 0...keys)
		{
			keysArray.push(ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note${keys}_$i')));
		}
	}

	public var skipArrowStartTween:Bool = true;

	private function generateStaticArrows(id:Int = 0, keys:Int = 4, isBoyfriend:Bool = false):Void
	{
		while (id >= strumMaps.length)
			strumMaps.push(new Map());

		var strumX:Float = 0;
		if (isBoyfriend)
			strumX += FlxG.width / 2;

		var strumGroup = new StrumLine(strumX, strumLine.y, keys, !skipArrowStartTween, true);
		strumGroup.botPlay = Main.debug;
		strumGroup.isBoyfriend = isBoyfriend;

		strumMaps[id].set(keys, strumGroup);
	}

	public function reloadHealthBarColors()
	{
		var healthColors = [dad.healthColorArray, boyfriend.healthColorArray];
		if (dadGroupFile != null)
			healthColors[0] = dadGroupFile.healthbar_colors;
		if (bfGroupFile != null)
			healthColors[1] = bfGroupFile.healthbar_colors;
		var match = true;
		for (i in 0...healthColors[0].length)
		{
			if (healthColors[0][i] != healthColors[1][i])
			{
				match = false;
				break;
			}
		}
		if (match)
			healthColors = [[255, 0, 0], [102, 255, 51]];
		healthBar.createFilledBar(FlxColor.fromRGB(healthColors[0][0], healthColors[0][1], healthColors[0][2]),
			FlxColor.fromRGB(healthColors[1][0], healthColors[1][1], healthColors[1][2]));
		healthBar.updateBar();
	}

	public function addCharacterToList(newCharacter:String, type:Int, ?index:Int = 0)
	{
		switch (type)
		{
			case 0:
				if (!boyfriendMap.exists(newCharacter))
				{
					var xOffset = 0.0;
					var yOffset = 0.0;
					if (bfGroupFile != null)
					{
						xOffset = (bfGroupFile.characters[index] != null ? bfGroupFile.characters[index].position[0] : 0) + bfGroupFile.position[0];
						yOffset = (bfGroupFile.characters[index] != null ? bfGroupFile.characters[index].position[1] : 0) + bfGroupFile.position[1];
					}
					var newBoyfriend = addCharacter(newCharacter, index, true, null, xOffset, yOffset);
					boyfriendMap.set(newCharacter, newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					add(newBoyfriend);
				}

			case 1:
				if (!dadMap.exists(newCharacter))
				{
					var xOffset = 0.0;
					var yOffset = 0.0;
					if (dadGroupFile != null)
					{
						xOffset = (dadGroupFile.characters[index] != null ? dadGroupFile.characters[index].position[0] : 0) + dadGroupFile.position[0];
						yOffset = (dadGroupFile.characters[index] != null ? dadGroupFile.characters[index].position[1] : 0) + dadGroupFile.position[1];
					}
					var newDad = addCharacter(newCharacter, index, false, null, xOffset, yOffset);
					dadMap.set(newCharacter, newDad);
					newDad.alpha = 0.00001;
					add(newDad);
				}

			case 2:
				if (!gfMap.exists(newCharacter))
				{
					var xOffset = 0.0;
					var yOffset = 0.0;
					if (gfGroupFile != null)
					{
						xOffset = (gfGroupFile.characters[index] != null ? gfGroupFile.characters[index].position[0] : 0) + gfGroupFile.position[0];
						yOffset = (gfGroupFile.characters[index] != null ? gfGroupFile.characters[index].position[1] : 0) + gfGroupFile.position[1];
					}
					var newGf = addCharacter(newCharacter, index, false, null, xOffset, yOffset, 0.95, 0.95);
					newGf.isGF = true;
					gfMap.set(newCharacter, newGf);
					newGf.alpha = 0.00001;
					add(newGf);
				}
		}
	}

	function eventPushed(event:EventNote)
	{
		switch (event.event)
		{
			case 'Change Character':
			/*var charData:Array<String> = event.value1.split(',');
				var charType:Int = 0;
				var index = 0;
				switch (charData[0].toLowerCase())
				{
					case 'gf' | 'girlfriend' | '2':
						charType = 2;
					case 'dad' | 'opponent' | '1':
						charType = 1;
				}
				if (charData[1] != null)
					index = Std.parseInt(charData[1]);

				var newCharacter:String = event.value2;
				addCharacterToList(newCharacter, charType, index); */

			case 'Dadbattle Spotlight':
				dadbattleBlack = new BGSprite(null, -800, -400, 0, 0);
				dadbattleBlack.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
				dadbattleBlack.alpha = 0.25;
				dadbattleBlack.visible = false;
				stage.foreground.add(dadbattleBlack);

				dadbattleLight = new BGSprite('spotlight', 400, -400);
				dadbattleLight.alpha = 0.375;
				dadbattleLight.blend = ADD;
				dadbattleLight.visible = false;

				dadbattleSmokes = new FlxSpriteGroup();
				dadbattleSmokes.alpha = 0.7;
				dadbattleSmokes.blend = ADD;
				dadbattleSmokes.visible = false;
				stage.foreground.add(dadbattleLight);
				stage.foreground.add(dadbattleSmokes);

				var offsetX = 200;
				var smoke:BGSprite = new BGSprite('smoke', -1550 + offsetX, 660 + FlxG.random.float(-20, 20), 1.2, 1.05);
				smoke.setGraphicSize(Std.int(smoke.width * FlxG.random.float(1.1, 1.22)));
				smoke.updateHitbox();
				smoke.velocity.x = FlxG.random.float(15, 22);
				smoke.active = true;
				dadbattleSmokes.add(smoke);
				var smoke:BGSprite = new BGSprite('smoke', 1550 + offsetX, 660 + FlxG.random.float(-20, 20), 1.2, 1.05);
				smoke.setGraphicSize(Std.int(smoke.width * FlxG.random.float(1.1, 1.22)));
				smoke.updateHitbox();
				smoke.velocity.x = FlxG.random.float(-15, -22);
				smoke.active = true;
				smoke.flipX = true;
				dadbattleSmokes.add(smoke);

			case 'Philly Glow':
				if (curStage == 'philly' && ClientPrefs.gameQuality != 'Crappy')
				{
					blammedLightsBlack = new FlxSprite(FlxG.width * -0.5,
						FlxG.height * -0.5).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
					blammedLightsBlack.visible = false;
					stage.background.insert(stage.background.members.indexOf(stage.phillyStreet), blammedLightsBlack);

					phillyWindowEvent = new BGSprite('philly/window', stage.phillyWindow.x, stage.phillyWindow.y, 0.3, 0.3);
					phillyWindowEvent.setGraphicSize(Std.int(phillyWindowEvent.width * 0.85));
					phillyWindowEvent.updateHitbox();
					phillyWindowEvent.visible = false;
					stage.background.insert(stage.background.members.indexOf(blammedLightsBlack) + 1, phillyWindowEvent);

					phillyGlowGradient = new PhillyGlow.PhillyGlowGradient(-400, 225); // This shit was refusing to properly load FlxGradient so fuck it
					phillyGlowGradient.visible = false;
					stage.background.insert(stage.background.members.indexOf(blammedLightsBlack) + 1, phillyGlowGradient);
					if (!ClientPrefs.flashing)
						phillyGlowGradient.intendedAlpha = 0.7;

					cacheImage('philly/particle'); // precache particle image
					phillyGlowParticles = new FlxTypedGroup<PhillyGlow.PhillyGlowParticle>();
					phillyGlowParticles.visible = false;
					stage.background.insert(stage.background.members.indexOf(phillyGlowGradient) + 1, phillyGlowParticles);
				}
		}
	}

	function eventNoteEarlyTrigger(event:EventNote):Float
	{
		switch (event.event)
		{
			case 'Kill Henchmen': // Better timing so that the kill sound matches the beat intended
				return 280; // Plays 280ms before the actual position
		}
		return 0;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	function sortByTime(Obj1:EventNote, Obj2:EventNote):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	function sortByOrder(wat:Int, Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.zIndex, Obj2.zIndex);
	}

	function sortByZ(wat:Int, Obj1:FNFSprite, Obj2:FNFSprite):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.z, Obj2.z);
	}

	public function checkEventNote()
	{
		while (eventNotes.length > 0)
		{
			var leStrumTime:Float = eventNotes[0].strumTime;
			if (Conductor.songPosition < leStrumTime)
			{
				break;
			}

			var value1:String = '';
			if (eventNotes[0].value1 != null)
				value1 = eventNotes[0].value1;

			var value2:String = '';
			if (eventNotes[0].value2 != null)
				value2 = eventNotes[0].value2;

			triggerEventNote(eventNotes[0].event, value1, value2);
			eventNotes.shift();
		}
	}

	public function triggerEventNote(eventName:String, value1:String, value2:String)
	{
		switch (eventName)
		{
			case 'Dadbattle Spotlight':
				var val:Null<Int> = Std.parseInt(value1);
				if (val == null)
					val = 0;

				switch (Std.parseInt(value1))
				{
					case 1, 2, 3: // enable and target dad
						if (val == 1) // enable
						{
							dadbattleBlack.visible = true;
							dadbattleLight.visible = true;
							dadbattleSmokes.visible = true;
							defaultCamZoom += 0.12;
						}

						var who:Character = dad;
						if (val > 2)
							who = boyfriend;
						// 2 only targets dad
						dadbattleLight.alpha = 0;
						new FlxTimer(timerManager).start(0.12, function(tmr:FlxTimer)
						{
							dadbattleLight.alpha = 0.375;
						});
						dadbattleLight.setPosition(who.getMidpoint().x - dadbattleLight.width / 2, who.y + who.height - dadbattleLight.height + 50);

					default:
						dadbattleBlack.visible = false;
						dadbattleLight.visible = false;
						defaultCamZoom -= 0.12;
						tweenManager.tween(dadbattleSmokes, {alpha: 0}, 1, {
							onComplete: function(twn:FlxTween)
							{
								dadbattleSmokes.visible = false;
							}
						});
				}

			case 'Hey!':
				var value:Int = 2;
				switch (value1.toLowerCase().trim())
				{
					case 'bf' | 'boyfriend' | '0':
						value = 0;
					case 'gf' | 'girlfriend' | '1':
						value = 1;
				}

				var time:Float = Std.parseFloat(value2);
				if (Math.isNaN(time) || time <= 0)
					time = 0.6;

				if (value != 0)
				{
					for (dad in dadGroup)
					{
						if (dad.curCharacter.startsWith('gf') && dad.animation.exists('cheer'))
						{ // Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
							dad.playAnim('cheer', true);
							dad.specialAnim = true;
							dad.heyTimer = time;
						}
					}

					for (gf in gfGroup)
					{
						if (gf.animation.exists('cheer'))
						{
							gf.playAnim('cheer', true);
							gf.specialAnim = true;
							gf.heyTimer = time;
						}
					}
				}
				if (value != 1)
				{
					for (boyfriend in boyfriendGroup)
					{
						if (boyfriend.animation.exists('hey'))
						{
							boyfriend.playAnim('hey', true);
							boyfriend.specialAnim = true;
							boyfriend.heyTimer = time;
						}
					}
				}

			case 'Set GF Speed':
				var value:Int = Std.parseInt(value1);
				if (Math.isNaN(value))
					value = 1;
				if (value < 0)
					value = 0;
				for (gf in gfGroup)
				{
					gf.danceEveryNumBeats = value;
				}

			case 'Philly Glow':
				if (curStage == 'philly' && ClientPrefs.gameQuality != 'Crappy')
				{
					var lightId:Int = Std.parseInt(value1);
					if (Math.isNaN(lightId))
						lightId = 0;

					var doFlash:Void->Void = function()
					{
						var color:FlxColor = FlxColor.WHITE;
						if (!ClientPrefs.flashing)
							color.alphaFloat = 0.5;

						for (camera in camGames)
							camera.flash(color, 0.15, null, true);
					};

					var chars = [boyfriendGroup, gfGroup, dadGroup];
					switch (lightId)
					{
						case 0:
							if (phillyGlowGradient.visible)
							{
								doFlash();
								if (ClientPrefs.camZooms)
								{
									for (camera in camGames)
										camera.zoom += 0.5;
									camHUD.zoom += 0.1;
								}

								blammedLightsBlack.visible = false;
								phillyWindowEvent.visible = false;
								phillyGlowGradient.visible = false;
								phillyGlowParticles.visible = false;
								curLightEvent = -1;

								for (charGroup in chars)
								{
									for (who in charGroup)
									{
										who.color = FlxColor.WHITE;
									}
								}
								stage.phillyStreet.color = FlxColor.WHITE;
							}

						case 1: // turn on
							curLightEvent = FlxG.random.int(0, stage.phillyLightsColors.length - 1, [curLightEvent]);
							var color:FlxColor = stage.phillyLightsColors[curLightEvent];

							if (!phillyGlowGradient.visible)
							{
								doFlash();
								if (ClientPrefs.camZooms)
								{
									for (camera in camGames)
										camera.zoom += 0.5;
									camHUD.zoom += 0.1;
								}

								blammedLightsBlack.visible = true;
								blammedLightsBlack.alpha = 1;
								phillyWindowEvent.visible = true;
								phillyGlowGradient.visible = true;
								phillyGlowParticles.visible = true;
							}
							else if (ClientPrefs.flashing)
							{
								var colorButLower:FlxColor = color;
								colorButLower.alphaFloat = 0.25;
								for (camera in camGames)
									camera.flash(colorButLower, 0.5, null, true);
							}

							var charColor:FlxColor = color;
							if (!ClientPrefs.flashing)
								charColor.saturation *= 0.5;
							else
								charColor.saturation *= 0.75;

							for (charGroup in chars)
							{
								for (who in charGroup)
								{
									who.color = charColor;
								}
							}
							phillyGlowParticles.forEachAlive(function(particle:PhillyGlow.PhillyGlowParticle)
							{
								particle.color = color;
							});
							phillyGlowGradient.color = color;
							phillyWindowEvent.color = color;

							color.brightness *= 0.5;
							stage.phillyStreet.color = color;

						case 2: // spawn particles
							if (ClientPrefs.gameQuality == 'Normal')
							{
								var particlesNum:Int = FlxG.random.int(8, 12);
								var width:Float = (2000 / particlesNum);
								var color:FlxColor = stage.phillyLightsColors[curLightEvent];
								for (j in 0...3)
								{
									for (i in 0...particlesNum)
									{
										var particle:PhillyGlow.PhillyGlowParticle = new PhillyGlow.PhillyGlowParticle(-400
											+ width * i
											+ FlxG.random.float(-width / 5, width / 5),
											phillyGlowGradient.originalY
											+ 200
											+ (FlxG.random.float(0, 125) + j * 40), color);
										phillyGlowParticles.add(particle);
									}
								}
							}
							phillyGlowGradient.bop();
					}
				}

			case 'Kill Henchmen':
				stage.killHenchmen();

			case 'Add Camera Zoom':
				if (ClientPrefs.camZooms)
				{
					var camZoom:Float = Std.parseFloat(value1);
					var hudZoom:Float = Std.parseFloat(value2);
					if (Math.isNaN(camZoom))
						camZoom = 0.015;
					if (Math.isNaN(hudZoom))
						hudZoom = 0.03;

					for (camera in camGames)
					{
						if (camera.zoom < 1.35)
							camera.zoom += camZoom;
					}
					camHUD.zoom += hudZoom;
				}

			case 'Play Animation':
				var charGroup = dadGroup;
				var index = 0;
				var charData = value2.split(',');
				switch (charData[0].toLowerCase().trim())
				{
					case 'bf' | 'boyfriend' | '1':
						charGroup = boyfriendGroup;
					case 'gf' | 'girlfriend' | '2':
						charGroup = gfGroup;
				}
				if (charData[1] != null)
					index = Std.parseInt(charData[1]);
				if (charGroup.members[index % charGroup.length] != null
					&& charGroup.members[index % charGroup.length].animation.exists(value1))
				{
					charGroup.members[index % charGroup.length].playAnim(value1, true);
					charGroup.members[index % charGroup.length].specialAnim = true;
				}

			case 'Alt Idle Animation':
				var charGroup = dadGroup;
				var index = 0;
				var charData = value1.split(',');
				switch (charData[0].toLowerCase().trim())
				{
					case 'bf' | 'boyfriend' | '1':
						charGroup = boyfriendGroup;
					case 'gf' | 'girlfriend' | '2':
						charGroup = gfGroup;
				}
				if (charData[1] != null)
					index = Std.parseInt(charData[1]);
				if (charGroup.members[index % charGroup.length] != null)
				{
					charGroup.members[index % charGroup.length].idleSuffix = value2;
					charGroup.members[index % charGroup.length].recalculateDanceIdle();
				}

			case 'Screen Shake':
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FlxCamera> = [FlxG.camera, camHUD];
				for (i in 0...targetsArray.length)
				{
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = 0;
					var intensity:Float = 0;
					if (split[0] != null)
						duration = Std.parseFloat(split[0].trim());
					if (split[1] != null)
						intensity = Std.parseFloat(split[1].trim());
					if (Math.isNaN(duration))
						duration = 0;
					if (Math.isNaN(intensity))
						intensity = 0;

					if (duration > 0 && intensity != 0)
					{
						if (i == 0)
						{
							for (camera in camGames)
								camera.shake(intensity, duration);
						}
						else
							targetsArray[i].shake(intensity, duration);
					}
				}

			case 'Change Character':
			/*var charType:Int = 0;
				var index = 0;
				var charData = value1.split(',');
				switch (charData[0].toLowerCase().trim())
				{
					case 'gf' | 'girlfriend' | '2':
						charType = 2;
					case 'dad' | 'opponent' | '1':
						charType = 1;
				}
				if (charData[1] != null)
					index = Std.parseInt(charData[1]);

				switch (charType)
				{
					case 0:
						index %= boyfriendGroup.length;
						if (boyfriendGroup.members[index].curCharacter != value2)
						{
							if (!boyfriendMap.exists(value2))
								addCharacterToList(value2, charType, index);

							var lastAlpha:Float = boyfriendGroup.members[index].alpha;
							boyfriendGroup.members[index].alpha = 0.00001;
							for (spr in boyfriendGroup.members[index].associatedSprites)
								spr.visible = false;
							boyfriendGroup.remove(boyfriendGroup.members[index], true);
							remove(boyfriendMap.get(value2));
							boyfriendGroup.insert(index, boyfriendMap.get(value2));
							if (boyfriendGroup.members[index].addedToGroup)
							{
								boyfriendGroup.members[index].x -= boyfriendGroup.x;
								boyfriendGroup.members[index].y -= boyfriendGroup.y;
							}
							else
							{
								boyfriendGroup.members[index].defaultX = boyfriendGroup.members[index].x;
								boyfriendGroup.members[index].defaultY = boyfriendGroup.members[index].y;
							}
							boyfriendGroup.members[index].addedToGroup = true;
							boyfriendGroup.members[index].alpha = lastAlpha;
							boyfriendGroup.members[index].dance();
							for (spr in boyfriendGroup.members[index].associatedSprites)
								spr.visible = true;
							if (boyfriendGroup.members.length == 1)
								iconP1.changeIcon(boyfriend.healthIcon);
							reloadHealthBarColors();
						}

					case 1:
						index %= dadGroup.length;
						if (dadGroup.members[index].curCharacter != value2)
						{
							if (!dadMap.exists(value2))
								addCharacterToList(value2, charType, index);

							var wasGf:Bool = dadGroup.members[index].curCharacter.startsWith('gf');
							var lastAlpha:Float = dadGroup.members[index].alpha;
							dadGroup.members[index].alpha = 0.00001;
							for (spr in dadGroup.members[index].associatedSprites)
								spr.visible = false;
							dadGroup.remove(dadGroup.members[index], true);
							remove(dadMap.get(value2));
							dadGroup.insert(index, dadMap.get(value2));
							if (dadGroup.members[index].addedToGroup)
							{
								dadGroup.members[index].x -= dadGroup.x;
								dadGroup.members[index].y -= dadGroup.y;
							}
							else
							{
								dadGroup.members[index].defaultX = dadGroup.members[index].x;
								dadGroup.members[index].defaultY = dadGroup.members[index].y;
							}
							dadGroup.members[index].addedToGroup = true;
							if (gf != null)
							{
								if (!dadGroup.members[index].curCharacter.startsWith('gf'))
								{
									if (wasGf)
										gf.visible = true;
								}
								else
									gf.visible = false;
							}
							dadGroup.members[index].alpha = lastAlpha;
							dadGroup.members[index].dance();
							for (spr in dadGroup.members[index].associatedSprites)
								spr.visible = true;
							if (dadGroup.members.length == 1)
								iconP2.changeIcon(dad.healthIcon);
							reloadHealthBarColors();
						}

					case 2:
						if (gf != null)
						{
							index %= gfGroup.length;
							if (gfGroup.members[index].curCharacter != value2)
							{
								if (!gfMap.exists(value2))
									addCharacterToList(value2, charType, index);

								var lastAlpha:Float = gfGroup.members[index].alpha;
								gfGroup.members[index].alpha = 0.00001;
								for (spr in dadGroup.members[index].associatedSprites)
									spr.visible = false;
								gfGroup.remove(gfGroup.members[index], true);
								remove(gfMap.get(value2));
								gfGroup.insert(index, gfMap.get(value2));
								if (gfGroup.members[index].addedToGroup)
								{
									gfGroup.members[index].x -= gfGroup.x;
									gfGroup.members[index].y -= gfGroup.y;
								}
								else
								{
									gfGroup.members[index].defaultX = dadGroup.members[index].x;
									gfGroup.members[index].defaultY = dadGroup.members[index].y;
								}
								gfGroup.members[index].addedToGroup = true;
								gfGroup.members[index].alpha = lastAlpha;
								gfGroup.members[index].dance();
								for (spr in gfGroup.members[index].associatedSprites)
									spr.visible = true;
							}
						}
			}*/

			case 'Change Scroll Speed':
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if (Math.isNaN(val1))
					val1 = 1;
				if (Math.isNaN(val2))
					val2 = 0;

				var newValue:Float = SONG.speed * val1;
				newValue = CoolUtil.boundTo(newValue, 0.1, 3.5);

				if (val2 <= 0)
					songSpeed = newValue;
				else
				{
					songSpeedTween = tweenManager.tween(this, {songSpeed: newValue}, val2, {
						onComplete: function(twn:FlxTween)
						{
							songSpeedTween = null;
						}
					});
				}

			case 'Set Property':
				var killMe:Array<String> = value1.split('.');
				if (killMe.length > 1)
					CoolUtil.setVarInArray(CoolUtil.getPropertyLoopThingWhatever(killMe, true, true), killMe[killMe.length - 1], value2);
				else
					CoolUtil.setVarInArray(this, value1, value2);
		}
		stage.onEvent(eventName, value1, value2);
	}

	function updateCameras():Void
	{
		if (doubleCamMode)
		{
			camFollow[0].set(CoolUtil.getCamFollowCharacter(dad).x, CoolUtil.getCamFollowCharacter(dad).y);

			if (dadGroupFile != null)
			{
				camFollow[0].x += dadGroupFile.camera_position[0];
				camFollow[0].y += dadGroupFile.camera_position[1];
			}
			else
			{
				camFollow[0].x += dad.cameraPosition[0];
				camFollow[0].y += dad.cameraPosition[1];
			}

			camFollow[0].x += dadCamX;
			camFollow[0].y += dadCamY;

			camFollow[1].set(CoolUtil.getCamFollowCharacter(boyfriend).x, CoolUtil.getCamFollowCharacter(boyfriend).y);

			if (bfGroupFile != null)
			{
				camFollow[1].x += bfGroupFile.camera_position[0];
				camFollow[1].y += bfGroupFile.camera_position[1];
			}
			else
			{
				camFollow[1].x += boyfriend.cameraPosition[0];
				camFollow[1].y += boyfriend.cameraPosition[1];
			}

			camFollow[1].x += boyfriendCamX;
			camFollow[1].y += boyfriendCamY;

			if (gf != null && gf.visible)
			{
				camGames[2].visible = true;
				camBorder.visible = true;
				camFollow[2].set(CoolUtil.getCamFollowCharacter(gf).x, CoolUtil.getCamFollowCharacter(gf).y);
				if (gfGroupFile != null)
				{
					camFollow[2].x += gfGroupFile.camera_position[0];
					camFollow[2].y += gfGroupFile.camera_position[1];
				}
				else
				{
					camFollow[2].x += gf.cameraPosition[0];
					camFollow[2].y += gf.cameraPosition[1];
				}

				camFollow[2].x += gfCamX;
				camFollow[2].y += gfCamY;
			}
			else
			{
				camGames[2].visible = false;
				camBorder.visible = false;
			}
		}
		else
		{
			if (SONG.notes[curSection] == null)
				return;

			if (gf != null && SONG.notes[curSection].gfSection)
			{
				camFollow[0].set(CoolUtil.getCamFollowCharacter(gf).x, CoolUtil.getCamFollowCharacter(gf).y);
				if (gfGroupFile != null)
				{
					camFollow[0].x += gfGroupFile.camera_position[0] + girlfriendCameraOffset[0];
					camFollow[0].y += gfGroupFile.camera_position[1] + girlfriendCameraOffset[1];
				}
				else
				{
					camFollow[0].x += gf.cameraPosition[0] + girlfriendCameraOffset[0];
					camFollow[0].y += gf.cameraPosition[1] + girlfriendCameraOffset[1];
				}
				camFollow[0].x += gfCamX;
				camFollow[0].y += gfCamY;
				return;
			}

			moveCamera(!SONG.notes[curSection].mustHitSection);
		}
	}

	var cameraTwn:FlxTween;

	public function moveCamera(isDad:Bool)
	{
		if (isDad)
		{
			camFollow[0].set(CoolUtil.getCamFollowCharacter(dad).x, CoolUtil.getCamFollowCharacter(dad).y);

			if (dadGroupFile != null)
			{
				camFollow[0].x += dadGroupFile.camera_position[0] + opponentCameraOffset[0];
				camFollow[0].y += dadGroupFile.camera_position[1] + opponentCameraOffset[1];
			}
			else
			{
				camFollow[0].x += dad.cameraPosition[0] + opponentCameraOffset[0];
				camFollow[0].y += dad.cameraPosition[1] + opponentCameraOffset[1];
			}

			camFollow[0].x += dadCamX;
			camFollow[0].y += dadCamY;
		}
		else
		{
			camFollow[0].set(CoolUtil.getCamFollowCharacter(boyfriend).x, CoolUtil.getCamFollowCharacter(boyfriend).y);

			if (bfGroupFile != null)
			{
				camFollow[0].x += bfGroupFile.camera_position[0] + boyfriendCameraOffset[0];
				camFollow[0].y += bfGroupFile.camera_position[1] + boyfriendCameraOffset[1];
			}
			else
			{
				camFollow[0].x += boyfriend.cameraPosition[0] + boyfriendCameraOffset[0];
				camFollow[0].y += boyfriend.cameraPosition[1] + boyfriendCameraOffset[1];
			}

			camFollow[0].x += boyfriendCamX;
			camFollow[0].y += boyfriendCamY;
		}
	}

	function tweenCamIn(id:Int = 0)
	{
		if (cameraTwn == null)
		{
			cameraTwn = tweenManager.tween(camGames[id], {zoom: 1.3}, (Conductor.normalizedCrochet / 1000), {
				ease: FlxEase.elasticInOut,
				onComplete: function(twn:FlxTween)
				{
					cameraTwn = null;
				}
			});
		}
	}

	function snapCamFollowToPos(id:Int, x:Float, y:Float)
	{
		camFollow[id].set(x, y);
		camFollowPos[id].setPosition(x, y);
	}

	public function recalculateRating(badHit:Bool = false, id:Int = 0)
	{
		if (totalPlayed[id] < 1) // Prevent divide by 0
			ratingName[id] = '?';
		else
		{
			// Rating Percent
			ratingPercent[id] = Math.min(1, Math.max(0, totalNotesHit[id] / totalPlayed[id]));

			// Rating Name
			if (ratingPercent[id] >= 1)
			{
				ratingName[id] = ratingStuff[ratingStuff.length - 1][0]; // Uses last string
			}
			else
			{
				for (i in 0...ratingStuff.length - 1)
				{
					if (ratingPercent[id] < ratingStuff[i][1])
					{
						ratingName[id] = ratingStuff[i][0];
						break;
					}
				}
			}
		}

		// Rating FC
		ratingFC[id] = "";
		if (sicks[id] > 0)
			ratingFC[id] = "SFC";
		if (goods[id] > 0)
			ratingFC[id] = "GFC";
		if (bads[id] > 0 || shits[id] > 0)
			ratingFC[id] = "FC";
		if (songMisses[id] > 0 && songMisses[id] < 10)
			ratingFC[id] = "SDCB";
		else if (songMisses[id] >= 10)
			ratingFC[id] = "Clear";
		updateScore(badHit, id); // score will only update after rating is calculated, if it's a badHit, it shouldn't bounce -Ghost
	}

	public function updateScore(miss:Bool = false, id:Int = 0)
	{
		var txt = 'Score: ' + Math.round(songScore[id]) + ' | ' + 'Combo: ' + combo[id] + ' | ';

		if (ClientPrefs.showRatings)
			txt += 'Rating: ' + ratingName[id];
		else
			txt += 'Fails: ' + songMisses[id] + ' | Rating: ' + ratingName[id];

		if (ratingName[id] != '?')
			txt += ' [${CoolUtil.floorDecimal(ratingPercent[id] * 100, 2)}% | ${ratingFC[id]}]';

		if (ClientPrefs.scoreZoom && !miss)
		{
			if (scoreTxtTween[id] != null)
				scoreTxtTween[id].cancel();
			scoreTxt[id].scale.x = 1.01875;
			scoreTxt[id].scale.y = 1.01875;
			scoreTxtTween[id] = tweenManager.tween(scoreTxt[id].scale, {x: 1, y: 1}, 0.2, {
				onComplete: function(twn:FlxTween)
				{
					scoreTxtTween[id] = null;
				}
			});
		}

		scoreTxt[id].text = txt;
	}

	private function cachePopUpScore()
	{
		for (rating in ratingsData)
			cacheImage(getUIFile(rating.image));
	}

	private function popUpScore(note:Note = null, id:Int = 0):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.ratingOffset);

		var strumGroup = strumLineNotes.members[id];
		var strum = strumGroup.getReceptor(strumGroup.keys - 1);

		var rating:FlxSprite = grpRatings.recycle(FlxSprite);
		rating.setPosition(strum.x + strum.width, strum.y);
		var score:Int = 350;

		// tryna do MS based judgment due to popular demand
		var daRating = Conductor.judgeNote(note, noteDiff);
		if (strumLineNotes.members[id].botPlay)
			daRating = ratingsData[0];
		var ratingNum = ratingsData.indexOf(daRating);

		totalNotesHit[id] += daRating.ratingMod;
		note.ratingMod = daRating.ratingMod;
		if (!note.ratingDisabled)
			daRating.increase(1, id);
		note.rating = daRating.name;
		score = daRating.score;

		if (daRating.noteSplash && !note.noteSplashDisabled)
		{
			spawnNoteSplashOnNote(note, strumLineNotes.members[id]);
		}

		if (!daRating.causesMiss)
		{
			songScore[id] += score * (note.isOpponent ? dadScoreMult : boyfriendScoreMult);
			if (!note.ratingDisabled)
			{
				totalPlayed[id]++;
				recalculateRating(false, id);
				doRatingTween(ratingNum, id);
			}
		}
		else
		{
			noteMispress(note.noteData, id);
		}

		rating.scale.set(1, 1);
		rating.velocity.set(0, 0);
		rating.alpha = 1;
		rating.loadGraphic(Paths.image(getUIFile(daRating.image)));
		rating.acceleration.y = 550;
		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.velocity.x -= FlxG.random.int(0, 10);
		rating.visible = !ClientPrefs.hideHud && showRating;
		rating.scrollFactor.set();

		grpRatings.add(rating);

		if (!SONG.skinModifier.endsWith('pixel'))
		{
			rating.setGraphicSize(Std.int(rating.width * 0.7));
			rating.antialiasing = ClientPrefs.globalAntialiasing;
		}
		else
			rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.85));
		
		rating.updateHitbox();

		rating.x = ((FlxG.width / 2) - rating.width) / 2;
		if (id > 0)
			rating.x += FlxG.width / 2;
		rating.screenCenter(Y);

		tweenManager.tween(rating, {alpha: 0}, 0.2, {
			onComplete: function(tween:FlxTween)
			{
				rating.kill();
			},
			startDelay: Conductor.normalizedCrochet * 0.001
		});
	}

	function doRatingTween(ind:Int = 0, id:Int = 0)
	{
		if (ClientPrefs.scoreZoom)
		{
			if (ratingTxtTweens[id][ind] != null)
			{
				ratingTxtTweens[id][ind].cancel();
			}
			ratingTxtGroup[id].members[ind].scale.x = 1.02;
			ratingTxtGroup[id].members[ind].scale.y = 1.02;
			ratingTxtTweens[id][ind] = tweenManager.tween(ratingTxtGroup[id].members[ind].scale, {x: 1, y: 1}, 0.2, {
				onComplete: function(twn:FlxTween)
				{
					ratingTxtTweens[id][ind] = null;
				}
			});
		}
	}

	function groupFromPlayer(player:Int)
	{
		switch (MultiControls.playerPosition(player))
		{
			case 1:
				return boyfriendGroup;
			default:
				return dadGroup;
		}
	}

	function strumLineFromPlayer(player:Int)
	{
		return strumLineNotes.members[MultiControls.playerPosition(player)];
	}

	function mapVelocityChanges()
	{
		if (sliderVelocities.length < 1)
			return;

		var pos:Float = sliderVelocities[0].startTime * (SONG.initialSpeed);
		velocityMarkers.push(pos);
		for (i in 1...sliderVelocities.length)
		{
			pos += (sliderVelocities[i].startTime - sliderVelocities[i - 1].startTime) * (SONG.initialSpeed * sliderVelocities[i - 1].multiplier);
			velocityMarkers.push(pos);
		}
	}

	public static  function getPosFromTime(strumTime:Float, multSpeed:Float = 1):Float
	{
		if (sliderVelocities.length < 1)
			return strumTime * SONG.initialSpeed * multSpeed;

		var idx:Int = 0;
		while (idx < sliderVelocities.length)
		{
			if (strumTime < sliderVelocities[idx].startTime)
				break;
			idx++;
		}
		return getPosFromTimeSV(strumTime, idx, multSpeed);
	}

	public static function getPosFromTimeSV(strumTime:Float, svIdx:Int = 0, multSpeed:Float = 1):Float
	{
		if (sliderVelocities.length < 1 || svIdx == 0)
			return strumTime * SONG.initialSpeed * multSpeed;

		svIdx--;
		var curPos = velocityMarkers[svIdx];
		curPos += ((strumTime - sliderVelocities[svIdx].startTime) * (SONG.initialSpeed * sliderVelocities[svIdx].multiplier * multSpeed));
		return curPos;
	}

	function updatePositions()
	{
		if (startingSong)
		{
			if (startedCountdown)
			{
				Conductor.songPosition += FlxG.elapsed * 1000;
				if (Conductor.songPosition >= 0)
					startSong();
			}
		}
		else
		{
			if (!endingSong)
				Conductor.songPosition += FlxG.elapsed * 1000;
		}
		Conductor.currentTrackPos = getPosFromTime(Conductor.songPosition);
	}

	public static function getFNFSpeed(strumTime:Float, multSpeed:Float = 1):Float
	{
		if (sliderVelocities == null || sliderVelocities.length < 1)
			return instance.songSpeed * multSpeed;

		var idx:Int = 0;
		while (idx < sliderVelocities.length)
		{
			if (strumTime < sliderVelocities[idx].startTime)
				break;
			idx++;
		}
		idx--;
		if (idx <= 0)
			return instance.songSpeed * multSpeed;

		return instance.songSpeed * sliderVelocities[idx].multiplier * multSpeed;
	}
	
	var hidden:Float = 0;
	var hiddenOffset:Float = 0;
	var sudden:Float = 0;
	var suddenOffset:Float = 0;
	var flashR:Float = 0;
	var flashG:Float = 0;
	var flashB:Float = 0;
	public static var fadeDistY = 120;
	function updateNoteAlpha(note:Note) {
		var alpha:Float = 0;
		var yPos:Float = (note.initialPos - Conductor.currentTrackPos) + 50;

		if (hidden != 0) {
			var hiddenAdjust = CoolUtil.boundTo(FlxMath.remapToRange(yPos, getHiddenStart(), getHiddenEnd(), 0, -1), -1, 0);
			alpha += hidden * hiddenAdjust;
		}

		if (sudden != 0) {
			var suddenAdjust = CoolUtil.boundTo(FlxMath.remapToRange(yPos, getSuddenStart(), getSuddenEnd(), 0, -1), -1, 0);
     		alpha += sudden * suddenAdjust;
		}

		alpha = CoolUtil.boundTo(alpha + 1, 0, 1);
		note.alpha *= (alpha >= 0.5 ? 1 : 0);

    	var glow = FlxMath.remapToRange(Math.abs(alpha - 0.5), 0, 0.5, 1.3, 0);
		var flashColor = FlxColor.fromRGB(Std.int(flashR), Std.int(flashG), Std.int(flashB));
		note.effect.setFlashColor(flashColor);
		note.effect.setFlash(glow);
	}

	var modAlpha:Array<Float> = [0, 0];
	function updateReceptorAlpha(note:StrumNote, player:Int = 0) {
		note.alpha = 1 - modAlpha[player];
	}

	public function getHiddenEnd()
	{
		return(FlxG.height / 2)
			+ fadeDistY * FlxMath.remapToRange(getHiddenSudden(), 0, 1, -1, -1.25)
		+ (FlxG.height / 2) * hiddenOffset;
	}

	public function getHiddenStart()
	{
		return (FlxG.height / 2)
			+ fadeDistY * FlxMath.remapToRange(getHiddenSudden(), 0, 1, 0, -0.25)
			+ (FlxG.height / 2) * hiddenOffset;
	}

	public function getSuddenEnd()
	{
		return (FlxG.height / 2)
			+ fadeDistY * FlxMath.remapToRange(getHiddenSudden(), 0, 1, 1, 1.25)
			+ (FlxG.height / 2) * suddenOffset;
	}

	public function getSuddenStart()
	{
		return (FlxG.height / 2)
			+ fadeDistY * FlxMath.remapToRange(getHiddenSudden(), 0, 1, 0, 0.25)
			+ (FlxG.height / 2) * suddenOffset;
	}

	public function getHiddenSudden()
	{
		return hidden * sudden;
	}

	var reverse:Float = 0;
	function getReversePercent()
	{
		var percent:Float = 0;
		percent += reverse;

		if (percent > 2)
			percent %= 2;

		if (percent > 1)
			percent = FlxMath.remapToRange(percent, 1, 2, 1, 0);

		if (ClientPrefs.downScroll)
			percent = 1 - percent;

		return percent;
	}

	function updateNotePath(note:Note) {
		var perc = getReversePercent();
		var mult = FlxMath.remapToRange(perc, 0, 1, 1, -1);

		note.distance *= mult;
	}

	function updateNoteScale(note:Note) {
		note.scale.copyFrom(note.defaultScale);
		note.scale.scale(1 / note.z);
		note.updateHitbox();
	}

	var confusion:Array<Float> = [0, 0];
	var confusionNotes:Array<Array<Float>> = [[0, 0, 0, 0], [0, 0, 0, 0]];
	function updateReceptorAngle(note:StrumNote, player:Int = 0) {
		note.angle = confusion[player] + confusionNotes[player][note.noteData];
	}

	var transformX:Float = 0;
	var transformXNotes:Array<Array<Float>> = [[0, 0, 0, 0], [0, 0, 0, 0]];
	var transformY:Float = 0;
	var transformYNotes:Array<Array<Float>> = [[0, 0, 0, 0], [0, 0, 0, 0]];
	var transformZ:Float = 0;
	var transformZNotes:Array<Array<Float>> = [[0, 0, 0, 0], [0, 0, 0, 0]];
	var opponentSwap:Array<Float> = [0, 0];
	var flip:Array<Float> = [0, 0];
	var invert:Array<Float> = [0, 0];
	var drunk:Float = 0;
	var drunkSpeed:Float = 0;
	var tipsy:Float = 0;
	var tipsySpeed:Float = 0;
	function updateReceptorPath(note:StrumNote, player:Int = 0) {
		note.x = note.defaultX;
		note.z = 0;

		var perc = getReversePercent();
		var shift = FlxMath.remapToRange(perc, 0, 1, 50, 558);
		note.y = shift;

		var strumLine = strumLineNotes.members[player];
		var time = Conductor.songPosition / 1000;

		if (opponentSwap[player] != 0) {
			var nPlayer = 1 - player;
			var oppX = strumLineNotes.members[nPlayer].getReceptor(note.noteData).defaultX;
			var plrX = note.defaultX;
			var distX = oppX - plrX;
			note.x += distX * opponentSwap[player];
		}

		if (flip[player] != 0) {
			var distance = Note.swagWidth * (strumLine.receptors.length / 2) * (1.5 - note.noteData);
   			note.x += distance * flip[player];
		}

		if (invert[player] != 0) {
			var distance = Note.swagWidth * ((note.noteData % 2 == 0) ? 1 : -1);
			note.x += distance * invert[player];
		}

		if (tipsy != 0) {
			var tipsySpeed = FlxMath.remapToRange(tipsySpeed, 0, 1, 1, 2);
			note.y += tipsy * (FlxMath.fastCos((time * 1.2 + note.noteData * 1.8) * tipsySpeed) * Note.swagWidth * 0.4);
		}

		if (drunk != 0) {
			var drunkSpeed = FlxMath.remapToRange(drunkSpeed, 0, 1, 1, 2);
			note.x += drunk * (FlxMath.fastCos((time + note.noteData * 0.2 * 10 / FlxG.height) * drunkSpeed) * Note.swagWidth * 0.5);
		}

		note.x += transformX + transformXNotes[player][note.noteData];
		note.y += transformY + transformYNotes[player][note.noteData];
		note.z += transformZ + transformZNotes[player][note.noteData];

		var oX = note.x - (FlxG.width / 2);
		var oY = note.y - (FlxG.height / 2);
		var shit = note.z - 1;
		if (shit > 0) shit = 0;
		var ta = fastTan(Math.PI / 4);
		var x = oX / ta;
		var y = oY / ta;
		var z = (-1 * shit);
		note.x = (x / z) + (FlxG.width / 2);
		note.y = (y / z) + (FlxG.height / 2);
		note.z = z;
	}

	function updateReceptorScale(note:StrumNote, player:Int = 0) {
		note.scale.copyFrom(note.defaultScale);
		note.scale.scale(1 / note.z);
	}

	function introPart(step:Int) {
		var stepAdd = 20;
		new FlxTimer(timerManager).start((Conductor.stepCrochet * stepAdd) / 1000, function(_) {
			confusion[0] = confusion[1] = 360;
			tweenArrayNum(confusion, 0, 0, (Conductor.stepCrochet * 6) / 1000, {ease: FlxEase.quadOut});
			tweenArrayNum(confusion, 1, 0, (Conductor.stepCrochet * 6) / 1000, {ease: FlxEase.quadOut});
			tweenManager.tween(this, {reverse: 1}, (Conductor.stepCrochet * 6) / 1000, {ease: FlxEase.quadOut});
		});
		new FlxTimer(timerManager).start((Conductor.stepCrochet * (stepAdd + 32)) / 1000, function(_) {
			confusion[0] = confusion[1] = -360;
			tweenArrayNum(confusion, 0, 0, (Conductor.stepCrochet * 6) / 1000, {ease: FlxEase.quadOut});
			tweenArrayNum(confusion, 1, 0, (Conductor.stepCrochet * 6) / 1000, {ease: FlxEase.quadOut});
			tweenManager.tween(this, {reverse: 0}, (Conductor.stepCrochet * 6) / 1000, {ease: FlxEase.quadOut});
		});
		new FlxTimer(timerManager).start((Conductor.stepCrochet * (stepAdd + 64)) / 1000, function(_) {
			confusion[0] = -360;
			confusion[1] = 360;
			tweenArrayNum(confusion, 0, 0, (Conductor.stepCrochet * 4) / 1000, {ease: FlxEase.quadOut});
			tweenArrayNum(confusion, 1, 0, (Conductor.stepCrochet * 4) / 1000, {ease: FlxEase.quadOut});
			tweenArrayNum(opponentSwap, 0, 1, (Conductor.stepCrochet * 4) / 1000, {ease: FlxEase.quadOut});
			tweenArrayNum(opponentSwap, 1, 1, (Conductor.stepCrochet * 4) / 1000, {ease: FlxEase.quadOut});
		});
		new FlxTimer(timerManager).start((Conductor.stepCrochet * (stepAdd + 128)) / 1000, function(_)
		{
			confusion[0] = confusion[1] = 360;
			tweenArrayNum(confusion, 0, 0, (Conductor.stepCrochet * 6) / 1000, {ease: FlxEase.quadOut});
			tweenArrayNum(confusion, 1, 0, (Conductor.stepCrochet * 6) / 1000, {ease: FlxEase.quadOut});
			tweenManager.tween(this, {reverse: 1}, (Conductor.stepCrochet * 6) / 1000, {ease: FlxEase.quadOut});
		});
		new FlxTimer(timerManager).start((Conductor.stepCrochet * (stepAdd + 160)) / 1000, function(_)
		{
			confusion[0] = confusion[1] = -360;
			tweenArrayNum(confusion, 0, 0, (Conductor.stepCrochet * 6) / 1000, {ease: FlxEase.quadOut});
			tweenArrayNum(confusion, 1, 0, (Conductor.stepCrochet * 6) / 1000, {ease: FlxEase.quadOut});
			tweenManager.tween(this, {reverse: 0}, (Conductor.stepCrochet * 6) / 1000, {ease: FlxEase.quadOut});
		});
	}

	function tweenArrayNum(array:Array<Float>, index:Int, value:Float, duration:Float = 1, ?options:TweenOptions) {
		return tweenManager.num(array[index], value, duration, options, function(v) {
			array[index] = v;
		});
	}

	function tweenArrayNumInArray(array:Array<Array<Float>>, arrayIndex:Int, index:Int, value:Float, duration:Float = 1, ?options:TweenOptions) {
		return tweenManager.num(array[arrayIndex][index], value, duration, options, function(v) {
			array[arrayIndex][index] = v;
		});
	}

	function spinBurst(player:Int, id:Int) {
		confusionNotes[player][id] = 360;
		tweenArrayNumInArray(confusionNotes, player, id, 0, (Conductor.stepCrochet * 4) / 1000, {ease: FlxEase.quadOut});
		transformZNotes[player][id] = -0.2;
		tweenArrayNumInArray(transformZNotes, player, id, 0, (Conductor.stepCrochet * 4) / 1000, {ease: FlxEase.quadOut});
	}

	function fastTan(rad:Float) // thanks schmoovin
	{
		return FlxMath.fastSin(rad) / FlxMath.fastCos(rad);
	}
}
