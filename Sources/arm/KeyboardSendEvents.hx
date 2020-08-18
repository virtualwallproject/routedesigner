package arm;

import kha.input.Keyboard;
import iron.math.Vec2;
import armory.system.Event;
import iron.Scene;
import iron.object.Object;
import iron.object.CameraObject;

import arm.KhaKeyboard;

class KeyboardSendEvents extends iron.Trait {
  var scene:Scene;
  var camera:CameraObject;
  var frame:Object;
  var slave_frame:Object;
  var keyboard:KhaKeyboard;
  var state:Int;
  var last_state:Int;
  var info_icon:Object;
  var help_icon:Object;
  var icon_traits:Array<InTheWayTrait> = [null, null];
  var help:Object = null;
  var help_trait:ScreenSequenceTrait;
  
  var MOVECAMERA_SCREENINDEX:Int = 1;
  var ZOOM_SCREENINDEX:Int = 2;
  var SPACE_SCREENINDEX:Int = 3;
  var WALL_SCREENINDEX:Int = 4;
  var GRIP_SCREENINDEX:Int = 5;
  var ROTATE_SCREENINDEX:Int = 6;
  var MOVE_SCREENINDEX:Int = 7;
  
  @prop
  var info_icon_name: String;
  @prop
  var info_name: String;
  @prop
  var help_icon_name: String;
  @prop
  var help_name: String;
  @prop
  var leftjoycon_help_name: String;
  @prop
  var rightjoycon_help_name: String;
  @prop
  var tray_name: String;
  
  public function new() {
    super();
    
    notifyOnInit(function() {
      scene = Scene.active;
      camera = Scene.active.camera;
      frame = camera_trait().get_frame();
      slave_frame = frame.getTrait(MasterFrameTrait).get_slave();
      keyboard = new KhaKeyboard(scene);
      state = 0;
      last_state = -1;

      // if joycon has been detected replace help name with joycon help name
      #if kha_js
			var st:SceneTrait = scene.getTrait(SceneTrait);
      if (st.num_joycons() > 0) {
        if (keyboard.get_joycon().side == 'left')
          help_name = leftjoycon_help_name;
        else
          help_name = rightjoycon_help_name;
      }
			#end

      spawn_help();
    });
    
    notifyOnUpdate(function() {
      
      var scene_trait:SceneTrait = scene.getTrait(SceneTrait);
      var camera_trait = camera_trait();
      var master_trait = frame.getTrait(MasterFrameTrait);
      var slave_trait = slave_frame.getTrait(SlaveFrameTrait);
      var tray_trait = tray_trait(slave_trait);
      
      /**
      * Mouse input: store left click info
      */
      // var click:Vec2 = null;
      // if (mouse.started("left")) click = new Vec2(mouse.lastX,mouse.lastY);
      
      // Shutdown on escape
      if (keyboard.shutdown()) shutdown_event();

      // move in/out
      if (keyboard.zoom()) zoom_event();

      // move around
      if (keyboard.joystick()) joystick_event(slave_trait);

      // adjust the state
      if (slave_frame.visible) {
        state = (state + keyboard.delta_state())%4;
        if (state != last_state) check_state(slave_trait,tray_trait);
      }

      // face keys
      if (keyboard.face_keys()) face_event(slave_trait,tray_trait);

      // enter key
      if (keyboard.fxn_keys()) special_event();
    });
    
    // notifyOnRemove(function() {
    // });
  }

  /**
   * Make sure that we are not in invalid state situations
   */
  function check_state(slave_trait:SlaveFrameTrait,tray_trait:TrayTrait) {
    if ((state == 2) && (slave_trait.get_current_grip() == 0)) state = 0;

    tray_trait.hide_grips();

    if (state == 0) slave_trait.show_default();
    else if (state == 1) {
      slave_trait.show_default();
      tray_trait.toggle_grips();
    }
    else if (state == 2) slave_trait.show_spin();
    else if (state == 3) slave_trait.show_move();

    keyboard.reset("NextState");
    keyboard.reset("PrevState");
    last_state = state;
    
    if ((help_trait != null) && (help_trait.get_current() >= WALL_SCREENINDEX))
      help_trait.show_screen(state + WALL_SCREENINDEX);
  }

  function shutdown_event() {
    scene.getTrait(SceneTrait).shutdown();
    keyboard.reset("Shutdown");
  }

  function zoom_event() {
    var camera_trait = camera_trait();

    if (keyboard.state("MoveIn")) camera_trait.zoom_in();
    else if (keyboard.state("MoveOut")) camera_trait.zoom_out();

    if (current_help(ZOOM_SCREENINDEX)) {
      help_trait.show_next_screen();
    }
  }

  function joystick_event(slave_trait:SlaveFrameTrait) {
    var camera_trait = camera_trait();
    
    if (keyboard.state("Center/Activate")) {
      var temp:Int = slave_trait.get_current_grip();
      // if the slave frame has an active hold add it to used
      slave_trait.add_to_used();
      // activate nearby grip
      slave_trait.activate_grip();
      // if current grip was refound then just add it to used
      if ((temp != 0) && (slave_trait.get_current_grip() == temp))
        slave_trait.add_to_used();
      // if no nearby grip or current grip was found click the center frame
      if (slave_trait.get_current_grip() == 0) {
        state = 0;
        camera_trait.pick_center_tile();
      }
 
      // get the frame traits from master and slave frame objects
      var frame_traits = [frame.getTrait(FrameTrait),
        slave_frame.getTrait(FrameTrait)];
      // if master frame is active make it not active
      if (frame_traits[0].is_active())
        frame_traits[0].toggle_active(); 
      // if slave frame is not active make active
      if (!frame_traits[1].is_active())
        frame_traits[1].toggle_active();

      keyboard.reset("Center/Activate");

      if (current_help(SPACE_SCREENINDEX)) {
        help_trait.show_next_screen();
      }
    } else {
      if (keyboard.state("MoveRight")) camera_trait.move_right();
      else if (keyboard.state("MoveLeft")) camera_trait.move_left();
      if (keyboard.state("MoveDown")) camera_trait.move_down();
      else if (keyboard.state("MoveUp")) camera_trait.move_up();

      if (current_help(MOVECAMERA_SCREENINDEX)) {
        help_trait.show_next_screen();
      }
    }
  }

  function face_event(slave_trait:SlaveFrameTrait,tray_trait:TrayTrait) {
    if (state == 0) {
      var master_trait = frame.getTrait(MasterFrameTrait);

      // if the slave frame has an active hold add it to used before moving
      slave_trait.add_to_used();

      if (keyboard.state("FaceLeft")) master_trait.move_left();
      else if (keyboard.state("FaceUp")) master_trait.move_up();
      else if (keyboard.state("FaceRight")) master_trait.move_right();
      else if (keyboard.state("FaceDown")) master_trait.move_down();

    } else if (state == 1) {
      if (keyboard.state("FaceLeft")) tray_trait.show_prev_grip();
      else if (keyboard.state("FaceUp")) {
        tray_trait.remove_remove(slave_trait.get_current_grip());
        slave_trait.show_grip(0);
      } else if (keyboard.state("FaceRight")) tray_trait.show_next_grip();
      else if (keyboard.state("FaceDown")) {
        if (!slave_trait.is_used(tray_trait.get_current()))
          slave_trait.show_grip(tray_trait.get_current());
      }
    } else if (state == 2) {
      if (keyboard.state("FaceLeft")) slave_trait.rotate_ccw();
      else if (keyboard.state("FaceRight")) slave_trait.rotate_cw();
    } else if (state == 3) {
      if (keyboard.state("FaceLeft")) slave_trait.move_left();
      else if (keyboard.state("FaceUp")) slave_trait.move_up();
      else if (keyboard.state("FaceRight")) slave_trait.move_right();
      else if (keyboard.state("FaceDown")) slave_trait.move_down();
    }

    // reset the state for states frame move and hold selection states
    if (state < 2) {
      if (keyboard.state("FaceLeft")) keyboard.reset("FaceLeft");
      else if (keyboard.state("FaceUp")) keyboard.reset("FaceUp");
      else if (keyboard.state("FaceRight")) keyboard.reset("FaceRight");
      else if (keyboard.state("FaceDown")) keyboard.reset("FaceDown");
    }
  }

  function special_event() {
    if (keyboard.state("CloseHelp") && (help_trait != null) && (help_trait.get_current() >= WALL_SCREENINDEX)) {
      keyboard.reset(); // reset all keyboard states
      // make the help disappear immediately
      remove_help();
      show_icons();
    } else if (help_trait == null) {
      if (keyboard.state("ShowHelp")) {
        keyboard.reset(); // reset all keyboard states
        spawn_help();
        ObjectTools.setVisibility(help_icon,false);
        ObjectTools.setVisibility(info_icon,false);
      } else if (keyboard.state("ShowInfo")) {
        keyboard.reset("ShowInfo");
        ObjectTools.setVisibility(scene.getChild(info_name),true);
      }
    }
  }
  
  function camera_trait() {
    if (camera != null)
      return camera.getTrait(CameraTrait);
    
    throw "Camera is null";
    scene.getTrait(SceneTrait).shutdown();
    
    return null;
  }

  function tray_trait(slave_trait:SlaveFrameTrait):TrayTrait {
    var tray_trait:TrayTrait = null;

    tray_trait = slave_trait.get_tray().getTrait(TrayTrait);

    return tray_trait;
  }
  
  function get_icon_trait(i:Int):InTheWayTrait {
    if ((i <= 3) && (icon_traits[i] != null)) return icon_traits[i];
    
    if (i == 0) {
      info_icon = scene.getChild(info_icon_name);
      if (info_icon != null)
        icon_traits[0] = info_icon.getTrait(InTheWayTrait);
    } else if (i == 1) {
      help_icon = scene.getChild(help_icon_name);
      if (help_icon != null)
        icon_traits[1] = help_icon.getTrait(InTheWayTrait);
    }
    
    return icon_traits[i];
  }

  /**
   * Helper function to show the help and info icons
   */
  function show_icons() {
    if (info_icon == null) get_icon_trait(0);
    ObjectTools.setVisibility(info_icon,true);
    if (help_icon == null) get_icon_trait(1);
    ObjectTools.setVisibility(help_icon,true);
  }

  function spawn_help() {
    scene.spawnObject(help_name, null, null);
    help = scene.getChild(help_name);
    help_trait = help.getTrait(ScreenSequenceTrait);
  }

  function remove_help() {
    for (c in help.children) c.remove();
    help.remove();
    help_trait = null;
  }

  /**
   * Helper function that returns true only if help_trait is not null and its
   * current screen index is equal to i else false
   * @param i check if help is showing current screen
   * @return Bool
   */
  function current_help(i:Int=null):Bool {
    if (i == null) return (help_trait != null);
    else {
      if (help_trait == null) return false;
      return (help_trait.get_current() == i);
    }
  }
}