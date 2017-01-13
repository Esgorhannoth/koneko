package koneko;

using  koneko.StackItem; // for .type

/**
  All function return either a valuable StackItem or Noop;
  If a function is not to return anything (side-effect only, like `dup`) it must return Noop;
  Otherwise the value returned can be used elsewhere;
 **/
class Builtins {
  public static function dup(s: Stack): StackItem {
    s.dup();
    return Noop;
  }

  // TODO Debug
  public static function show_stack(s: Stack): StackItem {
    Sys.println(s.toString());
    return Noop;
  }

  public static function add(s: Stack): StackItem {
    s.push( math_add(s) );
    return Noop;
  }

  static function math_add(s: Stack): StackItem {
    var tos = s.tos();
    var nos = s.nos();
    var tos_type = tos.type();
    var nos_type = nos.type();

    // Both Int
    if( tos_type == "Int" && nos_type == "Int" ) {
      var fst = switch( tos ) {
        case IntSI(i) : i;
        case _        : throw KonekoException.IncompatibleTypes;  // unreachable
      }
      var snd = switch( nos ) {
        case IntSI(i) : i;
        case _        : throw KonekoException.IncompatibleTypes;  // unreachable
      }
      return add_int_int(fst, snd);
    }

    // One or both are Float
    if( tos_type == "Float" || nos_type == "Float" ) {
      var fst = switch( tos ) {
        case IntSI(i)   : cast(i, Float);
        case FloatSI(f) : f;
        case _          : throw KonekoException.IncompatibleTypes;  // unreachable
      }
      var snd = switch( nos ) {
        case IntSI(i)   : cast(i, Float);
        case FloatSI(f) : f;
        case _          : throw KonekoException.IncompatibleTypes;  // unreachable
      }
      return add_float_float(fst, snd);
    }

    // Both strings
    if( tos_type == "String" && nos_type == "String" ) {
      var fst = switch( tos ) {
        case StringSI(s) : s;
        case _           : throw KonekoException.IncompatibleTypes;  // unreachable
      }
      var snd = switch( nos ) {
        case StringSI(s) : s;
        case _           : throw KonekoException.IncompatibleTypes;  // unreachable
      }
      return add_strings(fst, snd);
    }

    throw KonekoException.IncompatibleTypes;
    return Noop; // should be unreachable
  }

  static function add_int_int(i: Int, j: Int): StackItem {
    return IntSI(i+j);
  }
  static function add_float_int(f: Float, i: Int): StackItem {
    return FloatSI(f+i);
  }
  static function add_float_float(f: Float, g: Float): StackItem {
    return FloatSI(f+g);
  }
  static function add_strings(f: String, g: String): StackItem {
    return StringSI(f+g);
  }
}
