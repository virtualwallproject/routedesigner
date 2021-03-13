package arm;

import iron.math.Quat;
using Lambda;
using arm.MapTools;

import haxe.Json;
import haxe.DynamicAccess;
import kha.FastFloat;
import iron.data.MaterialData;
import iron.data.MeshData;
import iron.math.Vec2;
import iron.math.Vec4;
import iron.math.Mat4;
import iron.math.Ray;
import iron.object.Object;
import iron.Scene;

import arm.ObjectTools;
import arm.Panel;

class Wall {
  public var panels:Array<Panel>;
  var tnut:Mat4; // closest tnut tnut matrix, returned by hitray_to_local()
  var local:Mat4; // any transformation applied to the wall
  
  public function new() {
    panels = new Array<Panel>();
    tnut = Mat4.identity();
    local = Mat4.identity();
  }
  
  public function set_local(m:Mat4) {
    local.setFrom(m);
    local.toRotation();
    local.setLoc(m.getLoc());
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

      } else if (key == "mesh_data") {

        var temp:DynamicAccess<Dynamic> = value;
        var o:DynamicAccess<Dynamic> = temp.mapToMeshData('WallMesh');
        var meshData:MeshData = o['meshdata'];
        var materials:haxe.ds.Vector<MaterialData> = o['materials'];
        var center_pos:Vec4 = o['center_pos'];
        var mesh:Object = Scene.active.addMeshObject(meshData,materials);
        mesh.transform.translate(center_pos.x,center_pos.y,center_pos.z);

      } else if (key == "children") {

        var child_index:Int = 0;
        for (child_value in (value:DynamicAccess<Dynamic>)) {
          var temp:DynamicAccess<Dynamic> = child_value;
          var mesh_name:String = 'WallChildMesh${child_index}';
          var o:DynamicAccess<Dynamic> = temp.mapToMeshData(mesh_name);
          var meshData:MeshData = o['meshdata'];
          var materials:haxe.ds.Vector<MaterialData> = o['materials'];
          var center_pos:Vec4 = o['center_pos'];
          var mesh:Object = Scene.active.addMeshObject(meshData,materials);
          mesh.transform.translate(center_pos.x,center_pos.y,center_pos.z);
          child_index++;
        }

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

    // get local wall frame components necessary for building tnut frame
    var q:Quat = new Quat(); var l:Vec4 = new Vec4(); var s:Vec4 = new Vec4();
    local.decompose(l,q,s);
    
    // set tnut from the panel's quaternion
    tnut.fromQuat(panel.get_quat());
    tnut.applyQuat(q);

    // set the scale
    var s:Vec2 = panel.get_spacing();
    var scale:FastFloat = panel.get_scale()*(if (s.x >= s.y) s.x else s.y);
    tnut.scale(new Vec4(scale,scale,scale));
    
    // set tnut location from the closest tnut location
    var temp = panel.get_loc().map(dist_to_ray);
    tnut.setLoc(panel.get_loc()[min_index(temp)]);
    tnut.setLoc(tnut.getLoc().applyQuat(q).add(l));
    
    return tnut;
  }

  public function cameraray_to_local(ray:Ray):Mat4 {
    // transform the ray into the wall's local frame
    var temp:Mat4 = Mat4.identity();
    temp.setFrom(local).toRotation();
    temp.getInverse(temp);
    var local_ray:Ray = new Ray(ray.origin.clone(),ray.direction.clone());
    local_ray.direction.applymat(temp);
    local_ray.origin.add(local.getLoc().mult(-1)).applymat(temp);

    var dist_to_ray = function(x:Vec4) return local_ray.distanceToPoint(x);
    var filter_fxn = function(x:Panel)
      return x.get_normal().dot(local_ray.direction) < -1.0*Math.cos(75*Math.PI/180);

    return ray_to_local(local_ray,dist_to_ray,filter_fxn);
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