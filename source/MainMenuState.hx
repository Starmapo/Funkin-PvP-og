package;

import flixel.util.FlxDestroyUtil;
#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;
import editors.MasterEditorMenu;
import flixel.input.keyboard.FlxKey;

using StringTools;

class MainMenuState extends MusicBeatState
{
	public static var version:String = '0.0.1'; //This is also used for Discord RPC
	public static var curSelected:Int = 0;

	var menuItems:FlxTypedGroup<FlxSprite>;
	private var camGame:FlxCamera;
	
	static var optionShit:Array<String> = [
		'pvp',
		'credits',
		'options'
	];

	var magenta:FlxSprite;
	var camFollow:FlxObject;
	var camFollowPos:FlxObject;
	var debugKeys:Array<FlxKey>;

	override function create()
	{	
		super.create();
		FlxG.mouse.visible = false;
		
		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		debugKeys = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));

		camGame = new FlxCamera();

		FlxG.cameras.reset(camGame);

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = true;

		var yScroll:Float = Math.max(0.25 - (0.05 * (optionShit.length - 4)), 0.1);
		var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('menuBG'));
		bg.scrollFactor.set(0, yScroll);
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);

		magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		magenta.scrollFactor.set(0, yScroll);
		magenta.setGraphicSize(Std.int(magenta.width * 1.175));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.antialiasing = ClientPrefs.globalAntialiasing;
		magenta.color = 0xFFfd719b;
		add(magenta);

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		var totalHeight:Float = 0;
		var scr:Float = (optionShit.length - 4) * 0.135;
		if (optionShit.length < 6)
			scr = 0;
		for (i in 0...optionShit.length)
		{
			var offset:Float = 108 - (Math.max(optionShit.length, 4) - 4) * 80;
			var menuItem:FlxSprite = new FlxSprite(0, (i * 140)  + offset);
			menuItem.frames = Paths.getSparrowAtlas('mainmenu/menu_${optionShit[i]}');
			menuItem.animation.addByPrefix('idle', '${optionShit[i]} basic', 24);
			menuItem.animation.addByPrefix('selected', '${optionShit[i]} white', 24);
			menuItem.animation.play('idle');
			menuItem.ID = i;
			menuItem.screenCenter(X);
			menuItems.add(menuItem);
			menuItem.scrollFactor.set(0, scr);
			menuItem.antialiasing = ClientPrefs.globalAntialiasing;
			menuItem.updateHitbox();
			totalHeight += menuItem.height;
		}

		if (menuItems.length < 4) {
			for (i in 0...menuItems.length) {
				var item = menuItems.members[i];
				item.y = (i * 140) + ((FlxG.height - totalHeight) / 2);
			}
		}

		FlxG.camera.follow(camFollowPos, null, 1);

		var versionShit:FlxText = new FlxText(12, FlxG.height - 24, 0, 'Friday Night Funkin\' PvP v${Application.current.meta.get('version')}', 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);

		changeItem();
	}

	var selectedSomethin:Bool = false;
	var holdTime:Float = 0;
	override function update(elapsed:Float)
	{
		var lerpVal:Float = CoolUtil.boundTo(elapsed * 7.5, 0, 1);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

		if (!selectedSomethin)
		{
			if (MultiControls.anyCheck(UI_UP_P) || FlxG.mouse.wheel > 0)
			{
				CoolUtil.playScrollSound();
				changeItem(-1);
				holdTime = 0;
			}

			if (MultiControls.anyCheck(UI_DOWN_P) || FlxG.mouse.wheel < 0)
			{
				CoolUtil.playScrollSound();
				changeItem(1);
				holdTime = 0;
			}

			var down = MultiControls.anyCheck(UI_DOWN);
			var up = MultiControls.anyCheck(UI_UP);
			if (down || up)
			{
				var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
				holdTime += elapsed;
				var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

				if (holdTime > 0.5 && checkNewHold - checkLastHold > 0)
				{
					CoolUtil.playScrollSound();
					changeItem((checkNewHold - checkLastHold) * (up ? -1 : 1));
				}
			}

			if (MultiControls.anyCheck(BACK_P))
			{
				selectedSomethin = true;
				CoolUtil.playCancelSound();
				MusicBeatState.switchState(new TitleState());
			}

			if (MultiControls.anyCheck(ACCEPT) || FlxG.mouse.justPressed)
			{
				selectedSomethin = true;
				CoolUtil.playConfirmSound();

				if (ClientPrefs.flashing) FlxFlicker.flicker(magenta, 1.1, 0.15, false);

				menuItems.forEach(function(spr:FlxSprite)
				{
					if (curSelected != spr.ID)
					{
						FlxTween.tween(spr, {alpha: 0}, 0.4, {
							ease: FlxEase.quadOut,
							onComplete: function(twn:FlxTween)
							{
								spr.kill();
							}
						});
					}
					else
					{
						FlxFlicker.flicker(spr, 1, 0.06, false, false, function(flick:FlxFlicker)
						{
							var daChoice:String = optionShit[curSelected];

							switch (daChoice)
							{
								default:
									MusicBeatState.switchState(new PvPState());
									FlxG.sound.music.stop();
								case 'credits':
									MusicBeatState.switchState(new CreditsState());
								case 'options':
									MusicBeatState.switchState(new options.OptionsState());
							}
						});
					}
				});
			}
			else if (Main.debug && FlxG.keys.anyJustPressed(debugKeys))
			{
				selectedSomethin = true;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
		}

		super.update(elapsed);

		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.screenCenter(X);
		});
	}

	function changeItem(huh:Int = 0)
	{
		curSelected += huh;

		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;

		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.animation.play('idle');
			spr.updateHitbox();

			if (spr.ID == curSelected)
			{
				spr.animation.play('selected');
				var add:Float = 0;
				if (menuItems.length > 4) {
					add = menuItems.length * 8;
				}
				camFollow.setPosition(spr.getGraphicMidpoint().x, spr.getGraphicMidpoint().y - add);
				spr.centerOffsets();
			}
		});
	}

	override function destroy()
	{
		menuItems = FlxDestroyUtil.destroy(menuItems);
		camGame = FlxDestroyUtil.destroy(camGame);
		magenta = FlxDestroyUtil.destroy(magenta);
		camFollow = FlxDestroyUtil.destroy(camFollow);
		camFollowPos = FlxDestroyUtil.destroy(camFollowPos);
		debugKeys = null;
		super.destroy();
	}
}
