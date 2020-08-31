package arm;

using arm.ObjectTools;
using Lambda;

import kha.FastFloat;
import iron.object.Object;
import iron.Scene;
import iron.math.Vec4;
import iron.math.Quat;
import iron.math.Ray;
#if arm_physics
#if arm_oimo
import armory.trait.physics.oimo.PhysicsWorld;
#end
#if arm_bullet
import armory.trait.physics.PhysicsWorld;
#end
#end

import arm.JsonWallTrait;

class MasterFrameTrait extends iron.Trait {
	var slave_frame:Object = null;
	var json_wall:Object = null;
	#if arm_physics
	var physics:PhysicsWorld;
	#else
	var physics = null;
	#end
	
	@prop
	var slave_frame_name: String;
	@prop
	var mesh_name:String;
	
	public function new() {
		super();
		
		notifyOnInit(function() {
			#if arm_physics
			physics = armory.trait.physics.PhysicsWorld.active;
			#end
		});
		
		notifyOnUpdate(function() {
			if (slave_frame == null)
				slave_frame = Scene.active.getChild(slave_frame_name);
			if (json_wall == null) {
				json_wall = Scene.active.getChild(mesh_name);
				if (json_wall == null) Scene.active.spawnObject(mesh_name, null, null);
			}
		});
		
		// notifyOnRemove(function() {
		// });
	}
	
	function move_frame(x:Vec4,l_camera:Vec4) {
		moveToNearbyTile(
			x,
			l_camera
		);
	}
	
	public function get_slave() return slave_frame;
	
	public function get_wall():Wall {
		if (json_wall != null) {
			return json_wall.getTrait(JsonWallTrait).get_wall();
		}
		
		return null;
	}
	
	public function move_up() {
		move_frame(
			max_local(Scene.active.camera.transform.look()),
			Scene.active.camera.transform.loc
		);
	}
		
	public function move_down() {
		move_frame(
			max_local(Scene.active.camera.transform.look().clone().mult(-1)),
			Scene.active.camera.transform.loc
		);
	}
			
	public function move_right() {
		move_frame(
			max_local(Scene.active.camera.transform.right()),
			Scene.active.camera.transform.loc
		);
	}
				
	public function move_left() {
		move_frame(
			max_local(Scene.active.camera.transform.right().clone().mult(-1)),
			Scene.active.camera.transform.loc
		);
	}
					
	function max_local(c:Vec4):Vec4 {
		var locals:Array<Vec4> = [
			object.transform.local.up(),
			object.transform.local.up().clone().mult(-1),
			object.transform.local.look(),
			object.transform.local.look().clone().mult(-1),
			object.transform.local.right(),
			object.transform.local.right().clone().mult(-1)
		];
		var dots:Array<FastFloat> = locals.map(function(x) return x.dot(c));
		
		return locals[dots.indexOf(dots.fold(Math.max, dots[0]))].clone();
	}
					
	function moveToNearbyTile(x:Vec4,l_camera:Vec4):Bool {
		// get the location
		var l:Vec4 = object.transform.loc.clone();
		
		x.mult(2);
		
		// add the offset to the target and camera location
		l.add(x);
		
		// cast the ray and get the hit and make a ray from it
		#if arm_physics
		var hit = physics.rayCast(l_camera,l);
		var ray:Ray = PhysicsTools.hitToRay(hit,physics);
		return object.transformFrame(get_wall().hitray_to_local(ray));
		#else
		var ray:Ray = PhysicsTools.pointsToRay(l_camera,l);
		return object.transformFrame(get_wall().cameraray_to_local(ray));
		#end

		return false;
	}
}
					