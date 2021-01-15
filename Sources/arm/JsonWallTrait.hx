package arm;

import iron.Scene;
import kha.Assets;
import kha.Blob;

import arm.Wall;

using Lambda;

class JsonWallTrait extends iron.Trait {
  var wall:Wall;
  
  public function new() {
    super();
    
    notifyOnInit(function() {
      var scene_trait:SceneTrait = Scene.active.getTrait(SceneTrait);

      Assets.loadBlob(scene_trait.wall_name() + "_json", function (b:Blob) {
        wall = new Wall();
        wall.loadFromJsonString(b.toString());
      });
    });
    
    // notifyOnUpdate(function() {
    // });
    
    // notifyOnRemove(function() {
    // });
  }
  
  public function get_wall():Wall return wall;
}