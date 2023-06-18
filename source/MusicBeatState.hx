package;

import flixel.FlxG;
import flixel.FlxState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.ui.FlxUIState;
import lime.app.Application;

class MusicBeatState extends FlxUIState
{
	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;
	private var controls(get, never):Controls;

	public var windowNamePrefix:String = "Friday Night Funkin' PvP";
	public var windowNameSuffix:String = "";

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	override function create()
	{
		Paths.clearStoredMemory();
		if ((!Std.isOfType(this, PlayState)) && (!Std.isOfType(this, editors.ChartingState)))
			Paths.clearUnusedMemory();

		var skip:Bool = FlxTransitionableState.skipNextTransOut;
		super.create();

		// Custom made Trans out
		if (!skip)
			openSubState(new CustomFadeTransition(0.7, true));
		FlxTransitionableState.skipNextTransOut = false;
	}

	override function update(elapsed:Float)
	{
		var oldStep = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep)
		{
			if (curStep >= 0) {
				var diff = (curStep - oldStep) - 1;
				if (diff > 0) {
					var newStep = curStep;
					var newDecStep = curDecStep;
					for (i in 0...diff) {
						curStep = newStep - (diff - i);
						curDecStep = newDecStep - (diff - i);
						updateBeat();
						stepHit();
					}
					curStep = newStep;
					curDecStep = newDecStep;
					updateBeat();
				}
				stepHit();
			}

			if (PlayState.SONG != null)
			{
				updateSection();
			}
		}

		if (FlxG.save.data != null)
			FlxG.save.data.fullscreen = FlxG.fullscreen;

		Application.current.window.title = windowNamePrefix + windowNameSuffix;

		super.update(elapsed);
	}

	private function updateSection():Void
	{
		if (curStep < 0)
			return;

		var lastSection:Int = curSection;
		curSection = 0;
		stepsToDo = 0;
		for (i in 0...PlayState.SONG.notes.length)
		{
			if (PlayState.SONG.notes[i] != null)
			{
				stepsToDo += PlayState.SONG.notes[i].lengthInSteps;
				if (stepsToDo > curStep)
					break;

				curSection++;
			}
		}

		if (curSection > lastSection)
			sectionHit();
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep / 4;
	}

	private function updateCurStep():Void
	{
		var lastChange = Conductor.getBPMFromSeconds(PlayState.SONG, Conductor.songPosition - ClientPrefs.noteOffset);

		var shit = ((Conductor.songPosition - ClientPrefs.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	public static function switchState(nextState:FlxState)
	{
		// Custom made Trans in
		var curState = getState();
		if (!FlxTransitionableState.skipNextTransIn)
		{
			curState.openSubState(new CustomFadeTransition(0.6, false));
			if (nextState == FlxG.state)
			{
				CustomFadeTransition.finishCallback = function()
				{
					FlxGridOverlay.clearCache();
					FlxG.resetState();
				};
			}
			else
			{
				CustomFadeTransition.finishCallback = function()
				{
					FlxGridOverlay.clearCache();
					FlxG.switchState(nextState);
				};
			}
			return;
		}
		FlxTransitionableState.skipNextTransIn = false;
		FlxGridOverlay.clearCache();
		if (nextState == FlxG.state)
		{
			FlxG.resetState();
		}
		else
		{
			FlxG.switchState(nextState);
		}
	}

	public static function resetState()
	{
		switchState(FlxG.state);
	}

	public static function getState():MusicBeatState
	{
		var curState:Dynamic = FlxG.state;
		var leState:MusicBeatState = curState;
		return leState;
	}

	var passedFirstStep:Bool = false;

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();

		if (curStep >= 0 && !passedFirstStep)
		{ // stupid fix but whatever
			sectionHit();
			passedFirstStep = true;
		}
	}

	public function beatHit():Void
	{
		// trace('Beat: ' + curBeat);
	}

	public function sectionHit():Void
	{
		// trace('Section: ' + curSection + ', Beat: ' + curBeat + ', Step: ' + curStep);
	}

	override function destroy()
	{
		windowNamePrefix = null;
		windowNameSuffix = null;
		super.destroy();
	}
}
