package arm;

import iron.Scene;
import kha.input.Keyboard;
import kha.input.KeyCode;
import kha.Window;
#if kha_js
import arm.JoyconKeyboard;
#end

using Lambda;
#if kha_js
class SwitchJoyCon {
  public static function listConnectedJoyCons():Dynamic {
    return js.Syntax.code('window.listConnectedJoyCons()');
  }
}
#end

class KhaKeyboard {
  var scene_trait:SceneTrait;
  var w:Window;
  var states:Map<String, Bool> = ["MoveUp" => false,"MoveDown" => false,
    "MoveLeft" => false,"MoveRight" => false,"Center/Activate" => false,
    "MoveIn" => false,"MoveOut" => false,"NextState" => false,
    "PrevState" => false,"FaceLeft" => false,"FaceUp" => false,
    "FaceDown" => false,"FaceRight" => false,"ShowInfo" => false,
    "ShowHelp" => false,"Shift" => false,"Shutdown" => false,
    "CloseHelp" => false
  ];
  var slave_state:Int = 0;
  var next_slave_state:Int = 0;
  var joycon:Dynamic = null;
  var joyboard:JoyconKeyboard;

  public function new(scene:Scene) {
    w = Window.get(0);
    scene_trait = scene.getTrait(SceneTrait);

    // add listeners for keyboard
    Keyboard.get().notify(onKeyDown, onKeyUp);
    
    #if kha_js
    if (scene_trait.num_joycons() > 0) {
      var devices:Dynamic = SwitchJoyCon.listConnectedJoyCons();
      joycon = devices[0].open();
      joyboard = new JoyconKeyboard(this,joycon.side == 'left');
      js.Syntax.code("this.joycon.on('change',() => {this.joyboard.onChange({0})})",joycon.buttons);
      trace('joycon\n${joycon}');
    }
    #end
  }

  public function remove() {
    Keyboard.get().remove(onKeyDown, onKeyUp, null);
  }

  public function reset(s:String=null) {
    if (s == null)
      for (s in states.keys()) states[s] = false;
    else if (states.exists(s))
      states[s] = false;
  }

  public function state(s:String=null):Bool {
    if (states.exists(s)) return states[s];
    else return false;
  }

  public function trigger(s:String=null) {
    if (states.exists(s)) states[s] = true;
  }

  public function onKeyDown(key:Int) {
    switch (key) {
      case Up: states["MoveUp"] = true;
      case Down: states["MoveDown"] = true;
      case Left: states["MoveLeft"] = true;
      case Right: states["MoveRight"] = true;
      case Space: states["Center/Activate"] = true;
      case Period: states["MoveIn"] = true;
      case Comma: states["MoveOut"] = true;
      case Tab:
        if (states["Shift"]) states["PrevState"] = true;
        else states["NextState"] = true;
      case Shift: states["Shift"] = true;
      case KeyCode.A: states["FaceLeft"] = true;
      case KeyCode.W: states["FaceUp"] = true;
      case KeyCode.D: states["FaceRight"] = true;
      case KeyCode.S: states["FaceDown"] = true;
      case KeyCode.I: states["ShowInfo"] = true;
      case KeyCode.H:
        states["ShowHelp"] = true;
        #if kha_js
        if (scene_trait.num_joycons() > 0)
          states["CloseHelp"] = true;
        #end
      case QuestionMark: states["ShowHelp"] = true;
      case Slash: states["ShowHelp"] = true;
      case Escape: states["Shutdown"] = true;
      case Return: states["CloseHelp"] = true;
    }
  }

  public function onKeyUp(key:Int) {
    switch (key) {
      case Up: states["MoveUp"] = false;
      case Down: states["MoveDown"] = false;
      case Left: states["MoveLeft"] = false;
      case Right: states["MoveRight"] = false;
      case Space: states["Center/Activate"] = false;
      case Period: states["MoveIn"] = false;
      case Comma: states["MoveOut"] = false;
      case Tab:
        states["PrevState"] = false;
        states["NextState"] = false;
      case Shift: states["Shift"] = false;
      case KeyCode.A: states["FaceLeft"] = false;
      case KeyCode.W: states["FaceUp"] = false;
      case KeyCode.D: states["FaceRight"] = false;
      case KeyCode.S: states["FaceDown"] = false;
      case KeyCode.I: states["ShowInfo"] = false;
      case KeyCode.H:
        states["ShowHelp"] = false;
        #if kha_js
        if (scene_trait.num_joycons() > 0)
          states["CloseHelp"] = false;
        #end
      case QuestionMark: states["ShowHelp"] = false;
      case Slash: states["ShowHelp"] = false;
      case Escape: states["Shutdown"] = false;
      case Return: states["CloseHelp"] = false;
    }
  }

  public function fxn_keys() {
    return states["ShowInfo"] || states["ShowHelp"] || states["CloseHelp"];
  }

  public function shutdown():Bool {
    return states["Shutdown"];
  }

  public function delta_state():Int {
    if (states["PrevState"]) return -1;
    else if (states["NextState"]) return 1;
    else return 0;
  }

  public function zoom():Bool {
    return (states["MoveIn"] || states["MoveOut"]);
  }

  public function joystick():Bool {
    return (states["MoveUp"] || states["MoveDown"]
      || states["MoveLeft"] || states["MoveRight"]
      || states["Center/Activate"]);
  }

  public function face_keys():Bool {
    return (states["FaceLeft"] || states["FaceUp"]
      || states["FaceRight"] || states["FaceDown"]);
  }

  public function get_joycon():Dynamic return joycon;
}