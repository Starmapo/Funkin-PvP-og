package;

import Controls;
import flixel.util.FlxSignal;

class PlayerSettings
{
	static public var player1(default, null):PlayerSettings;

	static public final onAvatarAdd = new FlxTypedSignal<PlayerSettings->Void>();
	static public final onAvatarRemove = new FlxTypedSignal<PlayerSettings->Void>();

	public var id(default, null):Int;

	public final controls:Controls;

	function new(id, scheme)
	{
		this.id = id;
		this.controls = new Controls('player$id', scheme);
	}

	public function setKeyboardScheme(scheme)
	{
		controls.setKeyboardScheme(scheme);
	}
	
	static public function init():Void
	{
		if (player1 == null)
		{
			player1 = new PlayerSettings(0, Solo);
		}

		MultiControls.init();
	}

	static public function reset()
	{
		player1 = null;
	}
}