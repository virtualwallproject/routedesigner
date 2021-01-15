package arm;

using arm.MapTools;

import haxe.DynamicAccess;
import kha.FastFloat;
import iron.math.Vec2;
import iron.math.Quat;
import iron.math.Vec4;
import iron.math.Mat4;

class Panel {
  var id:Int;
  var center:Vec4;
  var xyzw:Quat;
  var start:Vec4;
  var spacing:Vec2;
  var offset:Vec2;
  var scale:FastFloat;
  var loc:Array<Vec4>;
  
  public function new(id:Int,m:DynamicAccess<Dynamic>) {
    this.id = id;
    center = new Vec4(m["center"][0],m["center"][1],m["center"][2],0);
    xyzw = new Quat(m["xyzw"][0],m["xyzw"][1],m["xyzw"][2],m["xyzw"][3]);
    start = new Vec4(m["start"][0],m["start"][1],m["start"][2],0);
    spacing = new Vec2(m["spacing"][0],m["spacing"][1]);
    offset = new Vec2(m["offset"][0],m["offset"][1]);
    scale = m["scale"];
    var scale_loc:FastFloat = m["scale_loc"];
    loc = new Array<Vec4>();
    var temp:Array<Dynamic> = m["loc"];
    for (i in 0...Std.int(temp.length/3)) {
      // push vec4 from -32676 to 32767 integer
      loc.push(new Vec4(temp[3*i],temp[3*i+1],temp[3*i+2],0));
      // scale to distance from integer
      loc[loc.length-1].mult(scale_loc/32767.0);
      // add back in center of panel
      loc[loc.length-1].add(center);
    }
  }
  
  public function get_id():Int return id;
  
  public function get_center():Vec4 return center;
  
  public function get_quat():Quat return xyzw;

  public function get_spacing():Vec2 return spacing;

  public function get_scale():FastFloat return scale;
  
  public function get_loc():Array<Vec4> return loc;
  
  public function get_normal():Vec4
    return Mat4.identity().fromQuat(xyzw).up();
}