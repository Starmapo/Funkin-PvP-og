import flixel.util.FlxSort;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxBasic;
import flixel.group.FlxGroup.FlxTypedGroup;

using StringTools;

typedef KeyChangeEvent =
{
	var section:Int;
	var keys:Int;
}

class StrumLine extends FlxTypedGroup<FlxBasic>
{
	public var receptors:FlxTypedGroup<StrumNote>;
	public var receptorsGroup:FlxTypedGroup<StrumNote>;
	public var notesGroup:FlxTypedGroup<Note>;
	public var holdsGroup:FlxTypedGroup<Note>;
	public var allNotes:FlxTypedGroup<Note>;

	public var keys:Int = 4;
	public var colors:Array<String> = [];
	public var animations:Array<String> = [];
	public var botPlay:Bool = true;
	public var isBoyfriend:Bool = false;

	public var keyChangeMap:Array<KeyChangeEvent> = [];

	public function new(x:Float = 0, y:Float = 0, keyAmount:Int = 4, tweenAlpha:Bool = false, inPlayState:Bool = false)
	{
		super();

		receptors = new FlxTypedGroup<StrumNote>();
		receptorsGroup = new FlxTypedGroup<StrumNote>();
		holdsGroup = new FlxTypedGroup<Note>();
		notesGroup = new FlxTypedGroup<Note>();
		allNotes = new FlxTypedGroup<Note>();

		createStrumLine(x, y, keyAmount, tweenAlpha, inPlayState);

		add(receptorsGroup);
		add(holdsGroup);
		add(notesGroup);
	}

	public function createStrumLine(x:Float = 0, y:Float = 0, keyAmount:Int = 4, tweenAlpha:Bool = false, inPlayState:Bool = false)
	{
		for (spr in receptors.members)
		{
			spr.kill();
			receptors.remove(spr);
			spr.destroy();
		}

		colors = CoolUtil.coolArrayTextFile(Paths.txt('note_colors'))[keyAmount - 1];
		animations = CoolUtil.coolArrayTextFile(Paths.txt('note_animations'))[keyAmount - 1];

		for (i in 0...keyAmount)
		{
			var targetAlpha:Float = 1;

			var babyArrow:StrumNote = new StrumNote(x, y, i, keyAmount);
			babyArrow.downScroll = ClientPrefs.downScroll;
			if (inPlayState && tweenAlpha)
			{
				var delay = 500 / (250 * keyAmount);
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {alpha: targetAlpha}, delay, {ease: FlxEase.circOut, startDelay: delay * (i + 1)});
			}
			else
			{
				babyArrow.alpha = targetAlpha;
			}

			receptors.add(babyArrow);
			receptorsGroup.add(babyArrow);
			babyArrow.postAddedToGroup();

			// centering it where 4k note size would be
			if (babyArrow.skinModifier.endsWith('pixel'))
			{
				babyArrow.x += (8.5 - (babyArrow.frameWidth / 2)) * (babyArrow.noteSize / Note.DEFAULT_NOTE_SIZE);
				babyArrow.y += (8.5 - (babyArrow.frameHeight / 2)) * (babyArrow.noteSize / Note.DEFAULT_NOTE_SIZE);
			}
			else
			{
				babyArrow.x += (80 - (babyArrow.frameWidth / 2)) * babyArrow.noteSize;
				babyArrow.y += (80 - (babyArrow.frameHeight / 2)) * babyArrow.noteSize;
			}

			babyArrow.defaultX = babyArrow.x;
			babyArrow.defaultY = babyArrow.y;
		}

		keys = keyAmount;
	}

	public function push(newNote:Note)
	{
		var chosenGroup = (newNote.isSustainNote ? holdsGroup : notesGroup);
		chosenGroup.add(newNote);
		allNotes.add(newNote);
		//chosenGroup.sort(sortByShit, FlxSort.ASCENDING);
	}

	function sortByShit(Order:Int, Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(Order, Obj1.strumTime, Obj2.strumTime);
	}

	public function removeNote(note:Note)
	{
		allNotes.remove(note, true);
		var daGroup = (note.isSustainNote ? holdsGroup : notesGroup);
		daGroup.remove(note, true);
	}

	public function takeNotesFrom(strum:StrumLine)
	{
		for (newNote in strum.allNotes)
		{
			push(newNote);
			var chosenGroup = (newNote.isSustainNote ? strum.holdsGroup : strum.notesGroup);
			chosenGroup.remove(newNote, true);
			strum.allNotes.remove(newNote, true);
		}
	}

	public function pushEvent(event:KeyChangeEvent)
	{
		keyChangeMap.push(event);
		keyChangeMap.sort(sortEvents);
	}

	function sortEvents(Obj1:KeyChangeEvent, Obj2:KeyChangeEvent):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.section, Obj2.section);
	}

	public function getReceptor(id:Int) {
		return receptors.members[id];
	}
}
