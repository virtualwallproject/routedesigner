package arm;

import iron.math.Ray;
import iron.math.Vec4;
#if arm_oimo
import armory.trait.physics.oimo.PhysicsWorld;
#elseif arm_bullet
import armory.trait.physics.PhysicsWorld;
#end

class PhysicsTools {
  public static function pointsToRay(start:Vec4,end:Vec4):Ray {
    var origin:Vec4 = start;
    var direction:Vec4 = (new Vec4()).subvecs(end,start).normalize();

    return new Ray(origin,direction);
  }

  #if arm_physics
  public static function hitToRay(hit,physics:PhysicsWorld):Ray {
    var ray:Ray = null;
    if (hit != null) {
      #if arm_oimo
      var closest:oimo.dynamics.callback.RayCastClosest = physics.rayCastResult;
      ray = new Ray(
        new Vec4(closest.position.x,closest.position.y,closest.position.z,0),
        new Vec4(closest.normal.x,closest.normal.y,closest.normal.z,1)
      );
      #elseif arm_bullet
      ray = new Ray(hit.pos,hit.normal);
      #end
    }
    return ray;
  }
  #end
}