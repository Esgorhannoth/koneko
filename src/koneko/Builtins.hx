package koneko;

using  StringTools;
using  koneko.StackItem; // for .type and .toString

/**
  All functions return either a valuable StackItem or Noop;
  If a function is not to return anything (side-effect only, like `dup`) it must return Noop;
  Otherwise the value returned can be used elsewhere;
 **/
class Builtins {

  // A-
  public static function add(s: Stack): StackItem {
    assert_stack_has(s, 2);
    var r = math_add(s);
    switch( r ) {
      case Noop : return Noop;
      case _    :
        s.push(r);
    }
    return Noop;
  }

  // C-
  public static function clear_stack(s: Stack): StackItem {
    s.clear();
    return Noop;
  }

  // D-
  public static function define(s: Stack): StackItem {
    check_underflow(s);
    return DefAtomSI;
  }
  public static function drop(s: Stack): StackItem {
    assert_stack_has(s, 1);
    return s.pop();
  }

  public static function dup(s: Stack): StackItem {
    s.dup();
    return Noop;
  }
  
  // I-
  public static function identity(s: Stack, interp: Interpreter): StackItem {
    check_underflow(s);
    var item: StackItem = s.pop();
    switch( item ) {
      case QuoteSI   (q) : interp.eval(q, Eager);
      case IntSI     (_) | FloatSI(_) | StringSI(_) : s.push(item);
      case ErrSI     (e) : throw error(e);

      case AtomSI    (s) : throw error('How did atom ${s} get here? 0.o');
      case DefAtomSI     : throw error('How did defatom get here? 0.o');
      case BuiltinSI (_) : throw error('How did builting get here? 0.o');
      case Noop          : // do nothing
      case PartQuoteSI(_): // should not meet at all
    } // switch
    return Noop;
  }

  // M-
  public static function math_random(s: Stack): StackItem {
    check_underflow(s);
    var item = s.pop();
    s.push( IntSI( Std.random( unwrap_int(item) )));
    return Noop;
  }

  public static function math_rnd(s: Stack): StackItem {
    s.push( FloatSI( Math.random() ) );
    return Noop;
  }

  public static function multiply(s: Stack): StackItem {
    assert_stack_has(s, 2);
    var r = math_multiply(s);
    switch( r ) {
      case Noop : return Noop;
      case _    :
        s.push(r);
    }
    return Noop;
  }

  // N-
  public static function negate(s: Stack): StackItem {
    check_underflow(s);
    var item = s.pop();
    switch( item ) {
      case IntSI(i)   : s.push( IntSI( -i ) );
      case FloatSI(f) : s.push( FloatSI( -f ) );
      case _          : throw KonekoException.IncompatibleTypes;
    }
    return Noop;
  }

  // O-
  public static function over(s: Stack): StackItem {
    assert_stack_has(s, 2);
    s.push( s.nos() );
    return Noop;
  }

  // P-
  public static function pick(s: Stack): StackItem {
    check_underflow(s);
    var item = s.pop();
    var idx = switch( item ) {
      case IntSI(i) : i;
      case _        : throw KonekoException.Custom('Incompatible index type : ${item.type()}');
    }
    s.push( nth(s, idx).value );
    return Noop;
  }

  public static function pop_and_print(s: Stack): StackItem {
    check_underflow(s);
    out(s.pop().toString());
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
          case DefAtomSI    : '<DefAtom>';
          case QuoteSI(_)   : '<Quote>';
          case BuiltinSI(_) : '<Builtin>';
          case Noop         : '<Noop>';
          case _            : '<Unknown>';
        }
    );
    return Noop;
  }

  // Q-
  public static function quit(s: Stack): StackItem {
    Sys.exit(0);
    return Noop;
  }

  public static function quit_with(s: Stack): StackItem {
    var code = 0; // default
    try {
      check_underflow(s);
      var item = s.pop();
      code = switch( item ) {
        case IntSI(i) : i;
        case _        :
          throw KonekoException.Custom('Exit code must be !Int, got ${item.type()}');
          255;
      }
    } catch(e: Dynamic) {
      code = 255;
    }
    Sys.exit(code);
    return Noop;
  }

  // R-
  // -rot : 1 2 3 -> 3 1 2
  public static function rotate_1to3(s: Stack): StackItem {
    var tmp: StackCell = nth(s, 0); // save TOS
    var nos: StackCell = nth(s, 1);
    var trd: StackCell = nth(s, 2);
    s.head = nos;          // make NOS new TOS
    tmp.next = trd.next;   // make old TOS point to trd's next
    trd.next = tmp;        // make trd point to old TOS
    return Noop;
  }

  // rot : 1 2 3 -> 2 3 1
  public static function rotate_3to1(s: Stack): StackItem {
    var tos: StackCell = nth(s, 0); // save TOS
    var nos: StackCell = nth(s, 1);
    var trd: StackCell = nth(s, 2);
    s.head = trd;          // make TRD new TOS
    nos.next = trd.next;   // make NOS point to TRD's next
    trd.next = tos;        // make new TOS point to old TOS
    return Noop;
  }

  // S-
  public static function show_debug(s: Stack): StackItem {
    say(s.toString());
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
    sb.add("\n");
    out(sb.toString());
    return Noop;
  }

  public static function sleep(s: Stack): StackItem {
    check_underflow(s);
    switch( s.pop() ) {
      case IntSI(i) : Sys.sleep(i);
      case _        : throw KonekoException.IncompatibleTypes;
    }
    return Noop;
  }

  public static function subtract(s: Stack): StackItem {
    assert_stack_has(s, 2);
    var r = math_subtract(s);
    switch( r ) {
      case Noop : return Noop;
      case _    :
        s.push(r);
    }
    return Noop;
  }

  public static function swap(s: Stack): StackItem {
    assert_stack_has(s, 2);
    s.swap();
    return Noop;
  }

  // T-
  public static function type(s: Stack): StackItem {
    check_underflow(s);
    var item = s.pop();
    s.push( StringSI( item.type() ) );
    return Noop;
  }




  //
  // private
  //
  static inline function out(v: Dynamic) {
    Sys.print(v);
  }

  static inline function say(v: Dynamic) {
    Sys.println(v);
  }

  static function check_underflow(s: Stack) {
    if( s.is_empty() )
      throw KonekoException.StackUnderflow;
  }

  static inline function error(s: String): KonekoException {
    return KonekoException.Custom(s);
  }

  static function assert_stack_has(s: Stack, n: Int) {
    if( n < 1 )
      throw KonekoException.WrongAssertionParam;
    if( s.length < n )
      throw KonekoException.StackUnderflow;
  }

  static inline function _3rd(s: Stack): StackCell {
    return s.head.next.next;
  }

  // 0-based
  static function nth(s: Stack, n: Int): StackCell {
    assert_stack_has(s, n+1);
    var cell = s.head;
    while( n-- > 0 ) {
      cell = cell.next;
    } 
    return cell;
  }


  static function math_add(s: Stack): StackItem {
    var tos = s.pop();
    var nos = s.pop();
    var tos_type = tos.type();
    var nos_type = nos.type();

    // Both Int
    if( tos_type == "!Int" && nos_type == "!Int" ) {
      var fst = unwrap_int( tos );
      var snd = unwrap_int( nos );
      return add_int_int(fst, snd);
    }

    // One or both are Float
    if( tos_type == "!Float" || nos_type == "!Float" ) {
      var fst = unwrap_float( tos );
      var snd = unwrap_float( nos );
      return add_float_float(fst, snd);
    }

    // Both strings
    if( tos_type == "!String" && nos_type == "!String" ) {
      var fst = unwrap_string( tos );
      var snd = unwrap_string( nos );
      return add_strings(snd, fst); // it's more logical concat NOS + TOS
                                    // as they are added this way
    }

    throw KonekoException.IncompatibleTypes;
    return Noop; // should be unreachable
  }

  static function math_subtract(s: Stack): StackItem {
    var tos = s.pop();
    var nos = s.pop();

    // Both Int
    if( tos.type() == "!Int" && nos.type() == "!Int" ) {
      var fst = unwrap_int( tos );
      var snd = unwrap_int( nos );
      return subtract_int_int(snd, fst); // TOS from NOS
    }

    // Try to get floats
    var fst = unwrap_float( tos );
    var snd = unwrap_float( nos );
    return subtract_float_float(snd, fst); // TOS from NOS

    return Noop; // should be unreachable
  }

  static function math_multiply(s: Stack): StackItem {
    var tos = s.pop();
    var nos = s.pop();

    // Both Int
    if( tos.type() == "!Int" && nos.type() == "!Int" ) {
      var fst = unwrap_int( tos );
      var snd = unwrap_int( nos );
      return multiply_int_int(snd, fst);
    }

    // Try to get floats
    var fst = unwrap_float( tos );
    var snd = unwrap_float( nos );
    return multiply_float_float(snd, fst);

    return Noop; // should be unreachable
  }

  // add
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
  // sub
  static function subtract_int_int(i: Int, j: Int): StackItem {
    return IntSI(i-j);
  }

  static function subtract_float_float(f: Float, g: Float): StackItem {
    return FloatSI(f-g);
  }

  // mult
  static function multiply_int_int(i: Int, j: Int): StackItem {
    return IntSI(i*j);
  }

  static function multiply_float_float(f: Float, g: Float): StackItem {
    return FloatSI(f*g);
  }

  // div mod



  static inline function consume(s: Stack, n: Int) {
    for( i in 0 ... n )
      s.pop();
  }

  static inline function unwrap_int(si: StackItem): Int {
    return switch( si ) {
      case IntSI(i): i;
      case _ : throw KonekoException.IncompatibleTypes;
    }
  }

  static inline function unwrap_float(si: StackItem): Float {
    return switch( si ) {
      case IntSI(i)  : cast(i, Float);
      case FloatSI(f): f;
      case _ : throw KonekoException.IncompatibleTypes;
    }
  }

  static inline function unwrap_string(si: StackItem): String {
    return switch( si ) {
      case StringSI(s): s;
      case _ : throw KonekoException.IncompatibleTypes;
    }
  }

  /**
    Converts functions of type `Stack -> Vocabulary -> StackItem`
    to `Stack -> StackItem`
   **/
  public static function with_voc(voc: Vocabulary, func: Stack -> Vocabulary -> StackItem) {
    return function(s: Stack): StackItem {
      return func(s, voc);
    }
  }

  public static function with_interp(interp: Interpreter, func: Stack -> Interpreter  -> StackItem) {
    return function(s: Stack): StackItem {
      return func(s, interp);
    }
  }
}
