package arm;

import iron.math.Mat4;
import iron.math.Quat;
import iron.object.Object;
import iron.object.MeshObject;
import iron.data.MaterialData;
import kha.FastFloat;

class ObjectTools {
  static public function FRAME_DIM(a:Object):FastFloat return 2.0;

  /**
   * Set the visibility of object and all of its children
   * @param a 
   * @param visible 
   */
  static public function setVisibility(a:Object,visible:Bool) {
    a.visible = visible;
    copyVisibility(a);
  }

  static public function copyVisibility(a:Object) {
    for (child in a.children){
      if (child.children.length > 0) setVisibility(child,a.visible);
      else child.visible = a.visible;
    }
  }
  
  static public function hasQuatProps(a:Object) {
    if ((a == null) || (a.properties == null)) return false;
    
    var w_exists:Bool = a.properties.exists("w");
    var x_exists:Bool = a.properties.exists("x");
    var y_exists:Bool = a.properties.exists("y");
    var z_exists:Bool = a.properties.exists("z");
    
    return w_exists && x_exists && y_exists && z_exists;
  }
  
  static function quatFromProps(a:Object) {
    if (hasQuatProps(a)) {
      return new Quat(
        a.properties["x"],
        a.properties["y"],
        a.properties["z"],
        a.properties["w"]
      );
    }
    
    return new Quat();
  }
    
  static public function copyQuatProps(a:Object,b:Object) {
    // copy quaternion properties from b to a
    if (hasQuatProps(b)) {
      if (a.properties == null) {
        a.properties = new Map();
      }
      
      a.properties["x"] = b.properties["x"];
      a.properties["y"] = b.properties["y"];
      a.properties["z"] = b.properties["z"];
      a.properties["w"] = b.properties["w"];
    }
  }
    
  /* fix an objects rotation using its quaternion stored as w x y z armory
  *  properties
  */
  static public function fixRotation(a:Object) {
    // 
    
    if (hasQuatProps(a)) {
      // apply the correct rotation
      a.transform.rot = quatFromProps(a);
      
      // update the transform
      a.transform.buildMatrix();
      
      trace ('${a.name} has been fixed');
    }
  }
    
  static public function transformFrame(a:Object,b:Mat4):Bool {
    // sets the transform b to the frame a
    if (b == null) return false;

    a.transform.setMatrix(b.clone());
    return true;
  }
        
  static public function spawnGripByName(a:Object,name:String,parent:Object) {
    iron.Scene.active.spawnObject(
      name, parent, function(grip:iron.object.Object) {
      // rotation
      grip.transform.rot.setFrom(a.transform.rot);
      
      // translation
      grip.transform.loc = a.transform.loc.clone();
      
      // update the transform
      grip.transform.buildMatrix();
    });
  }
          
  /* Sets the transform of grip b to a
  */
  static public function transformFrameToGrip(a:Object,b:Object) {
    if (b != null) {
      // set rotation from the grip
      a.transform.rot.setFrom(b.transform.rot);
      
      // translate
      a.transform.loc = b.transform.loc.clone();
      
      // update the transform
      a.transform.buildMatrix();
    }
  }
          
  static public function change_material(a:Object,mat:MaterialData) {
    var mesh:MeshObject = cast(a,MeshObject);
    var to_return = mesh.materials[0];
    
    for (i in 0...mesh.materials.length) {
      mesh.materials[i] = mat;
    }
    
    return to_return;
  }

  /**
   * Helper function to flatten an object by setting and applying z scale
   * @param z_scale the z scale to apply
   */
  static public function flatten(a:Object,z_scale:FastFloat=0.1) {    
			a.transform.scale.z = z_scale*a.transform.scale.z;
			a.transform.buildMatrix();
  }

  /**
   * Helper function to flatten an object by setting and applying z scale
   * @param z_scale the z scale to apply
   */
  static public function unflatten(a:Object,z_scale:FastFloat=10) {    
      flatten(a,z_scale);
  }
          
}