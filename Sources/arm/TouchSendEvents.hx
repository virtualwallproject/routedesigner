package arm;

import iron.math.Vec2;
import iron.App;
import iron.Scene;
import iron.object.Object;
import iron.object.CameraObject;
import kha.FastFloat;
import kha.input.Surface;

using Lambda;

class TouchSendEvents extends iron.Trait {
    var scene:Scene;
    var camera:CameraObject;
    var frame:Object;
    var slave_frame:Object;

    var radius:Int = 20;

    var touches:Array<Bool> = [false, false, false];
    var touched:Int = -1;
    var start:Array<Vec2> = [new Vec2(), new Vec2(), new Vec2()];
    var last:Array<Vec2> = [new Vec2(), new Vec2(), new Vec2()];
    var max:Array<Vec2> = [new Vec2(), new Vec2(), new Vec2()];

	public function new() {
		super();

		notifyOnInit(function() {
            scene = Scene.active;
            camera = scene.camera;
            frame = camera_trait().get_frame();
            slave_frame = frame.getTrait(MasterFrameTrait).get_slave();
            
            // initialize stuff we need for multitouch
            if (App.w() > App.h()) {
                radius = Math.round(App.h()/20);
            } else {
                radius = Math.round(App.w()/20);
            }
            trace('Radius=${radius}');
			var surface = Surface.get();
			if (surface != null) surface.notify(touchStart, touchEnd, touchMove);
        });
        
        notifyOnUpdate(update);
    }
    
	/**
	 * Handles any continuous actions like moving camera or holds
	 */
	function update() {
        var frame_traits = [frame.getTrait(FrameTrait),
                            slave_frame.getTrait(FrameTrait)];
        var slave_trait = slave_frame.getTrait(SlaveFrameTrait);

        if (touches[0] && !touches[1] && !touches[2]) {
            one_finger_drag();
        } else if (touches[0] && touches[1] && !touches[2]) {
            adjust_camera();
        } else if (touches[0] && touches[1] && touches[2] && slave_frame.visible) {
            slave_trait.color_grips();
            move_grip();
        }

        if (!touches[2] || frame_traits[0].is_active())
            slave_trait.recolor_grips();
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
        else {
            var master_trait = frame.getTrait(MasterFrameTrait);
            var slave_trait = slave_frame.getTrait(SlaveFrameTrait);
            
            // check for moving
            // now make only one motion happen at a time
            var temp:Array<Vec2> = [move_last(0)];
            for (v in temp) {
                if (Math.abs(v.x) > Math.abs(v.y)) v.y = 0;
                else v.x = 0;
            }

            if (Math.abs(temp[0].x) > radius) {
                var xs:Array<FastFloat> = [for (v in temp) v.x];
                if (xs.foreach(function(v) return v > radius)) {
                    if (frame.visible) master_trait.move_right();
                } else if (xs.foreach(function(v) return v < -radius)) {
                    if (frame.visible) master_trait.move_left();
                }
            } else if (Math.abs(temp[0].y) > radius) {
                var ys:Array<FastFloat> = [for (v in temp) v.y];
                if (ys.foreach(function(v) return v > radius)) {
                    if (frame.visible) master_trait.move_down();
                    else if (slave_frame.visible) slave_trait.show_prev_grip();
                } else if (ys.foreach(function(v) return v < -radius)) {
                    if (frame.visible) master_trait.move_up();
                    else if (slave_frame.visible) slave_trait.show_next_grip();
                }
            }
        }
    }

    /**
     * Handle single finger clicks
     */
    function one_finger_click() {
        var frame_trait = frame.getTrait(FrameTrait);
        var camera_trait = camera_trait();
        if (frame_trait.is_active()) {
            camera_trait.click_frame(last[0].x,last[0].y);
        } else if (slave_frame.visible) {
            var slave_trait = slave_frame.getTrait(SlaveFrameTrait);
            slave_trait.activate_grip();
        }
    }

    /**
     * Handle single finger drags
     */
    function one_finger_drag() {
        var master_trait = frame.getTrait(MasterFrameTrait);
        var slave_trait = slave_frame.getTrait(SlaveFrameTrait);

        // check for moving
        // now make only one motion happen at a time
        var temp:Array<Vec2> = [move_last(0)];
        for (v in temp) {
            if (Math.abs(v.x) > Math.abs(v.y)) v.y = 0;
            else v.x = 0;
        }

        if (Math.abs(temp[0].x) > radius) {
            var xs:Array<FastFloat> = [for (v in temp) v.x];
            if (xs.foreach(function(v) return v > radius)) {
                if (slave_frame.visible) slave_trait.rotate_cw();
            } else if (xs.foreach(function(v) return v < -radius)) {
                if (slave_frame.visible) slave_trait.rotate_ccw();
            }
        }
    }

    function two_finger_move() {
        var temp:Array<Vec2> = [move_max(0),move_max(1)];

        if ((temp[0].length() < radius) && (temp[1].length() < radius))
            two_finger_click();
    }

    /**
     * Handle two finger clicks
     */
    function two_finger_click() {
        var frame_traits = [frame.getTrait(FrameTrait),
                            slave_frame.getTrait(FrameTrait)];
        for (frame in frame_traits) frame.toggle_active();
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
     * Check three finger drag that adjust hold position
     */
    function move_grip() {
        var slave_trait = slave_frame.getTrait(SlaveFrameTrait);

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
                slave_trait.move_right();
            } else if (xs.foreach(function(v) return v < -radius)) {
                slave_trait.move_left();
            }
        } else if (Math.abs(temp[0].y) > radius) {
            var ys:Array<FastFloat> = [for (v in temp) v.y];
            // if moved enough in y with two fingers move the camera up down
            if (ys.foreach(function(v) return v < -radius)) {
                slave_trait.move_down();
            } else if (ys.foreach(function(v) return v > radius)) {
                slave_trait.move_up();
            }
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
