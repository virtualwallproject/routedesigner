package arm;

import iron.math.Vec2;
import kha.Window;
import kha.FastFloat;
import kha.Scheduler;

using Lambda;

class KhaSurface {
  var w:Window;
  var radius:Int = 10;
  var tap_time:FastFloat = 0.5;
  var hold_time:FastFloat = 1.0; // gets reset in new
  var touches:Array<Bool> = [false, false, false];
  var touched:Int = -1;
  var check_touched:Bool = false;
  var start:Array<Vec2> = [new Vec2(), new Vec2(), new Vec2()];
  var last:Array<Vec2> = [new Vec2(), new Vec2(), new Vec2()];
  var max:Array<Vec2> = [new Vec2(), new Vec2(), new Vec2()];
  var t_start:Array<FastFloat> = [0,0,0];
  var t_last:Array<FastFloat> = [0,0,0];
  var last_single_tap:Tap = new Tap();
  var tray_drag_index:Int;
  var is_mouse:Bool = false;
  
  public function new() {
    w = Window.get(0);

    if (Std.is(this,KhaMouse)) {
      is_mouse = true;
      radius = 5;
    } else {
      if (w.width > w.height) radius = Math.round(w.height/20);
      else radius = Math.round(w.width/20);
    }

    hold_time = tap_time + 0.5;
  }
  
  public function reset() {
    // save the first finger info if a single tap is true
    if (tapped(1)) last_single_tap.update(t_start[0],start[0].x,start[0].y);
    
    for (i in 0...3) {
      touches[i] = false;
      start[i].set(0,0);
      last[i].set(0,0);
      max[i].set(0,0);
      t_start = [0,0,0];
      t_last = [0,0,0];
    }
    
    touched = -1;
    check_touched = false;
    tray_drag_index = 0;
  }

  /**
   * Return the state
   * This should be called by the parent's notifyOnUpdate fxn then the state
   * used to send events in the parent's notifyOnLateUpdate
   * @return the int representing the state of the surface
   */
  public function current_state():Int {
    // check for presses first but if it's less than tap time it should fail
    // and check for taps
    var b:Bool = false;

    // check for double-tap
    if (double_tapped()) return (1 | 6<<2);

    // check for tap
    var i:Int = 3;
    while ((!b) && (i > 0)) {b = tapped(i); i--;}
    if (b) return (i+1 | 1<<2);

    // check for zoom (for mouse) or swipe (for surface)
    if (is_mouse) {
      if (squeezed() || stretched()) return (2 | 5<<2);
    } else {
      i = 3;
      while ((!b) && (i > 0)) {b = swiped(i); i--;}
      if (b) return (i+1 | 3<<2);
    }

    i = 3;
    while ((!b) && (i > 0)) {
      b = pressed(i);
      i = (b) ? i:i-1;
    }
    if (b) {
      // update time
      update_time(i);
      // check for hold
      if (held(i)) return (i | 7<<2);
      if ((i == 2) || is_mouse) {
        // check for spin
        if (rotated() != 0) return (2 | 4<<2);
        // check for pinch
        if (squeezed() || stretched()) return (2 | 5<<2);
      }
      // check for drag
      if (dragged(i)) return (i | 2<<2);
    }

    return 0;
  }
  
  public function touchStart(index:Int, x:Int, y:Int) {
    if (index > 2) return;
    else if (index == 0) reset();
    
    touches[index] = true;
    
    start[index].set(x,y);
    last[index].set(x,y);
    max[index].set(x,y);
    t_start[index] = Scheduler.time();
    t_last[index] = t_start[index];
    
    touched = index;
  }
  
  public function touchEnd(index:Int, x:Int, y:Int) {
    if (index > 2) return;
    
    touches[index] = false;
    
    if (index == 0) {
      check_touched = true;
    }
  }
  
  public function touchMove(index:Int, x:Int, y:Int) {
    last[index].set(x,y);
    if (last[index].distanceTo(start[index]) >
      max[index].distanceTo(start[index])) max[index].set(x,y);
  }
  
  /**
  * Check if exactly a number of fingers has been released
  * Always check at end of update when using a surface so that a reset is 
  * called if necessary
  * @param num number of fingers to check if have been released
  */
  public function released(num:Int) {
    if (check_touched && (touched == (num-1))) {
      reset();
      return true;
    }
    
    return false;
  }
  
  /**
  * Check if exactly a number of fingers are currently pressed
  * @param num number of fingers to check if are pressed
  */
  public function pressed(num:Int):Bool {
    if (num > 3) return false;

    var p = [for (i in 0...num) touches[i]];
    var np = (num < 3) ? [for (i in num...3) touches[i]] : [false];
    return !(p.has(false) || np.has(true));
  }
  
  /**
  * Check if a certain number of fingers were tapped
  * A tap is a move with a length less than radius and time less than tap
  * time
  * @param num 
  */
  public function tapped(num:Int) {
    if ((num > 3) || !check_touched || (touched != (num-1))) return false;
    
    // check magnitude of tap and length of press
    var l:Array<FastFloat> = [for (i in 0...num) move_max(i).length()];
    var t:Array<FastFloat> = [for (i in 0...num) t_hold(i)];
    return (l.foreach(function(v) return v < radius) &&
      t.foreach(function(v) return v < tap_time));
  }
  
  /**
  * Check for single finger double tap
  */
  public function double_tapped():Bool {
    if (tapped(1)) {
      var temp:Tap = new Tap(t_start[0],start[0].x,start[0].y);
      var diff:Array<FastFloat> = last_single_tap.diff(temp);
      return ((diff[0] < hold_time) && (diff[1] < radius));
    } else return false;
  }
  
  /**
  * Check if a certain number of fingers are held
  * A hold is a move with a length less than radius and time greater than
  * hold time
  * @param num 
  */
  public function held(num:Int) {
    if ((num > 3) || (touched != (num-1))) return false;
    
    // check magnitude of tap and length of press
    var l:Array<FastFloat> = [for (i in 0...num) move_max(i).length()];
    var t:Array<FastFloat> = [for (i in 0...num) t_hold(i)];
    return (l.foreach(function(v) return v < radius) &&
      t.foreach(function(v) return v > hold_time));
  }
  
  /**
  * Check if a number of fingers are dragged in a particular direction
  * @param num number of fingers to check if have been swiped
  * @param axis the orientation of the swipe (null=either,true=X,false=Y)
  * @param sign check for plus or minus move (null=either,false=minus,true=plus)
  */
  public function dragged(num:Int,?axis:Bool,?sign:Bool) {
    if (num > 3) return false;
    
    var temp:Array<Vec2> = [for (i in 0...num) move_last(i)];

    var sum = function(num:FastFloat, total:FastFloat) return total += num;

    // check the difference between the relative moves of each finger
    var x_moves:Array<FastFloat> = [for (i in 0...num) temp[i].x];
    var avg:FastFloat = x_moves.fold(sum,0)/num;
    if (x_moves.exists(function(v) return (Math.abs(v - avg) > radius)))
      return false;
    var y_moves:Array<FastFloat> = [for (i in 0...num) temp[i].y];
    var avg:FastFloat = y_moves.fold(sum,0)/num;
    if (y_moves.exists(function(v) return (Math.abs(v - avg) > radius)))
      return false;
    // check axis of move
    var dists:Array<FastFloat>;
    if (axis==null){
      dists = [for (i in 0...num) Math.max(Math.abs(temp[i].x),Math.abs(temp[i].y))];
    } else {
      dists = [for (i in 0...num) axis ? temp[i].x : temp[i].y];
    }
    // check magnitude and sign of move
    if (sign==null || sign) {
      return dists.foreach(function(v) return v > radius);
    } else {
      return dists.foreach(function(v) return v < -radius);
    }
  }
  
  /**
  * Check if a number of fingers have been swiped a particular direction
  * @param num number of fingers to check if have been swiped
  * @param axis the orientation of the swipe (true=X,false=Y)
  * @param sign check for plus or minus move (false=minus,true=plus)
  */
  public function swiped(num:Int,?axis:Bool,?sign:Bool) {
    if ((num > 3) || !check_touched || (touched != (num-1))) return false;

    var t:Array<FastFloat> = [for (i in 0...num) t_hold(i)];
    
    return (t.foreach(function(v) return v < tap_time) &&
      dragged(num,axis,sign));
  }
  
  /**
  * Checks for a two finger squeeze
  */
  public function squeezed() {
    if (!pressed(2)) return false;
    
    var dist_start:FastFloat = start[0].distanceTo(start[1]);
    var dist_last:FastFloat = last[0].distanceTo(last[1]);
    if (dist_start > dist_last + 2*radius) {
      return true;
    } else return false;
  }
  
  /**
  * Checks for a two finger stretch
  */
  public function stretched() {
    if (!pressed(2)) return false;
    
    var dist_start:FastFloat = start[0].distanceTo(start[1]);
    var dist_last:FastFloat = last[0].distanceTo(last[1]);
    if (dist_start + 2*radius < dist_last) {
      return true;
    } else return false;
  }

  /**
   * Checks for two finger rotation
   * returns the angle of rotation in radians or 0 if not rotated with plus 
   * rotation defined as ccw and negative as cw and minimum is 5
   */
  public function rotated():FastFloat {
    if (!pressed(2)) return 0;

    // check that the two fingers are at least diameter apart
    var dist_start:FastFloat = start[0].distanceTo(start[1]);
    var dist_last:FastFloat = last[0].distanceTo(last[1]);
    if ((dist_start < 2*radius) || (Math.abs(dist_start-dist_last) > 2*radius))
      return 0;

    // should we check that the fingers have not been squeezed or pinched?

    // normalize vectors passing through start and last touches
    var thru_start:Vec2 = start[1].clone().sub(start[0]).normalize();
    var thru_last:Vec2 = last[1].clone().sub(last[0]).normalize();

    // use dot product to calculate angle and cross product to set sign
    var temp:FastFloat = Math.acos(thru_last.dot(thru_start));
    if (thru_start.cross(thru_last) > 0.0) temp = -temp; 

    if (Math.abs(temp) > 1*Math.PI/180) return temp
    else return 0;
  }
  
  public function get_start(num:Int):Vec2 {
    if (num > 3) return new Vec2();
    
    return start[num-1];
  }
  
  public function get_last(num:Int):Vec2 {
    if (num > 3) return new Vec2();
    
    return last[num-1];
  }
  
  /**
  * Returns the difference of the last and the start
  */
  public function move_last(i:Int):Vec2 {
    return (new Vec2()).subvecs(last[i],start[i]);
  }
  
  /**
  * Returns the difference of the max and the start
  */
  function move_max(i:Int) {
    return (new Vec2()).subvecs(max[i],start[i]);
  }
  
  /**
  * Returns the time the finger has been pressed in fractional seconds
  * @param i the finger index (not number of fingers)
  */
  public function t_hold(i:Int) {
    return t_last[i] - t_start[i];
  }

  /**
   * Update the hold time for all presses up to and including index i
   * @param i the max index of finger/hold to update
   */
  function update_time(i:Int) {
    for (j in 0...(i+1)) t_last[j] = Scheduler.time();
  }
  
  /**
  * Set max time for taps
  * @param t new max tap time (>=0)
  */
  public function set_tap(t:FastFloat) {
    if (t < 0) t = 0;
    tap_time = t;
  }
  
  /**
  * Set min time for holds
  * @param t new min hold time (>= tap time)
  */
  public function set_hold(t:FastFloat) {
    if (t < tap_time) t = tap_time;
    hold_time = t;
  }
  
  /**
   * Get hold time
   * @return FastFloat return hold_time
   */
  public function get_hold():FastFloat return hold_time;

	/**
	 * Get the tray drag index variable or compute it based on a length=
	 * @return Int the class variable
	 */
	public function get_drag_index():Int return tray_drag_index;

	public function set_drag_index(i:Int) tray_drag_index = i;
  
}

class Tap {
  var time:FastFloat;
  var loc:Vec2;
  
  /**
  * Constructor for a tap class
  * @param time the time that the tap started
  * @param x the x screen position that tap started
  * @param y the y screen position that tap starte
  */
  public function new(time:FastFloat=0,x:FastFloat=0,y:FastFloat=0) {
    this.time = time;
    this.loc = new Vec2(x,y);
  }
  
  /**
  * Update the tap with new information
  * @param time the time
  * @param x x screen position
  * @param y y screen position
  */
  public function update(time:FastFloat,x:FastFloat,y:FastFloat) {
    this.time = time;
    this.loc.set(x,y);
  }
  
  /**
  * Compare another tap with this tap
  * @param t the tap to compare with this one
  * @return Array<FastFloat> with other tap less this tap time and position
  * delta
  */
  public function diff(t:Tap):Array<FastFloat> {
    return [
      t.time - time,
      t.loc.distanceTo(loc)
    ];
  }
}