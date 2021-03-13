package arm;

import iron.math.Mat4;
import kha.FastFloat;

class MatrixTools {
  /**
   * Nicely format a matrix as a string
   * @param a 
   * @return String
   */
  static public function prettyPrint(a:Mat4,?scaled:Bool=false):String {
    var x:Mat4 = Mat4.identity();
    x.setFrom(a);
    x.toRotation();
    x.setLoc(a.getLoc());
    if (scaled) x.scale(a.getScale());
    return '[[${x._00}, ${x._10}, ${x._20}, ${x._30}],\n[${x._01}, ${x._11}, ${x._21}, ${x._31}],\n[${x._02}, ${x._12}, ${x._22}, ${x._32}],\n[${x._03}, ${x._13}, ${x._23}, ${x._33}]]';
  }

  /**
   * Check if two matrices are very similar
   * @param a 
   * @param b 
   * @param tol 
   * @return Bool True if sum of absolute value of component differences is
   * less than tol
   */
  static public function close(a:Mat4,b:Mat4,?tol:FastFloat=0.000001):Bool {
    var temp:FastFloat = 0.0;
    temp += Math.abs(a._00 - b._00);
    temp += Math.abs(a._10 - b._10);
    temp += Math.abs(a._20 - b._20);
    temp += Math.abs(a._30 - b._30);
    temp += Math.abs(a._01 - b._01);
    temp += Math.abs(a._11 - b._11);
    temp += Math.abs(a._21 - b._21);
    temp += Math.abs(a._31 - b._31);
    temp += Math.abs(a._02 - b._02);
    temp += Math.abs(a._12 - b._12);
    temp += Math.abs(a._22 - b._22);
    temp += Math.abs(a._32 - b._32);

    return (temp < tol);
  }
}