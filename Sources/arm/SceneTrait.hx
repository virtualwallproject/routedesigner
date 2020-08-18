package arm;

import kha.System;

class SceneTrait extends iron.Trait {
	var joycons:Int = 0;

	public function new() {
		super();

		notifyOnInit(function() {
			#if kha_js
			var href:String = js.Browser.document.location.href;
			trace('found href of ${href}');
			var q:Map<String,String> = decode_query(href);
			trace('decode of query is {${q}}');
			if (q.exists('joycons')) {
				var temp = Std.parseInt(q['joycons']);
				if (temp != null) joycons = temp;
			}
			#end
		});

		// notifyOnUpdate(function() {
		// });

		// notifyOnRemove(function() {
		// });
	}

	public function shutdown() {
		System.stop();
	}

	public function num_joycons():Int return joycons;

	function decode_query(uri:String):Map<String, String> {
		var i:Int = uri.lastIndexOf('?');
		var m:Map<String, String> = [];

		if (i>0) {
			for (s in uri.substring(i+1).split('&')) {
				var temp:Array<String> = s.split('=');
				m[temp[0]] = temp[1];
			}
		}

		return m;
	}
}
