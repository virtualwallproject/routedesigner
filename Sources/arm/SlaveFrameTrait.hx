package arm;

import iron.math.Mat4;
import iron.object.Transform;
import arm.Bucket.Volume;
using arm.ObjectTools;

import iron.Scene;
import iron.data.MaterialData;
import iron.data.MeshData;
import iron.math.Vec4;
import iron.object.Object;
import iron.object.CameraObject;
import iron.object.MeshObject;
import iron.data.Data;

import kha.FastFloat;

class SlaveFrameTrait extends iron.Trait {
	var master_frame:Object;
	var spawned_parent:Object;
	var current_grip:Int = 0;
	var next_grip:Int = 0;
	var used_grips:Array<Int> = new Array();
	var used_materials:Array<MaterialData> = new Array();
	var ape_materials:Array<MaterialData> = new Array();
	var camera:CameraObject;
	var tray_name:String = 'Tray';
	var max_grips:Int;

	@prop
	var master_frame_name:String;
	@prop
	var spawned_parent_name: String;
	@prop
	var rotation_step_deg:Float = 1;
	@prop
	var ape_length:Float = 2.0;

	public function new() {
		super();

		notifyOnInit(function() {
			var scene:Scene = Scene.active;
			camera = scene.camera;

			master_frame = scene.getChild(master_frame_name);
			
			if ((spawned_parent_name != null) && (spawned_parent_name != ""))
				spawned_parent = Scene.active.root.find_descendant(spawned_parent_name);
			reset_parent();

			for (name in ['Yellow', 'Green', 'Blue', 'Red', 'Black']) {
				Data.getMaterial("Scene", name, function(data:MaterialData) {
					ape_materials.push(data);
				});
			}

			// change the material of the slave frames children
			for (name in ['FlatFrame','MoveFrame','SpinFrame'])
				object.getChild(name).change_material(ape_materials[1]);
		});

		notifyOnUpdate(function() {
			if (master_frame.transform.diff()) {
				update_transform();
			} else if ((object.visible) && (current_grip != next_grip)) {
				update_grip();
			} else if ((!object.visible) && (current_grip != 0)) {
				add_to_used();
			}
		});

		// if the slave frame is hidden make sure its children are too
		// do this on late update because surface events might show a child
		// during update
		notifyOnLateUpdate(function() {
			if (!object.visible) for (k in object.children) k.setVisibility(false);
		});

		// notifyOnRemove(function() {
		// });
	}

	/**
	 * Set frame properties that are related to a bucket of holds
	 * @param bucket Bucket object with holds that this frame can spawn
	 */
	public function load_bucket(bucket:Bucket) {
		if (bucket != null) {
			max_grips = bucket.holds.length;
			if (object.properties == null) {
				object.properties = new Map<String, Dynamic>();
			}
			for (i in 0...max_grips) {
				object.properties['grip_${i+1}'] = bucket.holds[i].get_name();
			}
		}
	}

	public function get_spawned_parent():Object return spawned_parent;

	public function reset_parent() object.parent = spawned_parent;

	public function set_parent(name:String) {
		trace('setting parent ${name} from parent ${spawned_parent.name}');
		var temp:Object = spawned_parent.find_descendant(name);

		if (temp != null) object.parent = temp;
		else reset_parent();
		
		return (object.parent == null) ? false : true;
	}

	function grip_from_index(i:Int):Object {
		return spawned_parent.find_descendant(object.properties['grip_${i}']);
	}

	public function grip_name(i:Int):String {
		if (i == 0) return "";
		else return object.properties['grip_${i%(max_grips + 1)}'];
	}

	/**
	 * Helper fxn to update the slave frame transform to master
	 */
	public function update_transform() {
		if (current_grip == 0)
			object.transform.setMatrix(master_frame.transform.local);
		else {
			var grip:Object = grip_from_index(current_grip);

			// scale the frame to object if it is a volume
			var bucket:Bucket = master_frame.getTrait(MasterFrameTrait).get_bucket();
			var volume:Volume = bucket.get_volume(grip.name);
			var scale:FastFloat = (volume == null) ? null : 2*volume.get_scale()/object.FRAME_DIM();

			object.transformFrameToGrip(grip,scale);
		}
	}

	/**
	 * [Description] Set the current grip based on the index in the frame's
	 * property list:
	 * if it is non-zero the frame is also transformed to the grip
	 * if it is zero then the frame is transformed to the master frame
	 * @param index
	 */
	public function set_current_grip(index:Int) {
		current_grip = index;
		next_grip = index;
		if (current_grip != 0) {
			var grip:Object = grip_from_index(current_grip);

			// scale the frame to object if it is a volume
			var bucket:Bucket = master_frame.getTrait(MasterFrameTrait).get_bucket();
			var volume:Volume = bucket.get_volume(grip.name);
			var scale:FastFloat = (volume == null) ? null : 2*volume.get_scale()/object.FRAME_DIM();

			object.transformFrameToGrip(grip,scale);
		} else {
			update_transform();
		}
		get_tray().getTrait(TrayTrait).set_slave_grip(current_grip);
	}

	/**
	 * [Description] Add the current grip index to the used grip array and set
	 * the current grip to zero
	 */
	public function add_to_used() {
		// set the current grip as used
		if (current_grip != 0) used_grips.push(current_grip);
		set_current_grip(0);
	}

	public function show_grip(i:Int) {
		if ((i >= 0) && (i < max_grips+1)) next_grip = i;
	}

	public function show_next_grip() {
		if (next_grip == max_grips) {
			next_grip = 0;
		} else {
			next_grip += 1;
		}
		if (used_grips.indexOf(next_grip) >= 0) {
			show_next_grip();
		}
	}

	public function show_prev_grip() {
		if (next_grip == 0) {
			next_grip = max_grips;
		} else {
			next_grip += -1;
		}
		if (used_grips.indexOf(next_grip) >= 0) {
			show_prev_grip();
		}
	}

	public function rotate_cw() {
		rotate_grip(-rotation_step_deg*Math.PI/180.0);
	}

	public function rotate_ccw() {
		rotate_grip(rotation_step_deg*Math.PI/180.0);
	}

	public function move_left(s:FastFloat=1.0) {
		var temp:Vec4 = camera.transform.right().clone();
		move_grip(temp.mult(-1*s));
	}

	public function move_right(s:FastFloat=1.0) {
		var temp:Vec4 = camera.transform.right().clone();
		move_grip(temp.mult(s));
	}

	public function move_down(s:FastFloat=1.0) {
		var temp:Vec4 = camera.transform.look().clone();
		move_grip(temp.mult(-1*s));
	}

	public function move_up(s:FastFloat=1.0) {
		var temp:Vec4 = camera.transform.look().clone();
		move_grip(temp.mult(s));
	}

	/**
	 * Show the default frame
	 */
	public function show_default() {
		object.getChild('FlatFrame').setVisibility(true);
		object.getChild('MoveFrame').setVisibility(false);
		object.getChild('SpinFrame').setVisibility(false);
	}

	/**
	 * Show the grip move frame
	 */
	public function show_move() {
		if (current_grip == 0) show_default();
		else {
			object.getChild('FlatFrame').setVisibility(false);
			object.getChild('MoveFrame').setVisibility(true);
			object.getChild('SpinFrame').setVisibility(false);
		}
	}

	/**
	 * Show the spin frame
	 */
	public function show_spin() {
		if (current_grip == 0) show_default();
		else {
			object.getChild('FlatFrame').setVisibility(false);
			object.getChild('MoveFrame').setVisibility(false);
			object.getChild('SpinFrame').setVisibility(true);
		}
	}

	/**
	 * Figure out what kind of frame is shown
	 * @return Int 0: default, 1: move, 2: spin, else -1 is returned
	 */
	public function get_shown():Int {
		if (object.getChild('FlatFrame').visible) return 0;
		if (object.getChild('MoveFrame').visible) return 1;
		if (object.getChild('SpinFrame').visible) return 2;
		return -1;
	}

	/**
	 * [Description] Return the spherical radius of the sphere containing the 
	 * master frame
	 */
	function r():FastFloat {
		var s:Vec4 = master_frame.transform.scale;
		var max_s:FastFloat = if (s.x >= s.y) s.x else s.y;
		return Math.sqrt(3.0*Math.pow(max_s,2));
	}

	public function spawn_grip(name:String, parent:Object, done: Object->Void):Object {
		var bucket:Bucket = master_frame.getTrait(MasterFrameTrait).get_bucket();
		var temp:Object = bucket.spawnGripByName(name,parent,done);

		return temp;
	}

	/**
	 * This automatically activates any grip near to this frame
	 */
	public function activate_grip() {
		var inside_grip:Object = null;
		var i:Int = 0;
		var r:FastFloat = r();
		while ((inside_grip == null) && (i < used_grips.length)) {
			var grip:Object = grip_from_index(used_grips[i]);
			var mesh:MeshObject = cast(grip,MeshObject);
			if (grip.transform.loc.distanceTo(master_frame.transform.loc) <
				Math.max(mesh.data.scalePos,r)) {
				inside_grip = grip;
			} else {
				i++;
			}
		}

		if (inside_grip != null) {
			// if there is a current grip then set it
			if (current_grip != 0) {
				add_to_used();
			}
			set_current_grip(used_grips.splice(i,1)[0]);
		}
	}

	public function update_grip() {
		// remove the old grip from scene
		if (current_grip != 0){
			var grip:Object = grip_from_index(current_grip);
			grip.remove();
		}

		// spawn the new grip
		if (next_grip != 0) {
			var next_grip_name = object.properties['grip_${next_grip}'];
			spawn_grip(next_grip_name,object.parent,(grip:Object) -> {
				// rotation
				grip.transform.rot.setFrom(object.transform.rot);
      
				// translation
				grip.transform.loc.applyQuat(object.transform.rot).add(object.transform.loc);
				
				// update the transform
				grip.transform.buildMatrix();
			});
		}

		// set the current grip index to the next grip index
		set_current_grip(next_grip);
	}

	/**
	 * [Description] Rotate the current hold by a certain angle in radians
	 * @param angle 
	 */
	public function rotate_grip(angle:FastFloat) {
		if (current_grip != 0) {
			var grip:Object = grip_from_index(current_grip);
			var temp:Mat4 = grip.transform.local;//Mat4.identity().setFrom(grip.transform.local).toRotation();
			grip.transform.rotate(temp.up(),angle);
			object.transformFrameToGrip(grip);
		}
	}

	/**
	 * [Description] Move the current hold along a vector
	 * @param v 
	 */
	public function move_grip(a:Vec4) {
		if (current_grip != 0) {
			var grip:Object = grip_from_index(current_grip);

			// transform the vector into the grip's local frame
			var temp:Mat4 = Mat4.identity();
			temp.setFrom(grip.parent.transform.world).toRotation();
			temp.getInverse(temp);
			var local_a:Vec4 = a.clone();
			local_a.applymat(temp);

			temp = Mat4.identity().setFrom(grip.transform.local).toRotation();
			var scale:FastFloat = 0.002;
			var b1:Vec4 = temp.right();
			var b2:Vec4 = temp.look();
			var v:Vec4 = b1.mult(local_a.dot(b1)).add(b2.mult(local_a.dot(b2)));
			grip.transform.translate(scale*v.x,scale*v.y,scale*v.z);
			object.transformFrameToGrip(grip);
		}
	}

	/**
	 * [Description] Color used grips by distance to frame
	 * Yellow <0.3 ape index
	 * Green 0.3-0.6 ape index
	 * Blue 0.6-1 ape index
	 * Red 1-1.5 ape index
	 * Black 1.5+ ape index
	 */
	public function color_grips() {
		if (used_materials.length == 0) {
			// loop through the used grip indices and color each
			for (i in used_grips) {
				var grip:Object = grip_from_index(i);

				// compute distance to figure out what material we want to use
				var dist:FastFloat = grip.transform.loc.distanceTo(object.transform.loc);
				var new_mat:MaterialData = ape_materials[ape_materials.length-1];
				if (dist < 1.5*ape_length) {
					new_mat = ape_materials[ape_materials.length-2];
					if (dist < ape_length) {
						new_mat = ape_materials[ape_materials.length-3];
						if (dist < 0.6*ape_length) {
							new_mat = ape_materials[ape_materials.length-4];
							if (dist < 0.3*ape_length) {
								new_mat = ape_materials[ape_materials.length-5];
							}
						}
					}
				}

				// change the material and push the returned material on used
				// list
				used_materials.push(grip.change_material(new_mat));
			}
		}
	}

	/**
	 * [Description] Recolor grips by their original colors
	 */
	public function recolor_grips() {
		if (used_materials.length > 0) {
			for (i in 0...used_grips.length) {
				var grip:Object = grip_from_index(used_grips[i]);
				grip.change_material(used_materials[i]);
			}
			used_materials = new Array();
		}
	}

	/**
	 * Returns number of grips currently used
	 * @return Int return this.used_grips.length
	 */
	public function get_num_used():Int return this.used_grips.length;

	public function get_current_grip():Int return this.current_grip;

	public function get_max_grips():Int return this.max_grips;

	public function get_tray():Object return this.object.getChild(tray_name);

	/**
	 * Returns the volumes that are currently on the wall
	 * @return Array<Volume>
	 */
	public function get_volumes_used():Array<Volume> {
		var bucket:Bucket = master_frame.getTrait(MasterFrameTrait).get_bucket();
		var used_volumes:Array<Volume> = new Array<Volume>();

		for (i in 0...used_grips.length) {
			var grip:Object = grip_from_index(used_grips[i]);
			var volume:Volume = bucket.get_volume(grip.name);
			if (volume != null) {
				used_volumes.push(volume);
				// update the local transformation matrix for the volume
				volume.set_local(grip.transform.local);
			}
		}

		return used_volumes;
	}

	/**
	 * Returns true if hold i is used
	 * @param i name number of the hold
	 * @return Bool If the hold is used true else false
	 */
	public function is_used(i:Int):Bool return (used_grips.indexOf(i) >= 0);

	/**
	 * [Description]
	 * @param id The int id of the grip to be removed
	 * @return Bool If the grip was removed
	 */
	public function remove_grip(id:Int):Bool {
		if (used_grips.remove(id)) {
			var grip:Object = grip_from_index(id);
			grip.remove();
			return true;
		} else return false;
	}

	public function remove_grips() {
		for (i in used_grips) {
			remove_grip(i);
		}
	}

}
