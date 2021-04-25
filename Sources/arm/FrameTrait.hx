package arm;

import iron.math.Mat4;
import iron.object.Object;
import kha.FastFloat;

using arm.ObjectTools;

class FrameTrait extends iron.Trait {
	public var _DIM(default, default): FastFloat; inline function get__DIM(): FastFloat { return this._DIM; } inline function set__DIM(f: FastFloat): FastFloat { return this._DIM = f; }
	public var _MINDIM(default, default): FastFloat; inline function get__MINDIM(): FastFloat { return this._MINDIM; } inline function set__MINDIM(f: FastFloat): FastFloat { return this._MINDIM = f; }

	@prop
	var active:Bool = false;

	public function new() {
		super();

		notifyOnInit(function() {
			object.transform.localOnly = false;
			_DIM = 2;
			_MINDIM = 0.1;
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
	
  /* Sets the transform of matrix b to this frame
  */  
  public function transformFrame(b:Mat4):Bool {
    // sets the transform b to the frame a
    if (b == null) return false;

		var a:Object = object;

    // set rotation from the grip
    a.transform.local.setIdentity();
    a.transform.local.multmat(b);
    a.transform.local.toRotation();
    
    // update the transform
		a.transform.decompose();
		a.transform.buildMatrix();

    var scale:FastFloat = Math.max(
			Math.sqrt(b._00 * b._00 + b._10 * b._10 + b._20 * b._20),
			Math.sqrt(b._01 * b._01 + b._11 * b._11 + b._21 * b._21)
		);
		scale = Math.max(scale/_DIM,_MINDIM/_DIM);
    a.transform.scale.set(scale,scale,scale);
    
    // translate
    a.transform.translate(b._30, b._31, b._32);

		// set the transform to dirty so that it is flagged for update
		a.transform.dirty = true;

    return true;
  }
	
	/* Sets the transform of grip b to this frame
  */
  public function transformFrameToGrip(b:Object,?scale:Null<Float>=null) {
    if (b != null) {
			var a:Object = object;

      // set rotation from the grip
      a.transform.rot.setFrom(b.transform.rot);

      // set the scale if it was non-negative
      if (scale != null) {
				var temp:FastFloat = ((scale > _MINDIM) ? scale : _MINDIM)/_DIM;
        a.transform.scale.set(temp,temp,temp);
      }
      
      // translate
      var temp:Mat4 = b.transform.local;
      a.transform.loc.set(temp._30, temp._31, temp._32);
      
      // update the transform
      a.transform.buildMatrix();
    }
  }

}
