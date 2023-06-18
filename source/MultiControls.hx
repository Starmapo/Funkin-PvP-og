import Controls.Action;
import flixel.FlxG;

class MultiControls
{
	public static var MAX_PLAYERS:Int = 2;
	public static var controlsArray:Array<Controls> = [];
	public static var controlsMap:Map<Int, Int> = new Map();
	public static var keyboardControls:Bool = false;

	public static function init()
	{
		controlsArray = [PlayerSettings.player1.controls];
		controlsMap.set(0, 0);

		for (i in 0...MAX_PLAYERS - 1)
		{
			var controls = new Controls('player' + (i + 2), Solo);
			controls.setKeyboardScheme(None);
			controlsArray.push(controls);
			controlsMap.set(i + 1, i + 1);

			var gamepad = FlxG.gamepads.getByID(i);
			if (gamepad != null)
			{
				addGamepadControls(gamepad.id);
			}
		}

		FlxG.gamepads.deviceConnected.add(function(gamepad)
		{
			if (!keyboardControls && gamepad != null && !controlsArray[gamepad.id + 1].gamepadsAdded.contains(gamepad.id))
			{
				addGamepadControls(gamepad.id);
			}
		});
		FlxG.gamepads.deviceDisconnected.add(function(gamepad)
		{
			if (gamepad != null)
			{
				removeGamepadControls(gamepad.id);
			}
		});
	}

	static function addGamepadControls(id:Int)
	{
		controlsArray[id + 1].addDefaultGamepad(id);
	}

	static function removeGamepadControls(id:Int)
	{
		controlsArray[id + 1].removeGamepad(id);
	}

	public static function playerCheck(action:Action, player:Int = 0)
	{
		if (controlsArray[player] != null)
			return controlsArray[player].checkByName(action);
		return false;
	}

	public static function positionCheck(action:Action, pos:Int = 0)
	{
		return playerCheck(action, playerFromPosition(pos));
	}

	public static function anyCheck(action:Action)
	{
		for (i in 0...controlsArray.length)
		{
			if (playerCheck(action, i))
				return true;
		}
		return false;
	}

	public static function playerActive(player:Int = 0)
	{
		return keyboardControls || (player == 0) || (controlsArray[player].gamepadsAdded.length > 0);
	}

	public static function positionActive(pos:Int = 0)
	{
		return playerActive(playerFromPosition(pos));
	}

	public static function playerPosition(player:Int)
	{
		return controlsMap.get(player);
	}

	public static function playerFromPosition(pos:Int)
	{
		for (key => mapPos in controlsMap)
		{
			if (mapPos == pos)
				return key;
		}
		return pos;
	}

	public static function switchPlayerPosition(player1:Int, player2:Int)
	{
		var newPos = playerPosition(player1);
		controlsMap.set(player1, playerPosition(player2));
		controlsMap.set(player2, newPos);
	}

	public static function isPlayerGamepad(player:Int) {
		return !keyboardControls && player > 0;
	}

	public static function isPositionGamepad(pos:Int) {
		return isPlayerGamepad(playerFromPosition(pos));
	}

	public static function toggleKeyboardControls() {
		keyboardControls = !keyboardControls;
		if (keyboardControls) {
			controlsArray[0].setKeyboardScheme(Duo(true));
			if (FlxG.gamepads.getByID(0) != null)
				removeGamepadControls(0);
			controlsArray[1].setKeyboardScheme(Duo(false));
		} else {
			controlsArray[0].setKeyboardScheme(Solo);
			controlsArray[1].setKeyboardScheme(None);
			if (FlxG.gamepads.getByID(0) != null)
				addGamepadControls(0);
		}
	}
}
