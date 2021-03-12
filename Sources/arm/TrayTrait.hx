package arm;

import iron.math.Mat4;
import iron.math.RayCaster;
import iron.math.Vec4;
import iron.math.Vec2;
import iron.Scene;
import kha.Window;
import iron.object.CameraObject;
import iron.object.Object;
import iron.object.MeshObject;
import kha.FastFloat;
import iron.math.Quat;

using arm.ObjectTools;

class TrayTrait extends iron.Trait {
	var scene:Scene;
	var w:Window;
	var cam:CameraObject;
	var height:FastFloat = 0;
	var width:FastFloat = 0;
	var show_grips:Bool = false;
	var current_grip:Int = -1;
	var slave_grip:Int = 0;
	var next_grip:Int = 1;
	var screen_loc:Vec2 = new Vec2(0,0);
	var offset:Vec2 = new Vec2(0,0);
	var R:Quat = new Quat();
	var scale:FastFloat = 1.0;
	var scroll_time:FastFloat = 0.5;

  @prop
  var tray_show_icon_name: String;
  @prop
  var tray_hide_icon_name: String;
  @prop
  var remove_icon_name: String;

	public function new() {
		super();

		notifyOnInit(function() {
			scene = Scene.active;
			cam = scene.camera;
			w = Window.get(0);

			// set it local only to ignore the transforms of parents
			object.transform.localOnly = true;
		});

		notifyOnUpdate(function() {
			// keep the tray visibility the same as the parent
			if (object.visible != object.parent.visible) {
				object.setVisibility(object.parent.visible);
			}

			if (object.visible) {
				set_icon_visibility(!show_grips,show_grips);
			} else {
				set_icon_visibility(false,false);
			}
		});

		notifyOnLateUpdate(function() {
			if (object.visible) {
				if ((height != w.height) || (width != w.width)) {
					object.getTrait(InTheWayTrait)._lateUpdate[0]();
					set_screen_loc();
					set_height();
				}

				update_grips();
			}
		});

		// notifyOnRemove(function() {
		// });
	}

	function set_screen_loc()
		screen_loc.setFrom(object.getTrait(InTheWayTrait).get_screen_loc());

	/**
	 * Set the quaternion for undoing the parent rotation
	 */
	function set_R() {
		R.set(
			-object.transform.rot.x,
			-object.transform.rot.y,
			-object.transform.rot.z,
			object.transform.rot.w);
	}

	/**
	 * Update the class variables that are based screen height
	 */
	function set_height() {
		height = w.height;
		width = w.width;

		set_R();

		offset.set(Math.min(height,width)/6,0);

		var a = new Vec4();
		set_tray_loc(a,screen_loc.x,screen_loc.y);
		var a2 = new Vec4();
		set_tray_loc(a2,screen_loc.x + offset.x,screen_loc.y + offset.y);

		// set scale to distance between center grip and adjacent grip
		scale = a2.sub(a).length();

		// trigger update of grips
		current_grip = -1;
	}

	function set_tray_loc(loc:Vec4,screen_x:FastFloat,screen_y:FastFloat) {
		var start = new Vec4();
		RayCaster.getDirection(
			start,
			loc,
			screen_x,
			screen_y,
			cam
		);
		loc.sub(start).normalize();

		loc.add(cam.transform.loc).sub(object.transform.loc);

		set_R();
		
		loc.applyQuat(R);
	}

	/**
	 * Spawn (if necessary) and set location of grip in tray
	 * @param name Name of grip
	 * @param i Screen location in multiples of offset relative to center of tray
	 * @return Bool true if grip was added
	 */
	function add_grip_at(name:String,i:Int):Bool {
		if (name == "") return true;

		// figure out where on the screen this tray grip goes
		var x:FastFloat = screen_loc.x + i*offset.x;
		var y:FastFloat = screen_loc.y + i*offset.y;

		// if grip in tray will not be visible do not add it
		if ((x < 0) || (x > w.width) || (y < 0) || (y > height)) return false;

		// spawn grip if necessary
		var temp:Object = object.getChild(name);
		if (temp == null)
			temp = object.parent.getTrait(SlaveFrameTrait).spawn_grip(name,object,null);

		if (temp != null) {
			// make it visible
			temp.setVisibility(true);

			// reset the transform to identity
			temp.transform.setMatrix(Mat4.identity());

			// set scale
			var max:FastFloat = Math.max(temp.transform.dim.x,temp.transform.dim.y);
			// make sure there's some gap between the holds
			max = max*((width > height) ? 1.1 : 1.5);
			temp.transform.scale.set(scale/max,scale/max,scale/max,1);

			// set location
			set_tray_loc(temp.transform.loc,x,y);

			temp.transform.buildMatrix();

			if (temp.getChild(remove_icon_name) != null) temp.flatten();

			return true;
		} else return false;
	}

	/**
	 * Update the grips in the tray
	 */
	function update_grips() {
		if ((!show_grips) || (current_grip != next_grip))
			for (grip in object.children) grip.setVisibility(false);

		if ((show_grips) && (current_grip != next_grip)) {
			var slave_trait = object.parent.getTrait(SlaveFrameTrait);

			var i:Int = 0;
			var grip_i:Int = next_grip;
			var name:String = "";
			var added:Bool = true;
			while (added) {
				i--;
				grip_i--;
				if (grip_i%(slave_trait.get_max_grips() + 1) == 0)
					grip_i = slave_trait.get_max_grips();
				name = slave_trait.grip_name(grip_i);
				added = add_grip_at(name,i);
			}
			i = 0;
			grip_i = next_grip;
			name = "";
			added = true;
			while (added) {
				i++;
				if (grip_i%(slave_trait.get_max_grips() + 1) == 0)
					grip_i = 1;
				name = slave_trait.grip_name(grip_i);
				added = add_grip_at(name,i);
				grip_i++;
			}
		}

		current_grip = next_grip;
	}

	/**
	 * Helper fxn to set the icon visibility
	 * @param show visibility of show tray icon
	 * @param hide visibility of hide tray icon
	 */
	function set_icon_visibility(show:Bool,hide:Bool) {
		scene.getChild(tray_show_icon_name).setVisibility(show);
		scene.getChild(tray_hide_icon_name).setVisibility(hide);
	}

	public function get_current():Int {
		return current_grip;
	}

	public function show_next_grip() {
		var slave_trait = object.parent.getTrait(SlaveFrameTrait);

		if (next_grip >= slave_trait.get_max_grips()) {
			next_grip = 1;
		} else {
			next_grip += 1;
		}
	}

	public function show_prev_grip() {
		var slave_trait = object.parent.getTrait(SlaveFrameTrait);

		if (next_grip <= 1) {
			next_grip = slave_trait.get_max_grips();
		} else {
			next_grip += -1;
		}
	}

	/**
	 * Called when the slave frame current grip has changed so we can give the
	 * tray version a remove icon
	 * @param i The number of the grip that is current
	 */
	public function set_slave_grip(i:Int) {
		if (i != 0) {
			var slave_trait = object.parent.getTrait(SlaveFrameTrait);

			// if the active slave grip has changed then remove old icon
			if (slave_grip != 0) remove_remove(slave_grip);

			// get the tray version of the hold
			var b:Object = object.getChild(slave_trait.grip_name(i));

			// check if it has the remove icon
			var temp:Object = b.getChild(remove_icon_name);

			// if the tray version does not have a remove icon add it
			if (temp == null) {
				// spawn the remove icon for new slave grip tray version
				scene.spawnObject(remove_icon_name,b,null,true);

				// adjust the scale and location of the remove icon
				var remove_icon:Object = b.getChild(remove_icon_name);
				var i_scale:Vec4 = b.transform.local.getScale();
				remove_icon.transform.scale.mult(1/i_scale.x);
				set_tray_loc(remove_icon.transform.loc,screen_loc.x,1*screen_loc.y);
				remove_icon.transform.buildMatrix();
				var mesh:MeshObject = cast(b,MeshObject);
				remove_icon.transform.move(Vec4.zAxis(),mesh.data.scalePos);
				b.flatten();
			}
		}

		slave_grip = i;
	}

	public function remove_remove(i:Int) {
		if (i != 0) {
			var slave_trait = object.parent.getTrait(SlaveFrameTrait);
			var a:Object = object.getChild(slave_trait.grip_name(i));
			var remove_icon:Object = a.getChild(remove_icon_name);
			remove_icon.remove();
			a.unflatten();
		}
	}

	/**
	 * Toggle tray grip visibility
	 * @return Bool state of show tray grips
	 */
	public function toggle_grips():Bool {
		show_grips = !show_grips;

		// force update of grips
		current_grip = -1;

		return show_grips;
	}

	public function hide_grips() show_grips = false;

	public function is_clicked(x:FastFloat,y:FastFloat):Int {
		if (show_grips) {
			var radius = offset.length()/2;

			var i_x:Int = Math.round((x - screen_loc.x)/offset.x);
			var y_i:FastFloat = screen_loc.y + i_x*offset.y;
			var x_i:FastFloat = screen_loc.x + i_x*offset.x;

			// since tray is displayed horizontally quickly eliminate taps based on y
			if ((Math.abs(y - y_i) > radius) || (i_x == 0)) return 0;

			if (Math.abs(x - x_i) < radius) {
				var slave_trait = object.parent.getTrait(SlaveFrameTrait);
				var max = slave_trait.get_max_grips();

				if (i_x > 0) i_x--;
				return (i_x + current_grip - 1)%max + 1;
			}
		}
		
		return 0;
	}

	public function is_dragged(x:FastFloat,y:FastFloat):Bool {
		var radius = offset.length()/2;

		var i_x:Int = Math.round((x - screen_loc.x)/offset.x);
		var y_i:FastFloat = screen_loc.y + i_x*offset.y;
		var x_i:FastFloat = screen_loc.x + i_x*offset.x;

		// since tray is displayed horizontally quickly eliminate taps based on y
		if (Math.abs(y - y_i) > radius) return false;
		else return true;
	}

	public function calculate_drag_index(v:Vec2) {
		var sign:Int = (v.dot(Vec2.xAxis()) >= 0) ? 1:-1;
		return sign*Math.round(v.length()/offset.length());
	}
}
