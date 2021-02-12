package arm;

using arm.ObjectTools;

class FrameTrait extends iron.Trait {
	@prop
	var active:Bool = false;

	public function new() {
		super();

		notifyOnInit(function() {
			object.transform.localOnly = false;
		});

		notifyOnUpdate(function() {
			set_visible();
		});

		// notifyOnRemove(function() {
		// });
	}

	public function is_active() return active;

	public function toggle_active() {
		active = !active;
	}

	public function set_visible() {
		if ((active) &&
			(object.transform.local.getLoc().length() > 0.0001)) {
			object.visible = true;
		} else object.visible = false;
	}

}
