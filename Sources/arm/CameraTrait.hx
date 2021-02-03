package arm;

using Lambda;
using arm.ObjectTools;

import kha.FastFloat;
import kha.Window;
import iron.Scene;
import iron.math.Vec4;
import iron.math.Mat4;
import iron.math.Ray;
import iron.math.RayCaster;
import iron.object.Object;
import iron.object.CameraObject;
#if arm_physics
#if arm_oimo
import armory.trait.physics.oimo.PhysicsWorld;
#end
#if arm_bullet
import armory.trait.physics.PhysicsWorld;
#end
#end

import arm.CameraPath;
import arm.CameraSurface;
import arm.PhysicsTools;

class CameraTrait extends iron.Trait {
	var w:Window;
	var camera:CameraObject;
	var original_camera:CameraObject;
	var target:Circle;
	var path:Circle;
	var surf:CameraCircle;
	#if arm_physics
	var physics:PhysicsWorld;
	#else
	var physics = null;
	#end
	var frame:Object = null;
	var v0:Vec4 = new Vec4();
	var v1:Vec4 = new Vec4();
	var dot_threshold = Math.PI/90.0;
	
	@prop
	var path_radius:Float = 5.0;
	@prop
	var target_radius:Float = 0.5;
	@prop
	var target_height:Float = 0.0;
	@prop
	var initial_height:Float = 2.5;
	@prop
	var min_height:Float = 0.2;
	@prop
	var max_height:Float = 3.0;
	@prop
	var frame_name: String;
	
	public function new() {
		super();
		
		notifyOnInit(function() {
			object.transform.localOnly = true;
			
			// should check that the frame and clipping objects are found
			
			// initialize class variables
			w = Window.get(0);
			camera = Scene.active.camera;
			original_camera = new CameraObject(camera.data);
			target = new Circle(target_height,null,target_radius);
			surf = new CameraCircle(target);
			surf.set_v_range(path_radius-2,path_radius+2);
			surf.set_z_range(min_height,max_height);
			#if arm_physics
			physics = armory.trait.physics.PhysicsWorld.active;
			#end
		});
		
		notifyOnUpdate(function() {
			if (frame == null) frame = Scene.active.getChild(frame_name);
			if (frame != null) {
				v1.subvecs(frame.transform.loc,camera.transform.loc);
				if (!v0.almostEquals(v1,0.1)) {
					updateDotThreshold();
				}
			}
			object.transform.setMatrix(surf.transform());
		});
		
		// notifyOnRemove(function() {
		// });
	}

	/**
	 * Called in notifyOnUpdate if the distance from camera to frame has changed
	 */
	function updateDotThreshold() {
		v0.setFrom(v1);
		var temp:FastFloat = 0.5*frame.transform.dim.x;
		dot_threshold = Math.asin(temp/v0.length());
	}
	
	public function get_frame() return frame;
	
	public function zoom_in() surf.decrement_v();
	
	public function zoom_out() surf.increment_v();
	
	public function move_left(s:FastFloat=1.0) surf.decrement_u(s);
	
	public function move_right(s:FastFloat=1.0) surf.increment_u(s);
	
	public function move_down(s:FastFloat=1.0) surf.decrement_z(s);
	
	public function move_up(s:FastFloat=1.0) surf.increment_z(s);
	
	public function pickClosestFrame(inputX:FastFloat, inputY:FastFloat):Mat4 {
		if (frame != null) {
			var master = frame.getTrait(MasterFrameTrait);
			if (master.get_wall() != null) {
				var closest_locals:Array<Mat4> = new Array<Mat4>();
				var start = new Vec4();
				var end = new Vec4();
				// set the start and end vectors based on screen location
				RayCaster.getDirection(start, end, inputX, inputY, camera);

				#if arm_physics
				var hit = physics.rayCast(camera.transform.world.getLoc(), end);
				var ray:Ray = PhysicsTools.hitToRay(hit,physics);
				closest_locals.push(master.get_wall().hitray_to_local(ray);
				#else
				var ray:Ray = PhysicsTools.pointsToRay(start,end);
				closest_locals.push(master.get_wall().cameraray_to_local(ray));
				#end

				for (i => v in master.get_slave().getTrait(SlaveFrameTrait).get_volumes_used()) {
					var temp:Mat4 = v.cameraray_to_local(ray);
					if (temp != null) closest_locals.push(temp);
				}

				// this code is mostly copied over from Wall.ray_to_local
				// but modified now to make sure we pick the tnut closer to the camera
				// only if the possible locations are both close to the ray
				var dist_to_ray = (x:Mat4) -> {
					var hyp:FastFloat = ray.origin.distanceTo(x.getLoc());
					var opp:FastFloat = ray.distanceToPoint(x.getLoc());
					if (Math.asin(opp/hyp) < 5.0*Math.PI/180.0) {
						return camera.transform.world.getLoc().distanceTo(x.getLoc());
					} else {
						return Math.POSITIVE_INFINITY;
					}
				}
				var min_index = function(x:Array<FastFloat>):Int
					return x.indexOf(x.fold(Math.min, x[0]));
				var loc_distances:Array<FastFloat> = closest_locals.map(dist_to_ray);

				return closest_locals[min_index(loc_distances)];
			}
		}
		
		return null;
	}

	/**
	 * Compute the dot product between a screen location and the active hold
	 * @param x X value of screen location
	 * @param y Y value of screen location
	 * @return FastFloat The dot product between active hold and input screen location
	 */
	public function dotActiveHold(x:FastFloat, y:FastFloat):FastFloat {
		if (frame != null) {
			var master = frame.getTrait(MasterFrameTrait);
			var slave_trait = master.get_slave().getTrait(SlaveFrameTrait);
			if (slave_trait.get_current_grip() != 0) {
				var start = new Vec4();
				var end = new Vec4();
				// set the start and end vectors based on screen location
				RayCaster.getDirection(start, end, x, y, camera);

				// get rays pointing to touched location and the slave frame
				var input_ray:Ray = PhysicsTools.pointsToRay(start,end);
				var frame_ray:Ray = PhysicsTools.pointsToRay(start,master.get_slave().transform.loc);

				return input_ray.direction.dot(frame_ray.direction);
			}
		}
		
		return Math.NaN;
	}

	/**
	 * Check for rotation around active hold for two screen locations
	 * @param x0 X value of start screen location
	 * @param y0 Y value of start screen location
	 * @param x1 X value of end screen location
	 * @param y1 Y value of end screen location
	 * @return FastFloat >0 for ccw <0 for cw rotation
	 */
	public function spinActiveHold(x0:FastFloat, y0:FastFloat, x1:FastFloat, y1:FastFloat):FastFloat {
		if (frame != null) {
			var master = frame.getTrait(MasterFrameTrait);
			var slave_trait = master.get_slave().getTrait(SlaveFrameTrait);
			if (slave_trait.get_current_grip() != 0) {
				var start = new Vec4();
				var xy0 = new Vec4();
				var xy1 = new Vec4();
				// set the end vectors based on screen location
				RayCaster.getDirection(start,xy0,x0,y0,camera);
				RayCaster.getDirection(start.set(0,0,0),xy1,x1,y1,camera);

				var input0:Ray = PhysicsTools.pointsToRay(start,xy0);
				var input1:Ray = PhysicsTools.pointsToRay(start,xy1);
				var frame_ray:Ray = PhysicsTools.pointsToRay(start,master.get_slave().transform.loc);

				var check0:FastFloat = input0.direction.dot(frame_ray.direction);

				if ((Math.cos(2*dot_threshold) < check0) && (check0 < Math.cos(dot_threshold))) {
					var v0:Vec4 = input0.direction.sub(frame_ray.direction);
					var v1:Vec4 = input1.direction.sub(frame_ray.direction);
					var xprod:Vec4 = v1.normalize().cross(v0.normalize());
	
					return frame_ray.direction.normalize().dot(xprod.normalize());
				}
			}
		}

		return Math.NaN;
	}
	
	public function click_frame(x:FastFloat, y:FastFloat):Bool {
		return frame.transformFrame(pickClosestFrame(x,y));
	}

	public function click_hold(x:FastFloat, y:FastFloat):Bool {
		var picked:FastFloat = dotActiveHold(x,y);
		if ((frame != null) && (!Math.isNaN(picked))) return (picked > Math.cos(dot_threshold));

		return false;
	}
	
	public function pick_center_tile() {
		click_frame(w.width/2.0,w.height/2.0);
	}
	
	public function get_original_camera():CameraObject return original_camera;
	
}
