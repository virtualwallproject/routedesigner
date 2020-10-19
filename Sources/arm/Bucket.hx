package arm;

import kha.FastFloat;
import iron.object.Object;
import iron.object.MeshObject;
import iron.Scene;
import haxe.io.Bytes;
import haxe.Json;
import haxe.DynamicAccess;
import iron.data.MeshData;
import iron.data.MaterialData;
import iron.system.ArmPack;

using arm.MapTools;

class Bucket {
  public var holds:Array<Hold>;
  var names:Map<String,Int>;

	public function new() {
    holds = new Array<Hold>();
    names = new Map<String,Int>();
	}

	public function loadFromBytes(b:Bytes) {
		var j:DynamicAccess<Dynamic> = ArmPack.decode(b);
		loadFromMap(j);
	}

	public function loadFromJsonString(s:String) {
		//Parse value from stringy json
		var j:DynamicAccess<Dynamic> = Json.parse(s);
    loadFromMap(j);
	}
	
	function loadFromMap(m:DynamicAccess<Dynamic>) {
		for (key => value in m) {
      holds.push(new Hold(key));
      names[key] = holds.length-1;
			var current_hold:Hold = holds[names[key]];
			current_hold.loadFromMap(value);
		}
  }
  
  public function spawnGripByName(name:String, parent:Object, done: Object->Void):Object {
    var temp:Hold = holds[names[name]];
    var temp2:Object = Scene.active.addMeshObject(temp.get_data(),temp.get_materials(),parent);
    temp2.transform.dim.mult(temp.get_scale());
    temp2.name = name;
    if (done != null) done(temp2);

    return temp2;
  }
}

class Hold {
	var name:String;
	var meshData:MeshData;
  var materials:haxe.ds.Vector<MaterialData>;
  var scale_pos:FastFloat;
	
	public function new(name:String) {
		this.name = name;
	}

  public function get_name():String return name;
  
  public function get_data():MeshData return meshData;

  public function get_scale():FastFloat return scale_pos;
  
  public function get_materials():haxe.ds.Vector<MaterialData> return materials;
	
	public function loadFromMap(m:DynamicAccess<Dynamic>) {
		var o:DynamicAccess<Dynamic> = m.mapToMeshData(this.get_name());
		meshData = o['meshdata'];
    materials = o['materials'];
    scale_pos = o['scale_pos'];
	}
}