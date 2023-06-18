package;

typedef SwagSong =
{
	var song:String;
	var notes:Array<SwagSection>;
	var ?events:Array<Array<Dynamic>>;
	var bpm:Float;
	var ?timeSignature:Array<Int>;
	var speed:Float;
	var ?boyfriendKeyAmount:Int;
	var ?dadKeyAmount:Int;

	var player1:String;
	var player2:String;
	var ?gfVersion:String;
	var ?stage:String;
	var ?arrowSkin:String;
	var ?splashSkin:String;
	var ?skinModifier:String;
	var type:String;

	var ?sliderVelocities:Array<VelocityChange>;
	var ?initialSpeed:Float;
}
