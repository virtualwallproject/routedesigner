package arm;

import kha.FastFloat;
import iron.Scene;
import iron.object.Object;
using arm.ObjectTools;

import kha.System;
import kha.Scheduler;

class ScreenSequenceTrait extends iron.Trait {
	var current_screen:Int = 0;
	var next_screen:Int = 1;
	var scene:Scene;
	var delay_start:FastFloat = 0;
	var delay:FastFloat = 0.5;

	@prop
	var has_intro:Bool = false;
	@prop
	var repeat:Int = 0;

	public function new() {
		super();

		notifyOnInit(function() {
			scene = Scene.active;

			// initialize delay at positive value so first screen shows up faster
			delay_start = 0.5*delay;

			spawn_screen(next_screen);
		});

		notifyOnUpdate(function() {
			spawn_screen(next_screen + 1);

			// by default hide all the screens that are spawned
			for (child in object.children)
				child.setVisibility(false);

			if (object.visible) {
				// show the current screen if we have it
				var i:Int = current_screen;

				if (has_intro && (i == 1) && (delay_start == 0)) {
					show_next_screen();
					delay_start = Scheduler.time() + 3 - delay;
				}
				
				if (has_screen(i)) {
					for (j in 0...num_tiles(i)) {
						var screen:Object = screen_from_index(i,j);
						if (screen != null) screen_from_index(i,j).setVisibility(true);
					}
				}
				
				if (i != next_screen) {
					if (delay_start <= 0) {
						delay_start = Scheduler.time();
					} else if ((Scheduler.time() - delay_start) > delay) {
						update_screen();
						delay_start = 0;
					}
				}
			}
		});

		// notifyOnRemove(function() {
		// });
	}

	function has_screen(i:Int):Bool {
		return object.properties.exists('screen_${i}');
	}

	function split_screen(i:Int):Array<String> {
		return Std.string(object.properties['screen_${i}']).split(',');
	}

	function num_tiles(i:Int):Int {
		if (has_screen(i)) {
			var temp:Array<String> = split_screen(i);
			return temp.length;
		}

		return 0;
	}

	function screen_from_index(i:Int,j:Int=0):Object {
		var split:Array<String> = split_screen(i);
		if (j < split.length)
			return object.getChild(split[j]);
		else return null;
	}

	function spawn_screen(i:Int,j:Int=0) {
		if (has_screen(i) && (screen_from_index(i,j) == null)) {
			var split:Array<String> = split_screen(i);
			if (j < split.length)
				scene.spawnObject(split[j], object, null);
		}
	}

	public function update_screen() {
		// remove the old screen from scene
		if (has_screen(current_screen)){
			for (j in 0...num_tiles(current_screen)) {
				var screen:Object = screen_from_index(current_screen,j);
				if (screen != null) screen.remove();
			}
		}

		// spawn the next screen
		if (next_screen != 0) {
			for (j in 0...num_tiles(next_screen)) {
				if (screen_from_index(next_screen,j) == null)
					spawn_screen(next_screen,j);
				else
					screen_from_index(next_screen,j).setVisibility(true);
			}
		}

		// set the current grip index to the next grip index
		current_screen = next_screen;
	}

	public function show_next_screen() {
		// add this check to make sure we only increment the screen when the screen
		// sequence is ready
		if (current_screen == next_screen) {
			if (has_screen(next_screen + 1))
				next_screen++;
			else
				next_screen = repeat;
		}
	}

	public function show_screen(i:Int) {
		if (current_screen == next_screen) {
			if (has_screen(i))
				next_screen = i;
		}
	}

	public function reset_screen() {
		next_screen = 0;
	}

	public function get_current():Int {
		return current_screen;
	}

	public function set_delay_start(f:FastFloat) {
		if (f < 0) delay_start = delay;
		else delay_start = f;
	}
}
