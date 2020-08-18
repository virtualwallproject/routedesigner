package arm;

import kha.FastFloat;

// To create a custom loading screen copy this file to blend_root/Sources/arm/LoadingScreen.hx

class LoadingScreen {

	public static function render(g: kha.graphics2.Graphics, assetsLoaded: Int, assetsTotal: Int) {
    g.color = kha.Color.fromBytes(0, 191, 255);
    var ratio:FastFloat = assetsLoaded/assetsTotal;
		if (iron.App.w() > iron.App.h())
			g.fillRect(0, 0, iron.App.w()*ratio, iron.App.h());
		else
			g.fillRect(0, iron.App.h()*(1-ratio), iron.App.w(), iron.App.h()*ratio);
	}
}
