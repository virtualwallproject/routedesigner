package arm;

import iron.math.Mat4;
import iron.math.Quat;
import iron.math.Vec2;
import iron.math.Vec3;
import iron.math.Vec4;

/**
 * Definition for CameraPath object
 */
class CameraPath {
  var positions:Array<Vec2> = [];
  var tangents:Array<Vec2> = [];
  var zHeight:Float = 0.0;
  var target:CameraPath = null;

  public function new(z:Float,target:CameraPath=null) {
    this.zHeight = z;
    this.target = target;
  }

  /**
   * Returns the target CameraPath of this CameraPath
   * @return CameraPath the target CameraPath
   */
   public function getTarget() {
     return this.target;
   }

  /**
   * Returns the position of the point at ratio a from beginning of CameraPath
   * @param x a ratio where 0 is beginning of CameraPath and 1 is end of CameraPath
   * @return Vec2 the position to place the camera
   */
  public function position(x:Float):Vec4 {
    // get indices of position array around this ratio
    var floatIndex:Float = x*(this.positions.length-1);
    var floor:Int = Math.floor(floatIndex);
    var ceil:Int = Math.ceil(floatIndex);

    var a:Vec2 = this.positions[floor];
    var b:Vec2 = this.positions[ceil];

    if (a == b) {
      return new Vec4(a.x,a.y,zHeight,0);
    }

    var run:Float = floatIndex - floor;
    var xy:Vec2 = (new Vec2()).lerp(a,b,run);

    return new Vec4(xy.x,xy.y,zHeight,0);
  }

  /**
   * Returns the tangent of the CameraPath at ratio a from beginning of CameraPath
   * @param x a ratio where 0 is beginning of CameraPath and 1 is end of CameraPath
   * @return Vec2 the tangent to place the camera (z is always 0 so not used)
   */
  public function tangent(x:Float): Vec2 {
    // get indices of position array around this ratio
    var floatIndex:Float = x*(this.positions.length-1);
    var floor:Int = Math.floor(floatIndex);
    var ceil:Int = Math.ceil(floatIndex);

    var a:Vec2 = this.tangents[floor];
    var b:Vec2 = this.tangents[ceil];

    if (a == b) {
      return a;
    }

    var run:Float = floatIndex - floor;
    var toReturn:Vec2 = (new Vec2()).lerp(a,b,run).normalize();

    return toReturn;
  }

  /**
   * Returns the vector tangent to the CameraPath at ratio a from beginning of CameraPath
   * @param a a ratio where 0 is beginning of CameraPath and 1 is end of CameraPath
   * @return Mat4 the transform of the camera (rot+loc)
   */
  public function transform(x:Float,z:Float): Mat4 {
    // get the camera i vector by subtracting target and camera positions
    var xyzPath:Vec4 = this.position(x);
    var xyzTarget:Vec4 = this.target.position(x);
    var cameraI:Vec4 = xyzTarget.clone().sub(xyzPath).normalize();

    // initially set the camera j vector to lerp tangent
    var temp:Vec2 = this.tangent(x);
    var cameraJ:Vec4 = new Vec4(temp.x,temp.y,0,0);
    // if camera is not pointing straight up or down use cross product
    if (Math.abs(cameraI.dot(Vec4.zAxis())) < 0.999) {
      cameraJ = Vec4.zAxis().cross(cameraI).normalize();
    }

    // camera k vector is the cross of i and j
    var cameraK:Vec4 = cameraI.clone().cross(cameraJ).normalize();

    // return Mat4.identity().setLookAt(xyzPath,xyzTarget,cameraK);

    // convert camera ijk to Mat4 and return it
    return new Mat4(-cameraJ.x,cameraK.x,-cameraI.x,xyzPath.x,
        -cameraJ.y,cameraK.y,-cameraI.y,xyzPath.y,
        -cameraJ.z,cameraK.z,-cameraI.z,xyzPath.z,
        0,0,0,1);
  }
}

class Circle extends CameraPath {
  public function new(z:Float,target:CameraPath,radius:Float) {
    super(z,target);

    // set the positions and orientations
    var numFrames:Int = 360;
    var radianStep:Float = 2.0*Math.PI/(numFrames-1);
    var angles:Array<Float> = [for(i in 0...numFrames) i*radianStep];
    for (a in angles) {
      var x:Float = radius*Math.cos(a);
      var y:Float = radius*Math.sin(a);
      this.positions.push(new Vec2(x,y));
      var tangentX:Float = -Math.sin(a);
      var tangentY:Float = Math.cos(a);
      this.tangents.push(new Vec2(tangentX,tangentY));
    }
  }
}