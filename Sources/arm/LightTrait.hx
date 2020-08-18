package arm;

import iron.Scene;

class LightTrait extends iron.Trait {
	public function new() {
		super();

		// notifyOnInit(function() {
		// });

		notifyOnUpdate(function() {
			object.transform.loc.setFrom(
				Scene.active.camera.transform.loc.clone().add(
					Scene.active.camera.right()
				)
			);

			object.transform.buildMatrix();
		});

		// notifyOnRemove(function() {
		// });
	}
}
