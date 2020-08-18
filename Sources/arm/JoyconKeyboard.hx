package arm;

import haxe.ds.ReadOnlyArray;
import haxe.ds.StringMap;
import haxe.ds.IntMap;
import kha.input.KeyCode;

@:keep
class JoyconKeyboard {
  var receiver:KhaKeyboard;
  var buttons:StringMap<Dynamic>;
  var directions:IntMap<String> = new IntMap();
  var isLeft:Bool;

  public static final arrows:ReadOnlyArray<KeyCode> = [Down,Up,Left,Right];
  public static final left:StringMap<StringMap<Dynamic>> =
  [
    'Directions' =>
    [
      'RIGHT' => 0x00,
      'DOWN_RIGHT' => 0x01,
      'DOWN' => 0x02,
      'DOWN_LEFT' => 0x03,
      'LEFT' => 0x04,
      'UP_LEFT' => 0x05,
      'UP' => 0x06,
      'UP_RIGHT' => 0x07,
      'NEUTRAL' => 0x08
    ],
    'Buttons' =>
    [
      'dpadUp' => false,
      'dpadDown' => false,
      'dpadLeft' => false,
      'dpadRight' => false,
      'minus' => false,
      'screenshot' => false,
      'sl' => false,
      'sr' => false,
      'l' => false,
      'zl' => false,
      'analogStickPress' => false,
      'analogStick' => 0x08
    ]
  ];
  public static final right:StringMap<StringMap<Dynamic>> =
  [
    'Directions' =>
    [
      'LEFT' => 0x00,
      'UP_LEFT' => 0x01,
      'UP' => 0x02,
      'UP_RIGHT' => 0x03,
      'RIGHT' => 0x04,
      'DOWN_RIGHT' => 0x05,
      'DOWN' => 0x06,
      'DOWN_LEFT' => 0x07,
      'NEUTRAL' => 0x08
    ],
    'Buttons' =>
    [
      'a' => false,
      'x' => false,
      'b' => false,
      'y' => false,
      'plus' => false,
      'home' => false,
      'sl' => false,
      'sr' => false,
      'r' => false,
      'zr' => false,
      'analogStickPress' => false,
      'analogStick' => 0x08
    ]
  ];
  
  public function new(keyboard:KhaKeyboard,isLeft:Bool) {
    receiver = keyboard;
    if (isLeft) {
      this.buttons = left.get('Buttons').copy();
      for (key => value in left.get('Directions').keyValueIterator())
        this.directions.set(value,key);
    } else {
      this.buttons = right.get('Buttons').copy();
      for (key => value in right.get('Directions').keyValueIterator())
        this.directions.set(value,key);
    }
    this.isLeft = isLeft;
  }

  public function onChange(buttons:Dynamic) {
    for (key in Reflect.fields(buttons)) {
      var value:Dynamic = Reflect.field(buttons,key);
      var old_value:Dynamic = this.buttons.get(key);
      if (old_value != value) {
        buttonToKey(key,value,old_value);
        this.buttons.set(key,value);
      }
    }
  }

  function buttonToKey(name,value:Dynamic,old_value:Dynamic) {
    switch (name) {
      case 'a':
        (value) ? receiver.onKeyDown(KeyCode.D) : receiver.onKeyUp(KeyCode.D);
      case 'x':
        (value) ? receiver.onKeyDown(KeyCode.W) : receiver.onKeyUp(KeyCode.W);
      case 'b':
        (value) ? receiver.onKeyDown(KeyCode.S) : receiver.onKeyUp(KeyCode.S);
      case 'y':
        (value) ? receiver.onKeyDown(KeyCode.A) : receiver.onKeyUp(KeyCode.A);
      case 'plus':
        (value) ? receiver.onKeyDown(KeyCode.H) : receiver.onKeyUp(KeyCode.H);
      case 'home':
        (value) ? receiver.onKeyDown(KeyCode.I) : receiver.onKeyUp(KeyCode.I);
      case 'l':
        (value) ? receiver.onKeyDown(Tab) : receiver.onKeyUp(Tab);
      case 'r':
        (value) ? receiver.onKeyDown(Tab) : receiver.onKeyUp(Tab);
      case 'zl':
        (value) ? receiver.onKeyDown(Shift) : receiver.onKeyUp(Shift);
        (value) ? receiver.onKeyDown(Tab) : receiver.onKeyUp(Tab);
      case 'zr':
        (value) ? receiver.onKeyDown(Shift) : receiver.onKeyUp(Shift);
        (value) ? receiver.onKeyDown(Tab) : receiver.onKeyUp(Tab);
      case 'dpadUp':
        (value) ? receiver.onKeyDown(KeyCode.W) : receiver.onKeyUp(KeyCode.W);
      case 'dpadDown':
        (value) ? receiver.onKeyDown(KeyCode.S) : receiver.onKeyUp(KeyCode.S);
      case 'dpadLeft':
        (value) ? receiver.onKeyDown(KeyCode.A) : receiver.onKeyUp(KeyCode.A);
      case 'dpadRight':
        (value) ? receiver.onKeyDown(KeyCode.D) : receiver.onKeyUp(KeyCode.D);
      case 'minus':
        (value) ? receiver.onKeyDown(KeyCode.H) : receiver.onKeyUp(KeyCode.H);
      case 'screenshot':
        (value) ? receiver.onKeyDown(KeyCode.I) : receiver.onKeyUp(KeyCode.I);
      case 'sl':
        if (isLeft) {
          (value) ? receiver.onKeyDown(Period) : receiver.onKeyUp(Period);
        } else {
          (value) ? receiver.onKeyDown(Comma) : receiver.onKeyUp(Comma);
        }
      case 'sr':
        if (isLeft) {
          (value) ? receiver.onKeyDown(Comma) : receiver.onKeyUp(Comma);
        } else {
          (value) ? receiver.onKeyDown(Period) : receiver.onKeyUp(Period);
        }
      case 'analogStickPress':
        (value) ? receiver.onKeyDown(Space) : receiver.onKeyUp(Space);
      case 'analogStick':
        var values:Array<Dynamic> = [old_value,value];
        for (i in 0...values.length) {
          var v:Int = values[i];
          var down:Bool = (v == value) ? true : false;
          switch (directions.get(v)) {
            case 'LEFT':
              (down) ? receiver.onKeyDown(Left) : receiver.onKeyUp(Left);
            case 'UP_LEFT':
              (down) ? receiver.onKeyDown(Left) : receiver.onKeyUp(Left);
              (down) ? receiver.onKeyDown(Up) : receiver.onKeyUp(Up);
            case 'UP':
              (down) ? receiver.onKeyDown(Up) : receiver.onKeyUp(Up);
            case 'UP_RIGHT':
              (down) ? receiver.onKeyDown(Right) : receiver.onKeyUp(Right);
              (down) ? receiver.onKeyDown(Up) : receiver.onKeyUp(Up);
            case 'RIGHT':
              (down) ? receiver.onKeyDown(Right) : receiver.onKeyUp(Right);
            case 'DOWN_RIGHT':
              (down) ? receiver.onKeyDown(Right) : receiver.onKeyUp(Right);
              (down) ? receiver.onKeyDown(Down) : receiver.onKeyUp(Down);
            case 'DOWN':
              (down) ? receiver.onKeyDown(Down) : receiver.onKeyUp(Down);
            case 'DOWN_LEFT':
              (down) ? receiver.onKeyDown(Left) : receiver.onKeyUp(Left);
              (down) ? receiver.onKeyDown(Down) : receiver.onKeyUp(Down);
            case 'NEUTRAL':
              for (code in arrows) receiver.onKeyUp(code);
          }
        }
    }
  }
}