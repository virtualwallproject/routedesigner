package arm;

import iron.math.Mat4;
import iron.math.Ray;
import iron.math.Vec4;
import kha.FastFloat;
import iron.object.Object;
import iron.Scene;
import haxe.io.Bytes;
import haxe.Json;
import haxe.DynamicAccess;
import iron.data.MeshData;
import iron.data.MaterialData;
import iron.system.ArmPack;

import arm.Wall;

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
    var isVolume = (n:DynamicAccess<Dynamic>) -> {
      return n.exists('mesh_data');
    };

		for (key => value in m) {
      if (isVolume(value)) holds.push(new Volume(key));
      else holds.push(new Hold(key));
      names[key] = holds.length-1;
			var current_hold = holds[names[key]];
			current_hold.loadFromMap(value);
		}
  }
  
  public function spawnGripByName(name:String, parent:Object, done: Object->Void):Object {
    var temp:Hold = holds[names[name]];
    var temp2:Object = Scene.active.addMeshObject(temp.get_data(),temp.get_materials(),parent);
    temp2.transform.dim.mult(temp.get_scale());
    var center_pos:Vec4 = temp.get_center();
    if (center_pos != null) {
      temp2.transform.loc.add(center_pos);
    }
    temp2.name = name;
    if (done != null) done(temp2);

    return temp2;
  }

  /**
   * Returns a volume if one of the given name exists
   * @param name Name of the volume to look for
   * @return Volume or null if not found or it is not a volume
   */
  public function get_volume(name:String):Volume {
    var temp = holds[names[name]];
    if (Std.is(temp,Volume)) return cast temp;
    
    return null;
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

  public function get_center():Vec4 return null;
	
	public function loadFromMap(m:DynamicAccess<Dynamic>):DynamicAccess<Dynamic> {
		var o:DynamicAccess<Dynamic> = m.mapToMeshData(this.get_name());
		meshData = o['meshdata'];
    materials = o['materials'];
    scale_pos = o['scale_pos'];

    return o;
  }
}

class Volume extends Hold {
  var wall:Wall = new Wall();
  var center_pos:Vec4;

  public function new(name:String) {
    super(name);
  }

  public override function loadFromMap(m:DynamicAccess<Dynamic>):DynamicAccess<Dynamic> {
    var o:DynamicAccess<Dynamic> = super.loadFromMap(m['mesh_data']);
    center_pos = o['center_pos'];
    
    for (id => data in (m['panels']:DynamicAccess<Dynamic>)) {
      var j:DynamicAccess<Dynamic> = data;
      wall.panels.push(new Panel(Std.parseInt(id),j));
    }

    trace('Volume has ${wall.panels.length} panels');

    return o;
  }

  public override function get_center():Vec4 return center_pos;

  public function cameraray_to_local(ray:Ray):Mat4 {
    return wall.cameraray_to_local(ray);
  }
  
  public function set_local(m:Mat4) wall.set_local(m);
}