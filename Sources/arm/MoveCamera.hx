package arm;

import iron.object.CameraObject;
import arm.CameraPath;

class MoveCamera extends iron.Trait {
	public function new() {
		super();
		var keyboard = iron.system.Input.getKeyboard();
		var ratio:Float;
		var zOffset:Float;
        var target:Circle;
		var path:Circle;
		var minHeight:Float;
		var maxHeight:Float;

		notifyOnInit(function() {
			object.transform.localOnly = true;
			ratio = 0.0;
			zOffset = 2.5;
			minHeight = 0.2;
			maxHeight = 3;
			target = new Circle(0,null,0.5);
			path = new Circle(zOffset,target,5);
		});

		notifyOnUpdate(function() {
			var camera = cast(object.getChild("Camera"),CameraObject);

			if(keyboard.down("left")){
				ratio += -0.005;
				if (ratio < 0) {
					ratio += 1.0;
				}
			}
			if(keyboard.down("right")){
				ratio += 0.005;
				if (ratio >= 1.0) {
					ratio += -1.0;
				}
			}
			if(keyboard.down("down")){
				zOffset += -0.05;
				if (zOffset < minHeight) {
					zOffset = minHeight;
				}
			}
			if(keyboard.down("up")){
				zOffset += 0.05;
				if (zOffset > maxHeight) {
					zOffset = maxHeight;
				}
			}

			var temp = path.transform(ratio,zOffset);
			object.transform.setMatrix(temp);
		});

		// notifyOnRemove(function() {
		// });
	}
}
