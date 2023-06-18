package;

import haxe.Json;

using StringTools;

typedef StageFile = {
	var defaultZoom:Float;
	var ?isPixelStage:Bool;

	var boyfriend:Array<Float>;
	var girlfriend:Array<Float>;
	var opponent:Array<Float>;
	var ?hide_girlfriend:Bool;

	var ?camera_boyfriend:Array<Float>;
	var ?camera_opponent:Array<Float>;
	var ?camera_girlfriend:Array<Float>;
	var ?camera_speed:Float;
}

class StageData {
	public static function getStageFile(stage:String):StageFile {
		var rawJson:String = null;
		var path:String = Paths.getPath('stages/$stage.json');

		if (Paths.exists(path)) {
			rawJson = Paths.getContent(path);
		}
		else
		{
			return null;
		}

		var stageFile:StageFile = cast Json.parse(rawJson);
		if (stageFile.isPixelStage == null) {
			stageFile.isPixelStage = false;
		}
		if (stageFile.hide_girlfriend == null) {
			stageFile.hide_girlfriend = false;
		}
		if (stageFile.camera_boyfriend == null) {
			stageFile.camera_boyfriend = [0, 0];
		}
		if (stageFile.camera_opponent == null) {
			stageFile.camera_opponent = [0, 0];
		}
		if (stageFile.camera_girlfriend == null) {
			stageFile.camera_girlfriend = [0, 0];
		}
		if (stageFile.camera_speed == null) {
			stageFile.camera_speed = 1;
		}
		return stageFile;
	}

	public static function getStageFromSong(song:String) {
		switch (song)
		{
			case 'tutorial' | 'bopeebo' | 'fresh' | 'dad-battle' | 'test':
				return 'stage';
			case 'spookeez' | 'south' | 'monster':
				return 'spooky';
			case 'pico' | 'blammed' | 'philly' | 'philly-nice':
				return 'philly';
			case 'milf' | 'satin-panties' | 'high':
				return 'limo';
			case 'cocoa' | 'eggnog':
				return 'mall';
			case 'winter-horrorland':
				return 'mallEvil';
			case 'senpai' | 'roses':
				return 'school';
			case 'thorns':
				return 'schoolEvil';
			case 'ugh' | 'guns' | 'stress':
				return 'tank';
			default:
				return '!VOID!';
		}
	}
}