package koneko;

import haxe.macro.Expr;

using  StringTools;
using  koneko.StackItem; // for .type and .toString

enum CompareOp { EQ; NQ; GT; LT; GE; LE; }
enum LogicalOp { NOT; AND; OR; XOR; }

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

  public static function args_from_cli(s: Stack): StackItem {
    var args = Sys.args();
    var q = new Array<StackItem>();
    for (a in args)
      q.push( StringSI(a) );
    s.push( QuoteSI(q) );
    return Noop;
  }

  public static function assert_true(s: Stack): StackItem {
    assert_stack_has(s, 1);
    var cond = unwrap_bool( s.pop() );
    if( !cond  )
      return BreakSI;
    return Noop;
  }

  public static function assert_true_msg(s: Stack): StackItem {
    assert_stack_has(s, 2);
    var item = s.pop();
    var b    = s.pop();
    var msg  = unwrap_string(item);
    var cond = unwrap_bool(b);
    if( !cond ) {
      out("Failed: ");
      say(msg);
      return BreakSI;
    }
    return Noop;
  }

  // B-
  public static function break_loop(s: Stack): StackItem {
    return BreakSI; // ??
  }

  // C-
  public static function careful_define(s: Stack): StackItem {
    check_underflow(s);
    return MaybeDefSI;
  }

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
      case BreakSI       : s.push(item); // or throw?

      case AtomSI    (s) : throw error('How did atom ${s} get here? 0.o');
      case DefAtomSI     : throw error('How did defatom get here? 0.o');
      case MaybeDefSI    : throw error('How did maybedef get here? 0.o');
      case BuiltinSI (_) : throw error('How did builting get here? 0.o');
      case Noop          : // do nothing
      case PartQuoteSI(_): // should not meet at all
    } // switch
    return Noop;
  }

  public static function if_conditional(s: Stack, interp: Interpreter): StackItem {
    assert_stack_has(s, 3);
    var else_br = s.pop();
    var then_br = s.pop();
    var cond = s.pop();
    assert_is(else_br, "!Quote");
    assert_is(then_br, "!Quote");
    interp.eval_item(cond, Eager);
    var r = s.pop(); // supposedly from evaluation of `cond`
    switch( r ) {
      case IntSI(i) :
        if( i == 0 ) interp.eval_item(else_br, Eager) else interp.eval_item(then_br, Eager);
      case _        :
        throw error('Condition for IF should leave !Int value on the stack. Found ${r.type()}');
    }
    return Noop;
  }

  // M-
  public static function math_compare(op: CompareOp): Stack->StackItem {
    return function(s: Stack): StackItem {
      var right = s.pop();
      var left  = s.pop();
      var r_type = right.type();
      var l_type = left.type();
      var r = false;

      // Both Strings
      if( l_type == "!String" && r_type == "!String" ) {
        r = do_compare(unwrap_string(left), unwrap_string(right), op);
      }

      // Both Ints
      else if( l_type == "!Int" && r_type == "!Int" ) {
        r = do_compare(unwrap_int(left), unwrap_int(right), op);
      }

      // Each must be either Int or Float
      else {
        r = do_compare(unwrap_float(left), unwrap_float(right), op);
      }
      if( r == true )
        s.push( IntSI(1) );
      else
        s.push( IntSI(0) );

      return Noop;
      }
  }

  public static function math_division(s: Stack): StackItem {
    assert_stack_has(s, 2);
    var tos = s.pop();
    var nos = s.pop();
    var dsor = unwrap_float(tos);
    var dend = unwrap_float(nos);
    if( dsor == 0 )
      throw KonekoException.DivisionByZero;
    s.push( FloatSI( dend / dsor ) );
    return Noop;
  }

  public static function math_int_division(s: Stack): StackItem {
    assert_stack_has(s, 2);
    var tos = s.pop();
    var nos = s.pop();
    var dsor = unwrap_float(tos);
    var dend = unwrap_float(nos);
    if( dsor == 0 )
      throw KonekoException.DivisionByZero;
    s.push( IntSI( Math.floor(dend / dsor) ) );
    return Noop;
  }

  public static function math_logical(op: LogicalOp): Stack->StackItem {
    return function(s: Stack): StackItem {
      switch( op ) {
        case NOT :
          assert_stack_has(s, 1);
          var boolv = unwrap_bool(s.pop());
          s.push( do_logical_op(boolv, false, NOT) );
        case _   :
          assert_stack_has(s, 2);
          var tos = s.pop();
          var nos = s.pop();
          var left = unwrap_bool(nos);
          var right = unwrap_bool(tos);
          s.push( do_logical_op(left, right, op) );
      } // switch
      return Noop;
    }
  }
  public static function math_modulo(s: Stack): StackItem {
    assert_stack_has(s, 2);
    var tos = s.pop();
    var nos = s.pop();
    if( tos.type() == "!Int" && nos.type() == "!Int" ) {
      var dend = unwrap_int(nos);
      var dsor = unwrap_int(tos);
      if( dsor == 0 )
        throw KonekoException.DivisionByZero;
      s.push( IntSI( dend % dsor ) );
    } else {
      var dend = unwrap_float(nos);
      var dsor = unwrap_float(tos);
      if( dsor == 0 )
        throw KonekoException.DivisionByZero;
      s.push( FloatSI( dend % dsor ) );
    }
    return Noop;
  }

  public static function math_negate(s: Stack): StackItem {
    check_underflow(s);
    var item = s.pop();
    switch( item ) {
      case IntSI(i)   : s.push( IntSI( -i ) );
      case FloatSI(f) : s.push( FloatSI( -f ) );
      case _          : throw KonekoException.IncompatibleTypes;
    }
    return Noop;
  }

  public static function math_random(s: Stack): StackItem {
    check_underflow(s);
    var item = s.pop();
    s.push( IntSI( Std.random( unwrap_int(item) )));
    return Noop;
  }

  public static function math_rounding(func: Float->Int): Stack->StackItem {
    return function(s: Stack): StackItem {
      check_underflow(s);
      var n = s.pop();
      s.push( switch( n ) {
        case IntSI(i)   : n;
        case FloatSI(f) : IntSI(func(f));
        case _          : throw error("!Int or !Float expected");
      });
      return Noop;
    }
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
      case _        : throw error('Incompatible index type : ${item.type()}');
    }
    s.push( nth(s, idx).value );
    return Noop;
  }

  public static function pop_and_print(s: Stack): StackItem {
    check_underflow(s);
    out(s.pop().toString());
    return Noop;
  }

  public static function pop_from_quote(s: Stack): StackItem {
    assert_stack_has(s, 1);
    var q = unwrap_quote( s.pop() );
    if( q.length < 1 )
      throw error("Cannot get last element from empty quote");
    var v = q.pop();
    s.push( QuoteSI(q) );
    s.push( v );
    // result on stack: [Q w/o last element] <last element of Q>
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
          case MaybeDefSI   : '<MaybeDef>';
          case QuoteSI(_)   : '<Quote>';
          case BuiltinSI(_) : '<Builtin>';
          case Noop         : '<Noop>';
          case ErrSI(s)     : 'ERROR: $s';
          case _            : '<Unknown>';
        }
    );
    return Noop;
  }

  public static function push_to_quote(s: Stack): StackItem {
    // [Q] V q<
    assert_stack_has(s, 2);
    var v = s.pop();
    var q = unwrap_quote( s.pop() );
    q.push(v);
    s.push(QuoteSI(q));
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
          throw error('Exit code must be !Int, got ${item.type()}');
          255;
      }
    } catch(e: Dynamic) {
      code = 255;
    }
    Sys.exit(code);
    return Noop;
  }

  public static function quote_values(s: Stack): StackItem {
    var item = s.pop();
    assert_is(item, "!Int");
    var n = unwrap_int(item);
    assert_stack_has(s, n);
    var a = new Array<StackItem>();
    for( i in 0 ... n )
      a.unshift(s.pop());
    s.push(QuoteSI(a));
    return Noop;
  }

  // R-
  public static function read_line_stdin(s: Stack): StackItem {
    try {
      var line = Sys.stdin().readLine();
      s.push( StringSI( line ) );
    }
    catch(e: Dynamic)
      s.push( ErrSI("EOF") );
    return Noop;
  }

  public static function reverse_quote(s: Stack): StackItem {
    assert_stack_has(s, 1);
    var q = unwrap_quote( s.pop() );
    q.reverse();
    s.push( QuoteSI(q) );
    return Noop;
  }

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
  public static function shift_from_quote(s: Stack): StackItem {
    assert_stack_has(s, 1);
    var q = unwrap_quote( s.pop() );
    if( q.length < 1 )
      throw error("Cannot get first element from empty quote");
    var v = q.shift();
    s.push( QuoteSI(q) );
    s.push( v );
    // result on stack: [Q w/o 1st element] <1st element of Q>
    return Noop;
  }

  public static function show_debug(s: Stack): StackItem {
    say(s.toString());
    return Noop;
  }

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

  public static function stack_length(s: Stack): StackItem {
    s.push( IntSI( s.length ) );
    return Noop;
  }

  public static function string_at(s: Stack): StackItem {
    var item = s.pop();
    var str = unwrap_string( s.pop() );
    var n = unwrap_int(item);
    try {
      s.push(
          StringSI(
            chars_to_utf8_string(
              [haxe.Utf8.charCodeAt(str, n)] )));
    }
    catch(e: Dynamic)
      throw error("Index out of bounds");
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
  public static function temp_stack_length(s: Stack): StackItem {
    s.push( IntSI( s.tmp.length ) );
    return Noop;
  }

  public static function temp_stack_pop(s: Stack): StackItem {
    assert_stack_has(s.tmp, 1);
    s.push( s.tmp.pop() );
    return Noop;
  }
  public static function temp_stack_push(s: Stack): StackItem {
    assert_stack_has(s, 1);
    s.tmp.push( s.pop() );
    return Noop;
  }
  public static function temp_stack_show(s: Stack): StackItem {
    show_stack(s.tmp);
    return Noop;
  }

  public static function times_loop(s: Stack, interp: Interpreter): StackItem {
    assert_stack_has(s, 2);
    var n = s.pop();
    var body = s.pop();
    assert_is(n, "!Int");
    assert_is(body, "!Quote");
    for( i in 0 ... unwrap_int(n) ) {
      // var eval_r = interp.eval_item(body, Eager);
      var eval_r = interp.eval(unwrap_quote(body), Eager);
      if( eval_r == Break ) break;
    }
    return Noop;
  }

  public static function type(s: Stack): StackItem {
    check_underflow(s);
    var item = s.pop();
    s.push( StringSI( item.type() ) );
    return Noop;
  }

  // U-
  public static function unquote_to_values(s: Stack): StackItem {
    assert_stack_has(s, 1);
    var q = unwrap_quote( s.pop() );
    for( i in q )
      s.push( i );
    return Noop;
  }

  public static function unshift_to_quote(s: Stack): StackItem {
    // V [Q] >q
    assert_stack_has(s, 2);
    var qt = s.pop(); // need to pop into variable here
    var v = s.pop();
    var q = unwrap_quote(qt);
    q.unshift(v);
    s.push(QuoteSI(q));
    return Noop;
  }

  // W-
  public static function when_conditional(s: Stack, interp: Interpreter): StackItem {
    assert_stack_has(s, 2);
    var then_br = s.pop();
    var cond = s.pop();
    assert_is(then_br, "!Quote");
    interp.eval_item(cond, Eager);
    var r = s.pop(); // supposedly from evaluation of `cond`
    switch( r ) {
      case IntSI(i) :
        if( i != 0 ) interp.eval_item(then_br, Eager);
      case _        :
        throw error('Condition for WHEN should leave !Int value on the stack. Found ${r.type()}');
    }
    return Noop;
  }

  public static function while_loop(s: Stack, interp: Interpreter): StackItem {
    assert_stack_has(s, 1);
    var body = s.pop();
    assert_is(body, "!Quote");
    do {
      var eval_r = interp.eval_item(body, Eager);
      if( eval_r == Break ) break;
      var r = s.pop();
      switch( r ) {
        case IntSI(i) : if( i == 0 ) break;
        case _        : throw error(
           'Condition for WHILE should leave !Int value on the stack. Found ${r.type()}');
      }
    } while(true);
    return Noop;
  }

  public static function words_list(s: Stack, voc: Vocabulary): StackItem {
    var words = new Array<String>();
    for (i in voc.keys()) {
      words.push(i);
    }
    words.sort(function(s1: String, s2: String): Int {
      if( s1 == s2 ) return 0;
      else if( s1 > s2 ) return 1;
      else return -1;
    });
    say(words.join(" "));
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
    if( n < 0 )
      throw KonekoException.WrongAssertionParam;
    if( s.length < n )
      throw KonekoException.StackUnderflow;
  }

  static inline function assert_is(si: StackItem, type: String) {
    if( si.type() != type )
      throw KonekoException.AssertFailureWrongType(si.type(), type);
  }

  static inline function assert_is_number(si: StackItem) {
    if( si.type() != "!Int" && si.type() != "!Float" )
      throw error('Expected number, but found ${si.type()}');
  }

  static inline function assert_one_of(si: StackItem, types: Array<String>) {
    var type = si.type();
    for( t in types )
      if( t == type ) return;
    throw KonekoException.AssertFailureWrongType(si.type(), types.join(" | "));
  }

  static function assert_valid_utf8(s: String) {
    if( !haxe.Utf8.validate(s) )
      throw error("Not a valid UTF-8 string");
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
      case _ : throw error('Expected !Int, but found ${si.type()}');
    }
  }

  static inline function unwrap_float(si: StackItem): Float {
    return switch( si ) {
      case IntSI(i)  : cast(i, Float);
      case FloatSI(f): f;
      case _ : throw error('Expected either !Int or !Float, but found ${si.type()}');
    }
  }

  static inline function unwrap_bool(si: StackItem): Bool {
    var r = switch( si ) {
      case IntSI(i)  : cast(i, Float);
      case FloatSI(f): f;
      case _ : throw error('Expected either !Int or !Float as boolean, but found ${si.type()}');
    }
    return r != 0; // false for 0, true for everything else
  }

  static inline function unwrap_string(si: StackItem): String {
    return switch( si ) {
      case StringSI(s): s;
      case _ : throw error('Expected !String, but found ${si.type()}');
    }
  }

  static inline function unwrap_quote(si: StackItem): Array<StackItem> {
    return switch( si ) {
      case QuoteSI(q) : q;
      case _          : throw error('Expected !Quote, but found ${si.type()}');
    }
  }

  macro static function do_compare(a: Expr, b: Expr, op: Expr): Expr {
    return macro switch( $op ) {
      case EQ  : $a == $b;
      case NQ  : $a != $b;
      case GT  : $a > $b;
      case LT  : $a < $b;
      case GE  : $a >= $b;
      case LE  : $a <= $b;
    }
  }

  static function do_logical_op(a: Bool, b: Bool, op: LogicalOp): StackItem {
    var r = switch( op ) {
      case AND: a && b;
      case OR : a || b;
      case XOR: a != b;
      case NOT: !a;
    }
    return IntSI( r == true ? -1 : 0 );
  }

  static function chars_to_utf8_string(chars: Array<Int>): String {
    // TODO
    var u = new haxe.Utf8();
    for ( i in chars )
      u.addChar(i);
    return u.toString();
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
