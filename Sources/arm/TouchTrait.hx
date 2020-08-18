package arm;

import iron.math.Vec4;
import kha.FastFloat;
import iron.math.Vec2;
import iron.App;
import iron.Scene;
import iron.data.MaterialData;
import iron.object.Object;
import iron.object.CameraObject;
import iron.object.MeshObject;

using Lambda;

class TouchTrait extends iron.Trait {
    var scene:Scene;
    var camera:CameraObject;
	var objects:Array<Object>;
	var meshes:Array<MeshObject>;
	var original_material:MaterialData;
	var materials:Array<MaterialData> = new Array();
	var index:Int = 0;

    var radius:Int;

    var touches:Array<Bool> = [false, false, false];
    var touched:Int = -1;
    var start:Array<Vec2> = [new Vec2(), new Vec2(), new Vec2()];
    var last:Array<Vec2> = [new Vec2(), new Vec2(), new Vec2()];
    var max:Array<Vec2> = [new Vec2(), new Vec2(), new Vec2()];

	public function new() {
		super();

		notifyOnInit(function() {
            // initialize stuff we need to work with scene
            scene = Scene.active;
            camera = Scene.active.camera;
            objects = [
                scene.getChild('Cube'),
                scene.getChild('Icosphere'),
                scene.getChild('Suzanne'),
            ];
			meshes = [for (object in objects) cast(object,MeshObject)];
			original_material = meshes[0].materials[0];
            for (name in ['Green', 'Red', 'Blue']) {
				var o:Object = scene.getChild(name);
				if (o != null) {
					var m:MeshObject = cast(o,MeshObject);
					materials.push(m.materials[0]);
				}
			}
            
            // initialize stuff we need for multitouc
            if (App.w() > App.h()) {
                radius = Math.round(App.h()/10);
            } else {
                radius = Math.round(App.w()/10);
            }
			var surface = kha.input.Surface.get();
			if (surface != null) surface.notify(touchStart, touchEnd, touchMove);
            notifyOnUpdate(update);
		});
    }
    
	/**
	 * Handles any continuous actions like moving camera or holds
	 */
	function update() {
		if (touches[0] && touches[1] && !touches[2]) {
            adjust_camera();
        } else if (touches[0] && touches[1] && touches[2]) {
            move_grip();
            scale_up();
        }

        if (!touches[2]) scale_down();
	}

	function touchStart(index:Int, x:Int, y:Int) {
        if (index > 2) return;
        
        touches[index] = true;

        start[index].set(x,y);
        last[index].set(x,y);
        max[index].set(x,y);

        touched = index;
	}

	function touchEnd(index:Int, x:Int, y:Int) {
        if (index > 2) return;

        touches[index] = false;

        if (index == 0) {
            if (touched == 0) {
                one_finger_move();
            } else if (touched == 1) {
                two_finger_move();
            }
        
            for (i in 0...2) {
                start[i].set(0,0);
                last[i].set(0,0);
                max[i].set(0,0);
            }

            touched = -1;
        }
    }

	function touchMove(index:Int, x:Int, y:Int) {
        last[index].set(x,y);
        if (last[index].distanceTo(start[index]) >
            max[index].distanceTo(start[index])) max[index].set(x,y);
    }

    /**
     * Check one finger moves
     */
    function one_finger_move() {
        var temp:Array<Vec2> = [move_max(0)];

        if (temp[0].length() < radius) one_finger_click();
        else one_finger_drag();
    }

    /**
     * Handle single finger clicks
     */
    function one_finger_click() {
        color_meshes();
    }

    /**
     * Handle single finger drags
     */
    function one_finger_drag() {
        trace("1 - drag");
    }

    function two_finger_move() {
        var temp:Array<Vec2> = [move_max(0),move_max(1)];

        if ((temp[0].length() < radius) && (temp[1].length() < radius)) {
            two_finger_click();
        }
    }

    /**
     * Handle two finger clicks
     */
    function two_finger_click() {
        if (objects[0].visible) {
            objects[0].visible = false;
            objects[1].visible = true;
        } else  if (objects[1].visible) {
            objects[1].visible = false;
            objects[2].visible = true;
        } else  if (objects[2].visible) {
            objects[2].visible = false;
            objects[0].visible = true;
        }
    }
    
    /**
     * Check two finger drag that adjust camera
     */
    function adjust_camera() {
        var camera_trait = camera_trait();
        
        // check for zooming
        var dist_start:FastFloat = start[0].distanceTo(start[1]);
        var dist_last:FastFloat = last[0].distanceTo(last[1]);
        if (dist_start > dist_last + radius) {
            camera_trait.zoom_out();
        } else if (dist_start + radius < dist_last) {
            camera_trait.zoom_in();
        }
        
        // check for moving
        // now make only one motion happen at a time
        var temp:Array<Vec2> = [move_last(0),move_last(1)];
        for (v in temp) {
            if (Math.abs(v.x) > Math.abs(v.y)) v.y = 0;
            else v.x = 0;
        }

        if (Math.abs(temp[0].x) > radius) {
            var xs:Array<FastFloat> = [for (v in temp) v.x];
            // if moved enough in x with two fingers move the camera left-right
            if (xs.foreach(function(v) return v > radius)) {
                camera_trait.move_left(0.5);
            } else if (xs.foreach(function(v) return v < -radius)) {
                camera_trait.move_right(0.5);
            }
        } else if (Math.abs(temp[0].y) > radius) {
            var ys:Array<FastFloat> = [for (v in temp) v.y];
            // if moved enough in y with two fingers move the camera up down
            if (ys.foreach(function(v) return v > radius)) {
                camera_trait.move_up();
            } else if (ys.foreach(function(v) return v < -radius)) {
                camera_trait.move_down();
            }
        }
    }
    
    /**
     * Check three finger drag that adjust camera
     */
    function move_grip() {
        // make only one motion happen at a time
        var temp:Array<Vec2> = [move_last(0),move_last(1),move_last(2)];
        for (v in temp) {
            if (Math.abs(v.x) > Math.abs(v.y)) v.y = 0;
            else v.x = 0;
        }

        if (Math.abs(temp[0].x) > radius) {
            var xs:Array<FastFloat> = [for (v in temp) v.x];
            // if moved enough in x with two fingers move the object left-right
            if (xs.foreach(function(v) return v > radius)) {
                move_objects(camera.transform.right());
            } else if (xs.foreach(function(v) return v < -radius)) {
                move_objects(camera.transform.right().clone().mult(-1));
            }
        } else if (Math.abs(temp[0].y) > radius) {
            var ys:Array<FastFloat> = [for (v in temp) v.y];
            // if moved enough in y with two fingers move the camera up down
            if (ys.foreach(function(v) return v < -radius)) {
                move_objects(camera.transform.look());
            } else if (ys.foreach(function(v) return v > radius)) {
                move_objects(camera.transform.look().clone().mult(-1));
            }
        }
    }

    /**
     * This scales up the objects and gets called for a three finger touch
     */
    function scale_up() {
        for (object in objects) {
            object.transform.scale.mult(1.001);
            object.transform.dirty = true;
        }
    }

    /**
     * This scales down objects until 1
     */
    function scale_down() {
        var temp:Vec4 = new Vec4(1,1,1);
        if (objects[0].transform.scale.x > 1) {
            temp = objects[0].transform.scale.clone().mult(0.999);
        }
        for (object in objects) {
            object.transform.scale = temp;
            object.transform.dirty = true;
        }
    }

    function camera_trait() {
        if (camera != null)
            return camera.getTrait(CameraTrait);

        throw "Camera is null";
        scene.getTrait(SceneTrait).shutdown();
        
        return null;
    }

    /**
     * Color the meshes of the cube, sphere, and suzanne
     */
    function color_meshes() {
        var next_index:Int = index + 1;
        if (next_index > materials.length) {
            next_index = 0;
        }

        index = next_index;
        for (mesh in meshes) {
            if (index == 0) {
                for (i in 0...mesh.materials.length) {
                    mesh.materials[i] = original_material;
                }
            } else {
                for (i in 0...mesh.materials.length) {
                    mesh.materials[i] = materials[index-1];
                }
            }
        }
    }

    /**
     * Move the objects along the vector v
     * @param v vector to translate on
     */
    function move_objects(v:Vec4) {
        var step:FastFloat = 0.05;
        for (object in objects) {
            object.transform.translate(step*v.x,step*v.y,step*v.z);
        }
    }

    /**
     * Returns the difference of the last and the start
     */
    function move_last(i:Int) {
        return (new Vec2()).subvecs(last[i],start[i]);
    }

    /**
     * Returns the difference of the max and the start
     */
    function move_max(i:Int) {
        return (new Vec2()).subvecs(max[i],start[i]);
    }
}
