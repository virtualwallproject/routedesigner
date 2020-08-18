package arm;

import iron.object.Object;
import iron.data.MaterialData;
import iron.system.Input;
import iron.object.MeshObject;
import iron.Scene;

import kha.System;

class CubeTrait extends iron.Trait {
	var mesh:MeshObject;
	var original_material:MaterialData;
	var materials:Array<MaterialData>;
	var index:Int = 0;

	public function new() {
		super();

		notifyOnInit(function() {
			mesh = cast(object,MeshObject);
			original_material = mesh.materials[0];

			var scene:Scene = Scene.active;
			materials = [];
			for (name in ['Yellow', 'Green', 'Blue', 'Red', 'Black']) {
				var o:Object = scene.getChild(name);
				var m:MeshObject = cast(o,MeshObject);
				materials.push(m.materials[0]);
			}
		});

		notifyOnUpdate(function() {
			var keyboard = Input.getKeyboard();
            
            // Shutdown on escape
			if (keyboard.started("escape")) System.stop();
			
			// switch materials on space
			if (keyboard.started("space")) {
				var next_index:Int = index + 1;
				if (next_index > materials.length) {
					next_index = 0;
				}

				index = next_index;
				if (index == 0) {
					for (i in 0...mesh.materials.length) {
						mesh.materials[i] = original_material;
					}
				} else {
					for (i in 0...mesh.materials.length) {
						mesh.materials[i] = materials[index-1];
					}
				}
				// trace('#mats ${materials.length} index ${index}')
			}
		});

		// notifyOnRemove(function() {
		// });
	}
}
