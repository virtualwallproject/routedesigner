package arm;

import iron.object.Object;
import iron.Scene;
import kha.FastFloat;
import kha.Scheduler;

class InfoTrait extends iron.Trait {
	var t_init:FastFloat = 0;

	@prop
	var background:String = "";

	public function new() {
		super();

		// notifyOnInit(function() {
		// });

		notifyOnUpdate(function() {
			if ((object.visible) && (t_init == 0)) {
				t_init = Scheduler.time();
				ObjectTools.setVisibility(object,true);
				toggleBackground();
			} else if ((t_init > 0) && ((Scheduler.time() - t_init) > 5)) {
				toggleBackground();
				ObjectTools.setVisibility(object,false);
				t_init = 0;
			}
		});

		// notifyOnRemove(function() {
		// });
	}

	function toggleBackground() {
		if (background != "") {
			var o:Object = Scene.active.getChild(background);
			if (o != null) ObjectTools.setVisibility(o,!o.visible);
		}
	}
}
