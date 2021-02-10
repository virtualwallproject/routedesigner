package arm;

import iron.math.Vec4;
import iron.data.Data;
import kha.FastFloat;
import kha.arrays.Int16Array;
import kha.arrays.Uint32Array;
import haxe.DynamicAccess;
import iron.data.MeshData;
import iron.data.MaterialData;
import iron.data.SceneFormat;

class MapTools {
  static public function mapToMeshData(map:DynamicAccess<Dynamic>,name:String):DynamicAccess<Dynamic> {
    // helper fxns
    var loadMaterials = (names:Array<String>,mats:haxe.ds.Vector<MaterialData>) -> {
      for (i in 0...names.length) {
        Data.getMaterial("Scene", names[i], function(data:MaterialData) {
          mats[i] = data;
        });
      }
    };
    var loadVertexArrays = (data:Array<DynamicAccess<Dynamic>>,pos:TVertexArray,nor:TVertexArray) -> {
      for (i in 0...pos.values.length) pos.values[i] = data[0]["values"][i];
      for (i in 0...nor.values.length) nor.values[i] = data[1]["values"][i];
    };
    var loadIndexArrays = (data:Array<DynamicAccess<Dynamic>>,map:Map<Int,Array<Int>>) -> {
      for (i in 0...data.length) {
        map.set(data[i]["material"],data[i]["values"]);
      }
    };

    // initialize variables we set in first for loop
		var scale_pos:FastFloat = 1.0;
		var center_pos:Array<FastFloat> = [0,0,0];
		var num_verts:Int = 0;
		var names:Array<String> = new Array<String>();

		for (id => data in (map:DynamicAccess<Dynamic>)) {

			if (id == "materials") {

				names = data;

			} else if (id == "center_pos") {

				var array:Array<Dynamic> = data;
				center_pos = [array[0],array[1],array[2]];

			} else if (id == "scale_pos") scale_pos = data;
			else if (id == "num_verts") num_verts = data;

		}

		// initialize variables we set in second for loop
		var pos: TVertexArray = { attrib: "pos", values: new Int16Array(4*num_verts), data: "short4norm" };
		var nor: TVertexArray = { attrib: "nor", values: new Int16Array(2*num_verts), data: "short2norm" };
		var index_map: Map<Int,Array<Int>> = new Map<Int,Array<Int>>();

		for (id => data in (map:DynamicAccess<Dynamic>)) {

			if (id == "vertex_arrays") {
				
				var arrays:Array<DynamicAccess<Dynamic>> = data;
				loadVertexArrays(arrays,pos,nor);

			} else if (id == "index_arrays") {

				var arrays:Array<DynamicAccess<Dynamic>> = data;
				loadIndexArrays(arrays,index_map);

			}

		}

		var toU32 = function(to:Uint32Array, from:Array<Int>)
			for (i in 0...to.length) to[i] = from[i];

		var ind: Array<TIndexArray> = [
			for (m => v in index_map)
				{material: m, values: new Uint32Array(v.length)}
		];
		ind.sort((a,b) -> a.material - b.material);

		for (i in ind) toU32(i.values,index_map[i.material]);

		var rawmeshData:TMeshData = {
			name: name,
			vertex_arrays: [pos, nor],
			index_arrays: ind,
			scale_pos: scale_pos
		};

		var temp:DynamicAccess<Dynamic> = new DynamicAccess<Dynamic>();
		temp['materials'] = new haxe.ds.Vector(names.length);
		loadMaterials(names,temp['materials']);
		temp['meshdata'] = new MeshData(rawmeshData,(data:MeshData) -> {});
		temp['scale_pos'] = scale_pos;
		temp['center_pos'] = new Vec4(center_pos[0],center_pos[1],center_pos[2]);

		return temp;
  }
  
}