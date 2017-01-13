package koneko;

using  StringTools;
using  koneko.StackItem; // for .type and .toString

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
    var sb = new StringBuf();
    var a = new Array<String>();
    sb.add("<");
    sb.add(s.length);
    sb.add("> ");
    for( i in s ) {
      a.unshift(i.toString());
    }
    sb.add( a.join(" ") );
    sb.add(" ");
    out(sb.toString());
    return Noop;
  }

  public static function show_debug(s: Stack): StackItem {
    Sys.println(s.toString());
    return Noop;
  }

  public static function print(s: Stack): StackItem {
    check_underflow(s);
    var el = s.pop();
    out( 
        switch( el ) {
          case IntSI(i)     : Std.string(i);
          case FloatSI(f)   : Std.string(f);
          case StringSI(s)  : s;
          case AtomSI(s)    : '<A:$s>';
          case DefAtomSI(s) : '<D:$s>';
          case QuoteSI(_)   : '<Quote>';
          case BuiltinSI(_) : '<Builtin>';
          case Noop         : '<Noop>';
          case _            : '<Unknown>';
        }
    );
    return Noop;
  }

  public static function drop(s: Stack): StackItem {
    assert_stack_has(s, 1);
    return s.pop();
  }

  public static function swap(s: Stack): StackItem {
    assert_stack_has(s, 2);
    s.swap();
    return Noop;
  }

  public static function pop_and_print(s: Stack): StackItem {
    check_underflow(s);
    out(s.pop().toString());
    return Noop;
  }

  public static function add(s: Stack): StackItem {
    var r = math_add(s);
    switch( r ) {
      case Noop : return Noop;
      case _    :
        consume(s, 2);
        s.push(r);
    }
    return Noop;
  }

  public static function quit(s: Stack): StackItem {
    Sys.exit(0);
    return Noop;
  }




  //
  // private
  //
  static function out(v: String) {
    Sys.stdout().writeString(v);
  }

  static function check_underflow(s: Stack) {
    if( s.is_empty() )
      throw KonekoException.StackUnderflow;
  }

  static function assert_stack_has(s: Stack, n: Int) {
    if( n < 1 )
      throw KonekoException.WrongAssertionParam;
    if( s.length < n )
      throw KonekoException.StackUnderflow;
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
      return add_strings(snd, fst); // it's more logical concat NOS + TOS
                                    // as they are added this way
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

  static inline function consume(s: Stack, n: Int) {
    for( i in 0 ... n )
      s.pop();
  }
}
