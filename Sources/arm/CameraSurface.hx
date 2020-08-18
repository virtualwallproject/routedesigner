package arm;

import iron.math.Vec4;
import iron.math.Mat4;
import kha.FastFloat;
import arm.CameraPath;

/**
 * Definition of CameraSurface
 */
class CameraSurface {
  var u_ratio:FastFloat = 0.0;
  var u_range:Range = new Range(0,1);
  var v_ratio:FastFloat = 0.2;
  var v_range:Range = new Range(0,1);
  var z_ratio:FastFloat = 0.5;
  var z_range:Range = new Range(0,0);

  var target:CameraPath = null;

  public function new(target:CameraPath) {
    this.target = target;
  }

  public function increment_u(s:FastFloat) {
    u_ratio += s*0.005*get_z_length()/get_u_length();
    if (u_ratio > 1) u_ratio = 1;
  }

  public function decrement_u(s:FastFloat) {
    u_ratio += -s*0.005*get_z_length()/get_u_length();
    if (u_ratio < 0) u_ratio = 0;
  }

  public function set_u_range(min,max) {
    u_range.min = min;
    u_range.max = max;
  }

  public function get_u_length():FastFloat return u_range.max - u_range.min;

  public function increment_v() {
    v_ratio += 0.005;
    if (v_ratio > 1) v_ratio = 1;
  }

  public function decrement_v() {
    v_ratio += -0.005;
    if (v_ratio < 0) v_ratio = 0;
  }

  public function set_v_range(min,max) {
    v_range.min = min;
    v_range.max = max;
  }

  public function get_v_length():FastFloat return v_range.max - v_range.min;

  public function increment_z(s:FastFloat) {
    z_ratio += s*0.005;
    if (z_ratio > 1) z_ratio = 1;
  }

  public function decrement_z(s:FastFloat) {
    z_ratio += -s*0.005;
    if (z_ratio < 0) z_ratio = 0;
  }

  public function set_z_range(min,max) {
    z_range.min = min;
    z_range.max = max;
  }

  public function get_z_length():FastFloat return z_range.max - z_range.min;

  function xyz():Vec4 {
    return new Vec4(
      u_range.min + u_ratio*(u_range.max - u_range.min),
      v_range.min + v_ratio*(v_range.max - v_range.min),
      z_range.min + z_ratio*(z_range.max - z_range.min),
      0
    );
  }

  function i() {
    var temp:Vec4 = xyz();
    var delta:Vec4 = null;

    if (v_ratio > 0.001) {
      v_ratio += -0.001;
      delta = xyz().sub(temp);
      v_ratio += 0.001;
    } else {
      v_ratio += 0.001;
      delta = temp.sub(xyz());
      v_ratio += -0.001;
    }

    return delta.normalize();
  }

  function j() {
    return Vec4.zAxis().cross(i());
  }

  public function transform() {
    var xyzPath:Vec4 = this.xyz();
    var xyzTarget:Vec4 = this.target.position(u_ratio);

    // do something here if the clipping object is not null

    var cameraI:Vec4 = xyzTarget.clone().sub(xyzPath).normalize();
    var cameraJ:Vec4 = this.j();
    var cameraK:Vec4 = (new Vec4()).crossvecs(cameraI,cameraJ);

    // convert camera ijk to Mat4 and return it
    return new Mat4(-cameraJ.x,cameraK.x,-cameraI.x,xyzPath.x,
      -cameraJ.y,cameraK.y,-cameraI.y,xyzPath.y,
      -cameraJ.z,cameraK.z,-cameraI.z,xyzPath.z,
      0,0,0,1);
  }
}

/**
 * Definition of a circular CameraSurface
 */
class CameraCircle extends CameraSurface {
  function r():FastFloat
    return v_range.min + v_ratio*(v_range.max - v_range.min);

  public override function increment_u(s:FastFloat) {
    super.increment_u(s);
    if (u_ratio == 1) u_ratio = 0;
  }

  public override function decrement_u(s:FastFloat) {
    super.decrement_u(s);
    if (u_ratio == 0) u_ratio = 1;
  }

  public override function get_u_length() return 0.5*Math.PI*r();

  override function xyz() {
    var angle:FastFloat = 2*Math.PI*u_ratio;
    var r:FastFloat = r();

    return new Vec4(
      r*Math.cos(angle),
      r*Math.sin(angle),
      z_range.min + z_ratio*(z_range.max - z_range.min),
      0
    );
  }
}

class Range {
  public var min:FastFloat;
  public var max:FastFloat;

  public function new(min:FastFloat,max:FastFloat) {
    this.min = min;
    this.max = max;
  }
}