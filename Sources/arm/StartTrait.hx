package arm;

import iron.object.Object;
import iron.Scene;
import kha.input.Surface;
import kha.input.Mouse;

import arm.KhaSurface;
import arm.KhaMouse;

class StartTrait extends iron.Trait {
	var names_tospawn:Array<String>;
	var surface:KhaSurface;
	var mouse:KhaMouse;
	var keyboard:KhaKeyboard;
	var screen_name:String;

	public function new() {
		super();

		notifyOnInit(function() {
      keyboard = new KhaKeyboard(Scene.active);
			surface = new KhaSurface();
			mouse = new KhaMouse(Scene.active.camera);
            
			var temp = Surface.get();
			if (temp != null) temp.notify(
				surface.touchStart,
				surface.touchEnd,
				surface.touchMove
			);

			var temp2 = Mouse.get();
			if (temp2 != null) temp2.notify(
				mouse.touchStart,
				mouse.touchEnd,
				mouse.mouseMove,
				mouse.wheelMove
			);
			
			#if kha_js
			var st:SceneTrait = Scene.active.getTrait(SceneTrait);
			if (st.num_joycons() > 0)
				screen_name = get_string_property("joycon_start_screen");
			else
				screen_name = get_string_property('js_start_screen');
			#else
			screen_name = get_string_property('js_start_screen');
			#end
			spawn_names([screen_name]);
		});

		notifyOnUpdate(function() {

			if (keyboard.state("ShowHelp") || keyboard.state("Center/Activate")) start_help("Keyboard");
			else if (surface.held(1) || surface.tapped(1)) start_help("Surface");
			else if (mouse.held(1) || mouse.tapped(1)) start_help("Mouse");

			// run released to reset the surface
			surface.released(1);
			surface.released(2);
			surface.released(3);
			mouse.released(1);
			mouse.released(2);
			mouse.released(3);
		});

		notifyOnRemove(function() {
			spawn_names(names_tospawn);
		});
	}

	function get_string_property(name:String):String {
		if (object.properties.exists(name))
			return object.properties[name];
		else return null;
	}

	function spawn_names(names:Array<String>) {
		if (names != null) {
			for (s in names) {
				var o:Object = Scene.active.getChild(s);
				// if object is not spawned, spawn it, otherwise make it visible
				if (o == null)
					Scene.active.spawnObject(s, null, null, false);
				else
					ObjectTools.setVisibility(o,true);
			}
		}
	}

	function start_help(name:String) {
		names_tospawn = [name];
		keyboard.remove();
		Scene.active.getChild(screen_name).remove();
		object.remove();
	}
}
