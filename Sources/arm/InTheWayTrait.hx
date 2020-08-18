package arm;

import iron.math.Vec2;
import kha.Window;
import kha.FastFloat;
import iron.Scene;
import iron.object.CameraObject;
import iron.math.Vec4;
import iron.math.Mat4;
import iron.math.RayCaster;

class InTheWayTrait extends iron.Trait {
	static inline var ASPECT_LANDSCAPE = 1366.0/768.0;

	var w:Window;
	var cam:CameraObject;
	var aspect:FastFloat = 0;
	var last_aspect:FastFloat = 0;
	var scale:Vec4 = new Vec4();
	var offset:Vec4 = new Vec4();
	var screen_loc:Vec2 = new Vec2();

	@prop
	var width:Float = -1;
	@prop
	var modifiers:String = "";

	public function new() {
		super();

		// notifyOnInit(function() {
		// });

		// notifyOnUpdate(function() {
		// });

		notifyOnLateUpdate(function() {
			if (object.visible) {
				cam = Scene.active.camera;
				w = Window.get(0);
				aspect = w.width/w.height;

				if (aspect != last_aspect) {
					cam.buildProjection();
					set_scale();
					set_offset();
				}

				block_camera();

				last_aspect = aspect;
			} else last_aspect = 0.0;
		});

		// notifyOnRemove(function() {
		// });
	}

	function block_camera() {
		// get a matrix version of the cam_rot and apply to a new mat
		var cam_rot:Mat4 = Mat4.identity().fromQuat(cam.transform.rot);

		// set matrix
		object.transform.setMatrix(cam_rot);

		object.transform.scale.setFrom(scale);

		object.transform.loc.addvecs(
			cam.transform.loc,
			offset.clone().applyQuat(cam.transform.rot)
		);

		object.transform.buildMatrix();
	}

	function set_scale() {
		var s:FastFloat = 1;

		var w_length:FastFloat;
		if (w.width < w.height) {
			var left:Vec4 = RayCaster.getRay(0,0.5*w.height,cam).direction.normalize();
			var right:Vec4 = RayCaster.getRay(w.width,0.5*w.height,cam).direction.normalize();
			w_length = left.distanceTo(right);
		} else {
			var top:Vec4 = RayCaster.getRay(0.5*w.width,0,cam).direction.normalize();
			var bottom:Vec4 = RayCaster.getRay(0.5*w.width,w.height,cam).direction.normalize();
			w_length = top.distanceTo(bottom);
		}

		var temp:FastFloat = (width > 0) ? width : object.transform.dim.x;
		if (width == 0) temp = w_length;

		scale.set(
			w_length/temp,
			w_length/temp,
			1,
			0
		);
	}

	function set_offset() {
		var camera_trait = cam.getTrait(CameraTrait);
		var original_camera:CameraObject = camera_trait.get_original_camera();
		original_camera.data.raw.aspect = null;
		original_camera.buildProjection();

		var start = new Vec4();
		var end = new Vec4();
		set_screen_loc();
		RayCaster.getDirection(
			start,
			end,
			screen_loc.x,
			screen_loc.y,
			original_camera
		);
		
		offset.setFrom(end.sub(start).normalize());

		// if it is a background set the offset to be a little longer than nominal
		if (modifiers == "background") {
			offset.mult(1.01);
		}
	}

	function set_screen_loc() {
		var offset:Int = Math.round(0.1*Math.min(w.width,w.height));
		#if kha_js
		var bottom_y = js.Browser.window.innerHeight - offset;
		#else
		var bottom_y:Int = w.height - offset;
		#end
		var top_y = offset;
		if (modifiers == "bottom-right") screen_loc.set(w.width - offset,bottom_y);
		else if (modifiers == "bottom-left") screen_loc.set(offset,bottom_y);
		else if (modifiers == "bottom-center") screen_loc.set(0.5*w.width,bottom_y);
		else if (modifiers == "top-right")	screen_loc.set(w.width - offset,top_y);
		else if (modifiers == "top-left")	screen_loc.set(offset,top_y);
		else if (modifiers == "top-center")	screen_loc.set(0.5*w.width,top_y);
		else screen_loc.set(0.5*w.width,0.5*w.height);
	}

	public function is_clicked(x:FastFloat,y:FastFloat) {
		if (!object.visible) return false;
		
		var radius = 0.1*Math.min(w.width,w.height);

		return (screen_loc.distanceTo(new Vec2(x,y)) < radius);
	}

	public function get_screen_loc():Vec2 {
		return screen_loc;
	}
}
