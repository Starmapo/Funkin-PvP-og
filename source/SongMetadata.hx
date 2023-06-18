import flixel.util.FlxColor;

using StringTools;

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var color:Int = -7179779;
	public var displayName:String = "";
	public var difficulties:String = null;
	public var skipStage:Bool = false;
	public var random:Bool = false;

	public function new(song:String, ?week:Int, ?songCharacter:String, ?color:Int, ?displayName:String, ?skipStage:Bool = false, ?difficulties:String)
	{
		songName = song;
		if (song == '')
		{
			random = true;
			this.color = FlxColor.GRAY;
			this.displayName = 'Pick Random';
			this.difficulties = '';
		}
		else
		{
			this.week = week;
			this.songCharacter = songCharacter;
			this.color = color;
			this.displayName = displayName;
			if (this.displayName == null)
				this.displayName = songName;
			this.skipStage = skipStage;
			if (difficulties != null)
				this.difficulties = difficulties.trim();
		}
	}
}