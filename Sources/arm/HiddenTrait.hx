package arm;

class HiddenTrait extends iron.Trait {
	public function new() {
		super();

		notifyOnInit(function() {
			ObjectTools.setVisibility(object,false);
		});

		// notifyOnUpdate(function() {
		// });

		// notifyOnRemove(function() {
		// });
	}
}
