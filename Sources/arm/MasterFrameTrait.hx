package arm;

import iron.math.Mat4;
using Lambda;
using arm.MatrixTools;

import kha.FastFloat;
import kha.Assets;
import kha.Blob;
import iron.object.Object;
import iron.Scene;
import iron.math.Vec4;
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
	var bucket:Bucket = null;
	#if arm_physics
	var physics:PhysicsWorld;
	#else
	var physics = null;
	#end
	var loaded_bucket:Blob = null;
	var loaded_volumes:Blob = null;
	
	@prop
	var slave_frame_name: String;
	@prop
	var mesh_name:String;
	@prop
	var bucket_name:String;
	
	public function new() {
		super();
		
		notifyOnInit(function() {
			#if arm_physics
			physics = armory.trait.physics.PhysicsWorld.active;
			#end

			// load the bucket blob
			#if js
			Assets.loadBlob("bucket_arm", function (b:Blob) {
			#else
			Assets.loadBlob("bucket_json", function (b:Blob) {
			#end
				loaded_bucket = b;
			});

			// load the volumes blob
			#if js
			Assets.loadBlob("volumes_arm", function (b:Blob) {
			#else
			Assets.loadBlob("volumes_json", function (b:Blob) {
			#end
				loaded_volumes = b;
			});
		});
		
		notifyOnUpdate(function() {
			if (slave_frame == null) {
				slave_frame = Scene.active.getChild(slave_frame_name);
			}
			if (json_wall == null) {
				json_wall = Scene.active.getChild(mesh_name);
				if (json_wall == null) Scene.active.spawnObject(mesh_name,null,null);
			}
			if ((bucket == null) && (loaded_bucket != null) && (loaded_volumes != null)) {
				load_bucket();
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

	function load_bucket() {
		bucket = new Bucket();
		#if js
		bucket.loadFromBytes(loaded_bucket.toBytes());
		bucket.loadFromBytes(loaded_volumes.toBytes());
		#else
		bucket.loadFromJsonString(loaded_bucket.toString());
		bucket.loadFromJsonString(loaded_volumes.toString());
		#end
		loaded_bucket.unload();
		loaded_volumes.unload();
		var temp_trait:SlaveFrameTrait = slave_frame.getTrait(SlaveFrameTrait);
		temp_trait.load_bucket(bucket);
	}
	
	public function get_slave() return slave_frame;
	
	public function get_wall():Wall {
		if (json_wall != null) {
			return json_wall.getTrait(JsonWallTrait).get_wall();
		}
		
		return null;
	}
	
	public function get_bucket():Bucket return bucket;
	
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
		var frame_trait:FrameTrait = object.getTrait(FrameTrait);
		var camera_trait:CameraTrait = Scene.active.camera.getTrait(CameraTrait);

		// get the location
		var l:Vec4 = object.transform.loc.clone();

		// get the closest frame to current location
		var current:Mat4 = camera_trait.pickClosestFrame(l.x,l.y,l.z);
		
		// set x to be the translation increment
		x.mult(0.25);

		var nearby:Mat4 = null;

		for (i in 1...12) {
			// add the offset to the target location
			l.add(x);
			
			// cast the ray and get the hit and make a ray from it
			nearby = camera_trait.pickClosestFrame(l.x,l.y,l.z);

			if (nearby.close(current) == false) break;
		}
		
		return frame_trait.transformFrame(nearby);
	}
}
					