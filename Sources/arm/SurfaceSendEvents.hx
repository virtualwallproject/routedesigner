package arm;

import kha.FastFloat;
import iron.math.Vec2;
import iron.Scene;
import iron.object.Object;
import iron.object.CameraObject;
import iron.App;
import kha.input.Surface;
import kha.input.Mouse;

import arm.KhaSurface;
import arm.KhaMouse;

class SurfaceSendEvents extends iron.Trait {
  var scene:Scene;
  var camera:CameraObject;
  var frame:Object;
  var slave_frame:Object;
	var surface:KhaSurface;
	var mouse:KhaMouse;
  var info_icon:Object;
  var help_icon:Object;
  var help:Object = null;
  var help_trait:ScreenSequenceTrait;
  var showtray_icon:Object;
  var hidetray_icon:Object;
  var icon_traits:Array<InTheWayTrait> = [null, null, null, null];
  var state:Int;
  
  var MOVECAMERA_SCREENINDEX:Int = 2;
  var ZOOM_SCREENINDEX:Int = 3;
  var TAPWALL_SCREENINDEX:Int = 4;
  var TAPBUCKET_SCREENINDEX:Int = 5;
  var SETHOLD_SCREENINDEX:Int = 6;
  var DRAGHOLDS_SCREENINDEX:Int = 7;
  var SPINHOLD_SCREENINDEX:Int = 8;
  var MOVEHOLD_SCREENINDEX:Int = 9;
  var TWOTAPHOLD_SCREENINDEX:Int = 10;
  
  @prop
  var info_icon_name: String;
  @prop
  var info_name: String;
  @prop
  var help_icon_name: String;
  @prop
  var help_name: String;
  @prop
  var tray_show_icon_name: String;
  @prop
  var tray_hide_icon_name: String;
  @prop
  var tray_name: String;
  @prop
  var is_mouse:Bool = false;

  static inline function pick_input(a:KhaMouse,b:KhaSurface,pick_a:Bool) {
    return ((pick_a) ? a : b);
  }
  
  public function new() {
    super();
    
    notifyOnInit(function() {
      scene = Scene.active;
      camera = scene.camera;
      frame = camera_trait().get_frame();
      slave_frame = frame.getTrait(MasterFrameTrait).get_slave();
      
      if (!is_mouse){
        surface = new KhaSurface();
        var temp:Surface = Surface.get();
        if (temp != null) {
          temp.notify(
            surface.touchStart,
            surface.touchEnd,
            surface.touchMove);
        }
      } else {
        mouse = new KhaMouse(camera);
        var temp:Mouse = Mouse.get();
        if (temp != null) {
          temp.notify(
            mouse.touchStart,
            mouse.touchEnd,
            mouse.mouseMove,
            mouse.wheelMove);
        }
      }
      
      state = pick_input(mouse,surface,is_mouse).current_state();

      scene.spawnObject(help_name, null, null);
      help = scene.getChild(help_name);
      help_trait = help.getTrait(ScreenSequenceTrait);
    });
    
    notifyOnUpdate(function() {
      var temp = pick_input(mouse,surface,is_mouse);
      var temp2:Int = temp.current_state();
      if (temp2 != state) {
        state = temp2;
      }
      
      switch (state) {
        case 5: one_tap(false);
        case 9: one_drag();
        case 13: one_swipe();
        case 18: two_spin();
        case 22: two_pinch();
        case 25: one_tap(true);
        case 29: one_hold();
        case 30: two_hold();
        case 31: three_hold();
        default: slave_frame.getTrait(SlaveFrameTrait).show_default();
      }
      
      // run released to reset
      temp.released(1);
      temp.released(2);
      temp.released(3);
    });
    
    // notifyOnRemove(function() {
    // });
  }
  
  function camera_trait():CameraTrait {
    if (camera != null)
      return camera.getTrait(CameraTrait);
    
    throw "Camera is null";
    scene.getTrait(SceneTrait).shutdown();
    
    return null;
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
    } else if (i == 2) {
      showtray_icon = scene.getChild(tray_show_icon_name);
      if (showtray_icon != null)
        icon_traits[2] = showtray_icon.getTrait(InTheWayTrait);
    } else if (i == 3) {
      hidetray_icon = scene.getChild(tray_hide_icon_name);
      if (hidetray_icon != null)
        icon_traits[3] = hidetray_icon.getTrait(InTheWayTrait);
    } else return null;
    
    return icon_traits[i];
  }

  function tray_trait():TrayTrait {
    var tray_trait:TrayTrait = null;

    if (scene.getChild(tray_name).visible)
      tray_trait = scene.getChild(tray_name).getTrait(TrayTrait);

    return tray_trait;
  }
  
  /**
  * KhaSurface state 5: handle a one finger tap
  * That means check if an icon was tapped and do the appropriate action if
  * it was, otherwise move the frame to the tap location
  * @param double true for a double tap and will try to reactivate a grip
  */
  function one_tap(double:Bool) {
    var camera_trait = camera_trait();
    var frame_traits = [frame.getTrait(FrameTrait),slave_frame.getTrait(FrameTrait)];
    var slave_trait = slave_frame.getTrait(SlaveFrameTrait);
    
    // setup traits
    var info_icon_trait = get_icon_trait(0);
    var help_icon_trait = get_icon_trait(1);
    var showtray_icon_trait = get_icon_trait(2);
    var hidetray_icon_trait = get_icon_trait(3);
    var tray_trait = tray_trait();
    
    // store the tap info
    var temp = pick_input(mouse,surface,is_mouse);
    var click:Vec2 = new Vec2(temp.get_last(1).x,temp.get_last(1).y);
    
    var icons_clicked:Bool = false;
    
    // check if any icons were tapped
    if ((!scene.getChild(info_name).visible) && (info_icon_trait != null) && (info_icon_trait.is_clicked(click.x,click.y))) {
      // show the info window
      ObjectTools.setVisibility(scene.getChild(info_name),true);
      icons_clicked = true;
    } else if ((!scene.getChild(info_name).visible) && (help_icon_trait != null) && (help_icon_trait.is_clicked(click.x,click.y))) {
      // show the help window
      help_trait.show_next_screen();
      // hide help and info icons
      ObjectTools.setVisibility(help_icon,false);
      ObjectTools.setVisibility(info_icon,false);
      icons_clicked = true;
    } else if (tray_trait != null) {
      if (showtray_icon_trait.is_clicked(click.x,click.y) || hidetray_icon_trait.is_clicked(click.x,click.y)) {
        tray_trait.toggle_grips();
        icons_clicked = true;

        if (help_trait.get_current() == TAPBUCKET_SCREENINDEX) {
          help_trait.show_next_screen();
        }

      } else {
        var clicked_grip:Int = Std.int(tray_trait.is_clicked(click.x,click.y));
        if (clicked_grip != 0) {
          if (slave_trait.remove_grip(clicked_grip)) {
            tray_trait.remove_remove(clicked_grip);
          } else if (clicked_grip == slave_trait.get_current_grip()) {
            tray_trait.remove_remove(clicked_grip);
            slave_trait.show_grip(0);
          } else {
            slave_trait.show_grip(clicked_grip);
          }
          icons_clicked = true;

          if (help_trait.get_current() == SETHOLD_SCREENINDEX) {
            help_trait.show_next_screen();
          }

        }
      }
    }
    
    // master frame move the frame to the click
    if ((!icons_clicked) && (camera_trait.click_frame(click.x,click.y))) {
      // if the slave frame has an active hold add it to used
      slave_trait.add_to_used();
      // update slave transform to master
      slave_trait.update_transform();
      // activate nearby grip
      if (double) {
        slave_trait.activate_grip();

        if (help_trait.get_current() == TWOTAPHOLD_SCREENINDEX) {
          help_trait.show_next_screen();
          show_icons();
        }

      } else if (help_trait.get_current() == TAPWALL_SCREENINDEX) {
        help_trait.show_next_screen();
      }

      // if master frame is active make it not active
      if (frame_traits[0].is_active())
        frame_traits[0].toggle_active();
      // if slave frame is not active make active
      if (!frame_traits[1].is_active())
        frame_traits[1].toggle_active();
    }
  }
  
  /**
  * KhaSurface state 9: handle a one finger drag
  * That means moving the camera around the wall or a grip on the wall
  */
  function one_drag() {
    var temp = pick_input(mouse,surface,is_mouse);
    var click:Vec2 = new Vec2(temp.get_start(1).x,temp.get_start(1).y);

    var camera_trait = camera_trait();
    var slave_trait = slave_frame.getTrait(SlaveFrameTrait);
    var tray_trait = tray_trait();

    // evaluate booleans
    var hold_clicked:Bool = camera_trait.click_hold(click.x,click.y);
    var tray_dragged:Bool = (tray_trait != null) && (tray_trait.is_dragged(click.x,click.y));
    var valid_state:Bool = slave_trait.get_shown() <= 0;

    if (hold_clicked || tray_dragged || valid_state) {
      if (tray_dragged) {
        var i:Int = tray_trait.calculate_drag_index(temp.move_last(0));
        var j:Int = temp.get_drag_index();
        if ((i != j) && (temp.dragged(1,true,false) || temp.dragged(1,true,true))) {
          temp.set_drag_index(i);
          if (i < j) tray_trait.show_next_grip();
          else if (i > j) tray_trait.show_prev_grip();
        }
      } else {
        if (hold_clicked) slave_trait.show_move();
        var s1:FastFloat = Math.min(1.0,temp.t_hold(0)/temp.get_hold());
        var directions:Array<Int> = [temp.drag_3bitdirection(0)];
        
        var i = 0;
        while (i < directions.length) {
          switch (directions[i]) {
            case 0: 
              (hold_clicked) ? slave_trait.move_right(s1) : camera_trait.move_left(s1);
            case 1:
              directions.push(0);
              directions.push(2);
            case 2:
              (hold_clicked) ? slave_trait.move_up(s1) : camera_trait.move_down(s1);
            case 3:
              directions.push(2);
              directions.push(4);
            case 4:
              (hold_clicked) ? slave_trait.move_left(s1) : camera_trait.move_right(s1);
            case 5:
              directions.push(4);
              directions.push(6);
            case 6:
              (hold_clicked) ? slave_trait.move_down(s1) : camera_trait.move_up(s1);
            case 7:
              directions.push(6);
              directions.push(0);
          }
          i++;
        }
      }

      // adjust tutorial screens
      if (
        (hold_clicked && (help_trait.get_current() == MOVEHOLD_SCREENINDEX)) ||
        (tray_dragged && (help_trait.get_current() == DRAGHOLDS_SCREENINDEX)) ||
        (valid_state && (help_trait.get_current() == MOVECAMERA_SCREENINDEX))
      ) {
        help_trait.show_next_screen();
      }
    }
  }
  
  /**
  * KhaSurface state 13: handle a one finger swipe
  * Change the hold for up/down swipe or move tray for left/right swipe
  */
  function one_swipe() {
    var temp = pick_input(mouse,surface,is_mouse);
    var slave_trait = slave_frame.getTrait(SlaveFrameTrait);
    var tray:Object = slave_trait.get_tray();
    var tray_trait = tray.getTrait(TrayTrait);
    if (tray.visible && temp.swiped(1,true,true))
      tray_trait.show_prev_grip();
    else if (tray.visible && temp.swiped(1,true,false))
      tray_trait.show_next_grip();
  }
  
  /**
  * KhaSurface state 18: handle a two finger spin
  */
  function two_spin() {
    var slave_trait = slave_frame.getTrait(SlaveFrameTrait);

    // only show the spin frame if frame is default
    if (slave_trait.get_shown() <= 0) slave_trait.show_spin();

    // only rotate if the slave frame is visible, has a grip and is in spin mode
    if (slave_frame.visible && (slave_trait.get_current_grip() > 0) && (slave_trait.get_shown() == 2)) {
      var rotated:Bool = false;
      var temp = pick_input(mouse,surface,is_mouse);

      // Rotate grip clockwise
      if (temp.rotated()<0) {
        slave_trait.rotate_cw();
        rotated = true;
      }

      // Rotate grip counterclockwise
      if (temp.rotated()>0) {
        slave_trait.rotate_ccw();
        rotated = true;
      }

      if ((rotated) && (help_trait.get_current() == SPINHOLD_SCREENINDEX)) {
        help_trait.show_next_screen();
      }
    }
  }
  
  /**
  * KhaSurface state 22: handle a two finger pinch/stretch
  */
  function two_pinch() {
    var slave_trait = slave_frame.getTrait(SlaveFrameTrait);

    // only zoom if the slave frame is visible and is in default mode
    if ((!slave_frame.visible) || (slave_frame.visible && (slave_trait.get_shown() == 0))) {
      var camera_trait = camera_trait();
      var temp = pick_input(mouse,surface,is_mouse);

      // Camera zoom in
      if (temp.stretched()) camera_trait.zoom_in();

      // Camera zoom out
      if (temp.squeezed()) camera_trait.zoom_out();

      if (Std.is(temp,KhaMouse)) cast(temp, KhaMouse).wheelUnMove();

      if (help_trait.get_current() == ZOOM_SCREENINDEX) {
        help_trait.show_next_screen();
      }
    }
  }

  function hold() {
    help_trait.reset_screen();
    show_icons();
  }

  function one_hold() {
    var temp = pick_input(mouse,surface,is_mouse);
    var click:Vec2 = new Vec2(temp.get_start(1).x,temp.get_start(1).y);

    var camera_trait = camera_trait();

    if (camera_trait.click_hold(click.x,click.y)) {
      var slave_trait = slave_frame.getTrait(SlaveFrameTrait);
      slave_trait.show_move();
    } else {
      var rotation = camera_trait.spinActiveHold(
        temp.get_start(1).x,
        temp.get_start(1).y,
        temp.get_last(1).x,
        temp.get_last(1).y
      );
      if (!Math.isNaN(rotation)) {
        var slave_trait = slave_frame.getTrait(SlaveFrameTrait);
        slave_trait.show_spin();
      } else hold();
    }
  }

  function two_hold() {
    var temp = pick_input(mouse,surface,is_mouse);
    var rotation:FastFloat = Math.NaN;
    rotation = camera_trait().spinActiveHold(
      temp.get_start(1).x,
      temp.get_start(1).y,
      temp.get_start(2).x,
      temp.get_start(2).y
    );

    if (!Math.isNaN(rotation)) {
      var slave_trait = slave_frame.getTrait(SlaveFrameTrait);
      slave_trait.show_spin();
    } else hold();
  }

  function three_hold() hold();

  public function current_state():Int {
    return state;
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
}