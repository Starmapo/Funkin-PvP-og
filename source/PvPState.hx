import Controls.Action;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.ui.FlxBar;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;

class PvPState extends MusicBeatState
{
	var charGroup:FlxTypedGroup<Character> = new FlxTypedGroup();
	var textGroup:FlxTypedGroup<FlxText> = new FlxTypedGroup();
	var iconGroup:FlxTypedGroup<FlxSprite> = new FlxTypedGroup();
	var strumLineGroup:FlxTypedGroup<StrumLine> = new FlxTypedGroup();
	var controlsArray:Array<FlxTypedGroup<FlxText>> = [];
	var switchButton:FlxButton;
	var noGamepadBlack:FlxSprite;
	var noGamepadText:FlxText;
	var noGamepadSine:Float = 0;
	var playerReady:Array<Bool> = [false, false];
	var exiting:Bool = false;
	var startText:FlxText;
	var startBG:FlxSprite;
	var returnBar:FlxBar;
	var returnTime:Float = 0;

	override function create()
	{
		super.create();
		persistentUpdate = true;
		FlxG.mouse.visible = true;

		var bg = new FlxSprite(0, 0, Paths.image('menuBG'));
		bg.scrollFactor.set();
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);

		for (i in 0...2)
		{
			var char = new Character(0, 0, 'bf', (i > 0));
			char.x = ((FlxG.width / 2) - char.width) / 2;
			if (i > 0)
				char.x += (FlxG.width / 2);
			char.screenCenter(Y);
			char.isPlayer = true;
			char.scrollFactor.set();
			charGroup.add(char);

			var text = new FlxText(0, 10, FlxG.width / 2, 'Player ${MultiControls.playerFromPosition(i) + 1}');
			if (i > 0)
				text.x += (FlxG.width / 2);
			text.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			text.scrollFactor.set();
			text.borderSize = 2;
			textGroup.add(text);

			var img = (MultiControls.isPositionGamepad(i) ? 'gamepad' : 'keyboard');
			var icon = new FlxSprite(0, text.y + text.height + 5, Paths.image('pvp/$img'));
			icon.x = ((FlxG.width / 2) - icon.width) / 2;
			if (i > 0)
				icon.x += (FlxG.width / 2);
			icon.scrollFactor.set();
			iconGroup.add(icon);

			var strumLine = new StrumLine((i > 0 ? FlxG.width / 2 : 0), FlxG.height - 162);
			strumLineGroup.add(strumLine);

			var controlsGroup = new FlxTypedGroup<FlxText>();
			var h:Float = -1;
			for (j in 0...6)
			{
				var controlsText = new FlxText(0, icon.y + 100 + (h * j), 0);
				controlsText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				controlsText.scrollFactor.set();
				controlsText.borderSize = 2;
				controlsGroup.add(controlsText);
				if (h < 0)
					h = controlsText.height;
			}
			controlsArray.push(controlsGroup);
		}

		add(charGroup);
		add(textGroup);
		add(iconGroup);
		add(strumLineGroup);
		for (i in 0...controlsArray.length)
			add(controlsArray[i]);

		noGamepadBlack = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width / 2), FlxG.height, FlxColor.BLACK);
		if (MultiControls.isPositionGamepad(1))
			noGamepadBlack.x += (FlxG.width / 2);
		noGamepadBlack.scrollFactor.set();
		noGamepadBlack.alpha = 0.8;
		noGamepadBlack.visible = !MultiControls.playerActive(1);
		add(noGamepadBlack);

		noGamepadText = new FlxText(noGamepadBlack.x, FlxG.height / 2, FlxG.width / 2, "Waiting for gamepad...", 32);
		noGamepadText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		noGamepadText.y -= (noGamepadText.height / 2);
		noGamepadText.scrollFactor.set();
		noGamepadText.borderSize = 2;
		noGamepadText.visible = !MultiControls.playerActive(1);
		add(noGamepadText);

		startText = new FlxText(0, FlxG.height * 0.3, FlxG.width / 2, "Press ACCEPT to continue");
		startText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		startText.screenCenter();
		startText.scrollFactor.set();
		startText.borderSize = 2;
		startText.visible = MultiControls.playerActive(1);

		startBG = new FlxSprite().makeGraphic(FlxG.width, Std.int(startText.height), FlxColor.BLACK);
		startBG.screenCenter();
		startBG.alpha = 0.5;
		startBG.scrollFactor.set();

		add(startBG);
		add(startText);

		switchButton = new FlxButton(0, 10, 'Switch Players', function()
		{
			switchPlayers();
			CoolUtil.playScrollSound();
		});
		switchButton.screenCenter(X);
		switchButton.visible = !MultiControls.keyboardControls;
		add(switchButton);

		returnBar = new FlxBar(0, 0, LEFT_TO_RIGHT, 200, 40, this, 'returnTime', 0.2, 1.2);
		returnBar.createFilledBar(0xFF000000, 0xFFFFFFFF, true, FlxColor.BLACK);
		returnBar.screenCenter(X);
		returnBar.scrollFactor.set();
		add(returnBar);

		updateControlsText();

		if (FlxG.sound.music == null || !FlxG.sound.music.playing)
			CoolUtil.playPvPMusic();
	}

	override function update(elapsed:Float)
	{
		Conductor.songPosition = FlxG.sound.music.time;
		super.update(elapsed);

		iconGroup.members[MultiControls.playerPosition(0)].alpha = 1;
		if (FlxG.mouse.overlaps(iconGroup.members[MultiControls.playerPosition(1)]))
		{
			if (FlxG.mouse.justPressed)
			{
				MultiControls.toggleKeyboardControls();
				if (MultiControls.keyboardControls && MultiControls.playerPosition(0) != 0)
					switchPlayers();
				else
				{
					for (i in 0...2)
						resetShit(i);
					updateControlsText();
				}
				switchButton.visible = !MultiControls.keyboardControls;
				CoolUtil.playScrollSound();
			}

			iconGroup.members[MultiControls.playerPosition(1)].alpha = (!FlxG.mouse.pressed ? 0.5 : 1);
		}
		else
			iconGroup.members[MultiControls.playerPosition(1)].alpha = 1;

		noGamepadBlack.visible = noGamepadText.visible = !MultiControls.playerActive(1);
		if (noGamepadText.visible)
		{
			noGamepadSine += 180 * elapsed;
			noGamepadText.alpha = 1 - Math.sin((Math.PI * noGamepadSine) / 180);
		}
		startBG.visible = startText.visible = !exiting && MultiControls.playerActive(1);

		if (!exiting)
		{
			var keys:Array<Action> = [NOTE_LEFT_P, NOTE_DOWN_P, NOTE_UP_P, NOTE_RIGHT_P];
			for (i in 0...2)
			{
				for (j in 0...4)
				{
					if (MultiControls.positionCheck(keys[j], i))
					{
						charGroup.members[i].playAnim(strumLineGroup.members[i].animations[j], true);
						charGroup.members[i].holdTimer = 0;
						charGroup.members[i].state = Sing;

						strumLineGroup.members[i].getReceptor(j).playAnim('pressed');
					}
				}
			}

			keys = [NOTE_LEFT, NOTE_DOWN, NOTE_UP, NOTE_RIGHT];
			for (i in 0...2)
			{
				var pressed:Bool = false;
				for (j in 0...4)
				{
					if (MultiControls.positionCheck(keys[j], i))
					{
						pressed = true;
						break;
					}
				}
				if (!pressed
					&& charGroup.members[i].holdTimer > Conductor.normalizedStepCrochet * 0.0011 * charGroup.members[i].singDuration
					&& charGroup.members[i].state == Sing)
				{
					charGroup.members[i].dance();
				}
			}

			keys = [NOTE_LEFT_R, NOTE_DOWN_R, NOTE_UP_R, NOTE_RIGHT_R];
			for (i in 0...2)
			{
				for (j in 0...4)
				{
					if (MultiControls.positionCheck(keys[j], i))
					{
						strumLineGroup.members[i].getReceptor(j).playAnim('static');
					}
				}
			}

			if (MultiControls.anyCheck(ACCEPT) && (Main.debug || MultiControls.playerActive(1)))
			{
				MusicBeatState.switchState(new SongSelectState());
				CoolUtil.playConfirmSound();
				startBG.visible = startText.visible = false;
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
							MusicBeatState.switchState(new MainMenuState());
							CoolUtil.playCancelSound();
							CoolUtil.playMenuMusic();
							exiting = true;
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

	override function beatHit()
	{
		if (curBeat % 2 == 0)
		{
			for (char in charGroup)
			{
				if (char.state == Default)
					char.dance();
			}
		}
	}

	function resetShit(i:Int)
	{
		var img = (MultiControls.isPositionGamepad(i) ? 'gamepad' : 'keyboard');
		iconGroup.members[i].loadGraphic(Paths.image('pvp/$img'));
		if (charGroup.members[i].state == Sing)
			charGroup.members[i].dance();
		for (j in 0...4)
		{
			strumLineGroup.members[i].getReceptor(j).playAnim('static');
		}
	}

	function switchPlayers()
	{
		MultiControls.switchPlayerPosition(0, 1);
		for (i in 0...2)
		{
			textGroup.members[i].text = 'Player ${MultiControls.playerFromPosition(i) + 1}';
			resetShit(i);
		}
		noGamepadText.x = noGamepadBlack.x = (FlxG.width / 2) * MultiControls.playerPosition(1);
		updateControlsText();
	}

	function updateControlsText()
	{
		for (i in 0...2)
		{
			var controlsGroup = controlsArray[MultiControls.playerPosition(i)];
			switch (i)
			{
				case 0:
					if (MultiControls.keyboardControls)
					{
						controlsGroup.members[0].text = 'Note Binds: A/S/D/F';
						controlsGroup.members[1].text = 'Menu Navigation: WASD';
						controlsGroup.members[2].text = 'Accept: Z';
						controlsGroup.members[3].text = 'Back: X';
						controlsGroup.members[4].text = 'Pause: 1';
						controlsGroup.members[5].text = 'Reset: R';
					}
					else
						for (j in 0...controlsGroup.length)
							controlsGroup.members[j].text = '';

				case 1:
					if (MultiControls.keyboardControls)
					{
						controlsGroup.members[0].text = 'Note Binds: Arrow Keys';
						controlsGroup.members[1].text = 'Menu Navigation: Arrow Keys';
						controlsGroup.members[2].text = 'Accept: O';
						controlsGroup.members[3].text = 'Back: P';
						controlsGroup.members[4].text = 'Pause: Enter';
						controlsGroup.members[5].text = 'Reset: Backspace';
					}
					else
					{
						controlsGroup.members[0].text = 'Note Binds: LT/LB/RB/RT';
						controlsGroup.members[1].text = 'Menu Navigation: Left Analog Stick';
						controlsGroup.members[2].text = 'Accept: A';
						controlsGroup.members[3].text = 'Back: B';
						controlsGroup.members[4].text = 'Pause: Start';
						controlsGroup.members[5].text = 'Reset: X';
					}
			}

			if (MultiControls.playerPosition(i) > 0)
			{
				for (j in 0...controlsGroup.length)
					controlsGroup.members[j].x = FlxG.width - controlsGroup.members[j].width - 2;
			}
		}
	}
}
