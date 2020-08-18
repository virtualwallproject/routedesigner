package arm;

import kha.FastFloat;
import iron.object.CameraObject;
import iron.Scene;

class KhaMouse extends KhaSurface {
  var wheel:Int = 0;
  var camera:CameraObject;

  public function new(camera:CameraObject) {
    super();
    this.camera = camera;
  }

  public function mouseMove(x:Int, y:Int, dx:Int, dy:Int) {
    for (i in 0...this.touches.length) {
      if (this.touches[i]) super.touchMove(i,x,y);
    }
  }

  public function wheelMove(i:Int) {
    wheel += i;
  }

  public function wheelUnMove() {
    if (wheel > 0) wheel += -1;
    else if (wheel < 0) wheel += 1;
  }

  public override function pressed(num:Int):Bool {
    if (num > 3) return false;
    else return this.touches[num-1];
  }

  public override function squeezed():Bool {
    return (wheel > 0);
  }

  public override function stretched():Bool {
    return (wheel < 0);
  }

  public override function rotated():FastFloat {
    var rotation:FastFloat = camera_trait().spinActiveHold(
      this.start[0].x,
      this.start[0].y,
      this.last[0].x,
      this.last[0].y);
    if (Math.isNaN(rotation)) return 0;
    else if (rotation > 0) return 1;
    else if (rotation < 0) return -1;
    else return 0;
  }
  
  function camera_trait():CameraTrait {
    if (camera != null)
      return camera.getTrait(CameraTrait);
    
    throw "Camera is null";
    Scene.active.getTrait(SceneTrait).shutdown();
    
    return null;
  }
}