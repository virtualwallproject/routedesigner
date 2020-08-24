package arm;

import kha.Assets;
import kha.Blob;
import haxe.Json;
import haxe.DynamicAccess;
import kha.FastFloat;
import iron.math.Quat;
import iron.math.Vec2;
import iron.math.Vec4;
import iron.math.Mat4;
import iron.math.Ray;

import arm.ObjectTools;

using Lambda;

class JsonWallTrait extends iron.Trait {
  var wall:Wall = null;
  var traced:Bool = false;
  
  public function new() {
    super();
    
    notifyOnInit(function() {
      // assume the json file is the only asset... haha
      Assets.loadBlob(Assets.blobs.names[0], function (b:Blob) {
        wall = new Wall();
        wall.loadFromJsonString(b.toString());
      });
    });
    
    notifyOnUpdate(function() {
      if ((wall != null) && (!traced)) {
        trace('Number of panels=${wall.panels.length}');
        traced = true;
      }
    });
    
    // notifyOnRemove(function() {
    // });
  }
  
  public function get_wall():Wall return wall;
}
  
class Wall {
  public var panels:Array<Panel>;
  var local:Mat4; // closest tnut local matrix, returned by hitray_to_local()
  
  public function new() {
    panels = new Array<Panel>();
    local = Mat4.identity();
  }
  
  public function loadFromJsonString(s:String) {
    //Parse value from stringy json
    var j:DynamicAccess<Dynamic> = Json.parse(s);
    loadFromMap(j);
  }
  
  function loadFromMap(m:DynamicAccess<Dynamic>) {
    for (key => value in m){
      
      if (key == "panels") {
        for (id => data in (value:DynamicAccess<Dynamic>)) {
          var j:DynamicAccess<Dynamic> = data;
          panels.push(new Panel(Std.parseInt(id),j));
        }
      } else {
        panels = null;
        break;
      }
    }
  }

  public function ray_to_local(ray:Ray,f:Vec4->FastFloat,filter_fxn:Panel->Bool):Mat4 {
    if (ray == null) return null;
    
    var dist_to_ray:Vec4->FastFloat = f;
    var dist_to_center:Panel->FastFloat = function(x:Panel):FastFloat
      return dist_to_ray(x.get_center());

    var min_index = function(x:Array<FastFloat>):Int
      return x.indexOf(x.fold(Math.min, x[0]));

    var panels = this.panels.filter(filter_fxn);
    
    // get the closest 6 panels
    var center_distances:Array<FastFloat> = panels.map(dist_to_center);
    var close_panels:Array<Panel> = new Array<Panel>();
    var close_loc_dists:Array<FastFloat> = new Array<FastFloat>();
    for (i in 0...6) {
      if (i < panels.length) {
        // add the next closest panel to the array
        close_panels.push(panels[min_index(center_distances)]);
        center_distances[min_index(center_distances)] = Math.POSITIVE_INFINITY;

        // compute the distance to the closest loc for next closest panel
        var panel:Panel = close_panels[close_panels.length-1];
        var loc_distances:Array<FastFloat> = panel.get_loc().map(dist_to_ray);
        close_loc_dists.push(loc_distances[min_index(loc_distances)]);
      }
    }

    if (close_panels.length == 0) return null;

    var i:Int = min_index(close_loc_dists);

    // select to the panel that has the closest loc
    var panel:Panel = close_panels[i];

    var max_dist:FastFloat =
      2*Math.max(panel.get_spacing().x,panel.get_spacing().y)*panel.get_scale();
    if (close_loc_dists[i] > max_dist) return null;
    
    // set local from the panel's quaternion
    local.fromQuat(panel.get_quat());

    // set the scale
    var s:Vec2 = panel.get_spacing();
    var scale:FastFloat = panel.get_scale()*(if (s.x >= s.y) s.x else s.y);
    scale = scale/ObjectTools.FRAME_DIM(null);
    local.scale(new Vec4(scale,scale,scale));
    
    // set local location from the closest tnut location
    var temp = panel.get_loc().map(dist_to_ray);
    local.setLoc(panel.get_loc()[min_index(temp)]);
    
    return local;
  }

  public function cameraray_to_local(ray:Ray):Mat4 {
    var dist_to_ray = function(x:Vec4) return ray.distanceToPoint(x);
    var filter_fxn = function(x:Panel)
      return x.get_normal().dot(ray.direction) < -1.0*Math.cos(75*Math.PI/180);

    return ray_to_local(ray,dist_to_ray,filter_fxn);
  }
  
  public function hitray_to_local(ray:Ray):Mat4 {
    var dist_to_ray = function(x:Vec4) return x.distanceTo(ray.origin);
    
    return ray_to_local(ray,dist_to_ray,function(x:Panel) return true);
  }
  
  public function panel_info():String {
    var info = "";
    for (i in 0...panels.length) {
      info += 'Info for face #${panels[i].get_id()}\n' +
      'Center=     ${panels[i].get_center()}\n' +
      'Quaternion= ${panels[i].get_quat()}\n' +
      'Num tnuts=  ${panels[i].get_loc().length}\n' +
      'Normal=     ${panels[i].get_normal()}';
      if (i < panels.length-1) info += "\n";
    }
    return info;
  }
}

class Panel {
  var id:Int;
  var filepath:String;
  var center:Vec4;
  var xyzw:Quat;
  var start:Vec4;
  var spacing:Vec2;
  var offset:Vec2;
  var scale:FastFloat;
  var loc:Array<Vec4>;
  
  public function new(id:Int,m:DynamicAccess<Dynamic>) {
    this.id = id;
    filepath = new String(m["filepath"]);
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
  
  public function get_filepath():String return filepath;
  
  public function get_center():Vec4 return center;
  
  public function get_quat():Quat return xyzw;

  public function get_spacing():Vec2 return spacing;

  public function get_scale():FastFloat return scale;
  
  public function get_loc():Array<Vec4> return loc;
  
  public function get_normal():Vec4
    return Mat4.identity().fromQuat(xyzw).up();
}