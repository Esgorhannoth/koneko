package koneko;

import haxe.macro.Expr;
import koneko.Helpers as H;

using  StringTools;
using  koneko.StackItem; // for .type and .toString

enum CompareOp { EQ; NQ; GT; LT; GE; LE; }
enum LogicalOp { NOT; AND; OR; XOR; }
enum SubstrVariant { SUB; SUBSTR; SUBRANGE; }

/**
  All functions return either a valuable StackItem or Noop;
  If a function is not to return anything (side-effect only, like `dup`) it must return Noop;
  Otherwise the value returned can be used elsewhere;
 **/
class Builtins {

  // A-
  public static function add(s: Stack): StackItem {
    H.assert_stack_has(s, 2);
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
    H.assert_has_one(s);
    var cond = H.unwrap_bool( s.pop() );
    if( !cond  )
      return BreakSI;
    return Noop;
  }

  public static function assert_true_msg(s: Stack): StackItem {
    H.assert_stack_has(s, 2);
    var item = s.pop();
    var b    = s.pop();
    var msg  = H.unwrap_string(item);
    var cond = H.unwrap_bool(b);
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
    H.assert_has_one(s);
    return MaybeDefSI;
  }

  public static function clear_stack(s: Stack): StackItem {
    s.clear();
    return Noop;
  }

  public static function concat_quotes(s: Stack): StackItem {
    H.assert_stack_has(s, 2);
    var item = s.pop();
    var first = H.unwrap_quote( s.pop() );
    var second = H.unwrap_quote( item );
    s.push( QuoteSI( first.concat(second) ) );
    return Noop;
  }

  // D-
  public static function define(s: Stack): StackItem {
    H.assert_has_one(s);
    return DefAtomSI;
  }

  public static function define_check_word(s: Stack, voc: Vocabulary): StackItem {
    H.assert_has_one(s);
    var q = H.unwrap_quote( s.pop() );
    if( q.length <=0 )
      throw H.error("No word to check in quote");
    if( q.length > 1 )
      throw H.error("Cannot check more then 1 word");
    var atom = q.shift();
    H.assert_is(atom, "!Atom");
    var key = H.unwrap_atom(atom);
    if( voc.exists(key) )
      s.push( IntSI( -1 ) ); //true
    else
      s.push( IntSI( 0 ) ); // false
    return Noop;
  }

  public static function define_see_source(s: Stack, voc: Vocabulary): StackItem {
    H.assert_has_one(s);
    var q = H.unwrap_quote( s.pop() );
    for( i in q ) {
      var a = H.unwrap_atom(i);
      say('${a}: ${voc.get_definition(a)}');
    }
    return Noop;
  }

  public static function define_undefine(s: Stack, voc: Vocabulary): StackItem {
    H.assert_has_one(s);
    var q = H.unwrap_quote( s.pop() );
    try {
      for( a in q )
        H.assert_is(a, "!Atom");
    }
    catch(e: Dynamic) {
      throw H.error("Non-atom in undef list");
    }
    for( a in q ) {
      voc.remove( H.unwrap_atom(a) );
    }
    return Noop;
  }

  public static function drop(s: Stack): StackItem {
    H.assert_has_one(s);
    return s.pop();
  }

  public static function dup(s: Stack): StackItem {
    s.dup();
    return Noop;
  }
  
  // I-
  public static function identity(s: Stack, interp: Interpreter): StackItem {
    H.assert_has_one(s);
    var item: StackItem = s.pop();
    switch( item ) {
      case QuoteSI   (q) : interp.eval(q, Eager);
      case IntSI     (_) | FloatSI(_) | StringSI(_) : s.push(item);
      case ErrSI     (e) : throw H.error(e);
      case BreakSI       : s.push(item); // or throw?

      case AtomSI    (s) : interp.eval_item(item);
      // case AtomSI    (s) : throw H.error('How did atom ${s} get here? 0.o');
      case DefAtomSI     : throw H.error('How did defatom get here? 0.o');
      case MaybeDefSI    : throw H.error('How did maybedef get here? 0.o');
      case BuiltinSI (_) : throw H.error('How did builtin get here? 0.o');
      case Noop          : // do nothing
      case PartQuoteSI(_): // should not meet at all
    } // switch
    return Noop;
  }

  public static function if_conditional(s: Stack, interp: Interpreter): StackItem {
    H.assert_stack_has(s, 3);
    var else_br = s.pop();
    var then_br = s.pop();
    var cond = s.pop();
    H.assert_is(else_br, "!Quote");
    H.assert_is(then_br, "!Quote");
    interp.eval_item(cond, Eager);
    var r = s.pop(); // supposedly from evaluation of `cond`
    switch( r ) {
      case IntSI(i) :
        if( i == 0 ) interp.eval_item(else_br, Eager) else interp.eval_item(then_br, Eager);
      case _        :
        throw H.error('Condition for IF should leave !Int value on the stack. Found ${r.type()}');
    }
    return Noop;
  }

  public static function import_file(s: Stack, interp: Interpreter): StackItem {
    H.assert_has_one(s);
    var item = s.pop();
    if( "!String" == item.type() ) {
      var fn = H.unwrap_string(item);
      H.load_file(fn, interp);
    }
    else {
      var q = H.unwrap_quote(item);
      for( i in q ) {
        try {
          var fn = H.unwrap_string(i);
          H.load_file(fn, interp);
        }
        catch(e: Dynamic) {
          say(e);
          continue;
        }
      }
    }
    return Noop;
  }

  // L-
  public static function load_module(s: Stack, voc: Vocabulary): StackItem {
    H.assert_has_one(s);
    var fname = H.unwrap_string( s.pop() );
    voc = ModLoader.add_to(voc, fname);
    return Noop;
  };

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
        r = do_compare(H.unwrap_string(left), H.unwrap_string(right), op);
      }

      // Both Ints
      else if( l_type == "!Int" && r_type == "!Int" ) {
        r = do_compare(H.unwrap_int(left), H.unwrap_int(right), op);
      }

      // Each must be either Int or Float
      else {
        r = do_compare(H.unwrap_float(left), H.unwrap_float(right), op);
      }
      if( r == true )
        s.push( IntSI(1) );
      else
        s.push( IntSI(0) );

      return Noop;
      }
  }

  public static function math_division(s: Stack): StackItem {
    H.assert_stack_has(s, 2);
    var tos = s.pop();
    var nos = s.pop();
    var dsor = H.unwrap_float(tos);
    var dend = H.unwrap_float(nos);
    if( dsor == 0 )
      throw KonekoException.DivisionByZero;
    s.push( FloatSI( dend / dsor ) );
    return Noop;
  }

  public static function math_int_division(s: Stack): StackItem {
    H.assert_stack_has(s, 2);
    var tos = s.pop();
    var nos = s.pop();
    var dsor = H.unwrap_float(tos);
    var dend = H.unwrap_float(nos);
    if( dsor == 0 )
      throw KonekoException.DivisionByZero;
    s.push( IntSI( Math.floor(dend / dsor) ) );
    return Noop;
  }

  public static function math_logical(op: LogicalOp): Stack->StackItem {
    return function(s: Stack): StackItem {
      switch( op ) {
        case NOT :
          H.assert_has_one(s);
          var boolv = H.unwrap_bool(s.pop());
          s.push( do_logical_op(boolv, false, NOT) );
        case _   :
          H.assert_stack_has(s, 2);
          var tos = s.pop();
          var nos = s.pop();
          var left = H.unwrap_bool(nos);
          var right = H.unwrap_bool(tos);
          s.push( do_logical_op(left, right, op) );
      } // switch
      return Noop;
    }
  }
  public static function math_modulo(s: Stack): StackItem {
    H.assert_stack_has(s, 2);
    var tos = s.pop();
    var nos = s.pop();
    if( tos.type() == "!Int" && nos.type() == "!Int" ) {
      var dend = H.unwrap_int(nos);
      var dsor = H.unwrap_int(tos);
      if( dsor == 0 )
        throw KonekoException.DivisionByZero;
      s.push( IntSI( dend % dsor ) );
    } else {
      var dend = H.unwrap_float(nos);
      var dsor = H.unwrap_float(tos);
      if( dsor == 0 )
        throw KonekoException.DivisionByZero;
      s.push( FloatSI( dend % dsor ) );
    }
    return Noop;
  }

  public static function math_negate(s: Stack): StackItem {
    H.assert_has_one(s);
    var item = s.pop();
    switch( item ) {
      case IntSI(i)   : s.push( IntSI( -i ) );
      case FloatSI(f) : s.push( FloatSI( -f ) );
      case _          : throw KonekoException.IncompatibleTypes;
    }
    return Noop;
  }

  public static function math_random(s: Stack): StackItem {
    H.assert_has_one(s);
    var item = s.pop();
    s.push( IntSI( Std.random( H.unwrap_int(item) )));
    return Noop;
  }

  public static function math_rounding(func: Float->Int): Stack->StackItem {
    return function(s: Stack): StackItem {
      H.assert_has_one(s);
      var n = s.pop();
      s.push( switch( n ) {
        case IntSI(i)   : n;
        case FloatSI(f) : IntSI(func(f));
        case _          : throw H.error("!Int or !Float expected");
      });
      return Noop;
    }
  }

  public static function math_rnd(s: Stack): StackItem {
    s.push( FloatSI( Math.random() ) );
    return Noop;
  }

  public static function multiply(s: Stack): StackItem {
    H.assert_stack_has(s, 2);
    var r = math_multiply(s);
    switch( r ) {
      case Noop : return Noop;
      case _    :
        s.push(r);
    }
    return Noop;
  }

  // N-
  public static function namespace_active_nss(s: Stack, voc: Vocabulary): StackItem {
    var nss = voc.using_list;
    var sb = new StringBuf();
    sb.add("< using:");
    for( i in nss )
      sb.add('  $i');
    sb.add("  ");
    sb.add(voc.current_ns);
    sb.add(" >");
    say(sb.toString());
    return Noop;
  }

  // TODO with `using`
  public static function namespace_cur_words(s: Stack, voc: Vocabulary): StackItem {
    s.push( StringSI( voc.current_ns ) );
    return namespace_words_list(s, voc);
  }

  public static function namespace_check_defined(s: Stack, voc: Vocabulary): StackItem {
    H.assert_has_one(s);
    var ns = H.unwrap_string( s.pop() );
    for( k in voc.keys() )
      if( k.startsWith(ns) ) {
        s.push( IntSI( -1 ) ); // true
        return Noop;
      }
    // false
    s.push( IntSI( 0 ) );
    return Noop;
  }

  public static function namespace_get(s: Stack, voc: Vocabulary): StackItem {
    s.push( StringSI( voc.current_ns ) );
    return Noop;
  }

  public static function namespace_set(s: Stack, voc: Vocabulary): StackItem {
    H.assert_has_one(s);
    var ns = H.unwrap_string( s.pop() );
    voc.current_ns = ns;
    return Noop;
  }

  public static function namespace_using(s: Stack, voc: Vocabulary): StackItem {
    H.assert_has_one(s);
    var item = s.pop();
    var nss = new Array<String>();
    switch( item ) {
      case StringSI(s)   : nss.push(s);
      case QuoteSI(q)    :
        for( i in q )
          nss.push( H.unwrap_string(i) );
      case _             :
      throw H.error('!String or !Quote of "!String"s expected for setting active namespaces, but ${item.type()} found');

    }
    voc.using_list = nss;
    return Noop;
  }

  public static function namespace_words_list(s: Stack, voc: Vocabulary): StackItem {
    H.assert_has_one(s);
    var ns = H.unwrap_string( s.pop() );
    var ns_len = ns.length + 1; // eat ":"

    var words = new Array<String>();
    for (i in voc.keys()) {
      if( i.startsWith(ns) )
      words.push(i.substr(ns_len));
    }
    words.sort(function(s1: String, s2: String): Int {
      if( s1 == s2 ) return 0;
      else if( s1 > s2 ) return 1;
      else return -1;
    });
    out('<ns:${ns}>   ');
    say(words.join("  "));
    return Noop;
  }

  // O-
  public static function over(s: Stack): StackItem {
    H.assert_stack_has(s, 2);
    s.push( s.nos() );
    return Noop;
  }

  // P-
  public static function pick(s: Stack): StackItem {
    H.assert_has_one(s);
    var item = s.pop();
    var idx = switch( item ) {
      case IntSI(i) : i;
      case _        : throw H.error('Incompatible index type : ${item.type()}');
    }
    s.push( H.nth(s, idx).value );
    return Noop;
  }

  public static function pop_and_print(s: Stack): StackItem {
    H.assert_has_one(s);
    out(s.pop().toString());
    out(" ");
    return Noop;
  }

  public static function pop_from_quote(s: Stack): StackItem {
    H.assert_has_one(s);
    var q = H.unwrap_quote( s.pop() );
    if( q.length < 1 )
      throw H.error("Cannot get last element from empty quote");
    var v = q.pop();
    s.push( QuoteSI(q) );
    s.push( v );
    // result on stack: [Q w/o last element] <last element of Q>
    return Noop;
  }

  public static function print(s: Stack): StackItem {
    H.assert_has_one(s);
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
    H.assert_stack_has(s, 2);
    var v = s.pop();
    var q = H.unwrap_quote( s.pop() );
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
      H.assert_has_one(s);
      var item = s.pop();
      code = switch( item ) {
        case IntSI(i) : i;
        case _        :
          throw H.error('Exit code must be !Int, got ${item.type()}');
          255;
      }
    } catch(e: Dynamic) {
      code = 255;
    }
    Sys.exit(code);
    return Noop;
  }

  public static function quote_length(s: Stack): StackItem {
    H.assert_has_one(s);
    var q = H.unwrap_quote( s.pop() );
    s.push( IntSI( q.length ) );
    return Noop;
  }

  public static function quote_values(s: Stack): StackItem {
    H.assert_has_one(s);
    var n = H.unwrap_int( s.pop() );
    H.assert_stack_has(s, n);
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
    H.assert_has_one(s);
    var q = H.unwrap_quote( s.pop() );
    q.reverse();
    s.push( QuoteSI(q) );
    return Noop;
  }

  // -rot : 1 2 3 -> 3 1 2
  public static function rotate_1to3(s: Stack): StackItem {
    var tmp: StackCell = H.nth(s, 0); // save TOS
    var nos: StackCell = H.nth(s, 1);
    var trd: StackCell = H.nth(s, 2);
    s.head = nos;          // make NOS new TOS
    tmp.next = trd.next;   // make old TOS point to trd's next
    trd.next = tmp;        // make trd point to old TOS
    return Noop;
  }

  // rot : 1 2 3 -> 2 3 1
  public static function rotate_3to1(s: Stack): StackItem {
    var tos: StackCell = H.nth(s, 0); // save TOS
    var nos: StackCell = H.nth(s, 1);
    var trd: StackCell = H.nth(s, 2);
    s.head = trd;          // make TRD new TOS
    nos.next = trd.next;   // make NOS point to TRD's next
    trd.next = tos;        // make new TOS point to old TOS
    return Noop;
  }

  // S-
  public static function shift_from_quote(s: Stack): StackItem {
    H.assert_has_one(s);
    var q = H.unwrap_quote( s.pop() );
    if( q.length < 1 )
      throw H.error("Cannot get first element from empty quote");
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
    H.assert_has_one(s);
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
    var str = H.unwrap_string( s.pop() );
    var n = H.unwrap_int(item);
    try {
      s.push(
          StringSI(
            H.chars_to_utf8_string(
              [haxe.Utf8.charCodeAt(str, n)] )));
    }
    catch(e: Dynamic)
      throw H.error("Index out of bounds");
    return Noop;
  }

  public static function string_atc(s: Stack): StackItem {
    var item = s.pop();
    var str = H.unwrap_string( s.pop() );
    var n = H.unwrap_int(item);
    try {
      s.push(
          IntSI(
              haxe.Utf8.charCodeAt(str, n) ));
    }
    catch(e: Dynamic)
      throw H.error("Index out of bounds");
    return Noop;
  }

  public static function string_backwards(s: Stack): StackItem {
    H.assert_has_one(s);
    var str = H.unwrap_string( s.pop() );
    var cps = H.utf8_to_chars(str);
    cps.reverse();
    s.push( StringSI( H.chars_to_utf8_string(cps) ) );
    return Noop;
  }

  public static function string_case_lower(s: Stack): StackItem {
    H.assert_has_one(s);
    var str = H.unwrap_string( s.pop() );
    var cps = H.utf8_to_chars( str );
    var lc = cps.map(function(c: Int): Int {
      return switch( c ) {
        case 1025: 1105; // ё -> Ё
        case i if( H.valid_for_lowercase(c) ) : i + 32;
        case _: c;
      }
    });
    s.push( StringSI( H.chars_to_utf8_string(lc)));
    return Noop;
  }

  public static function string_case_upper(s: Stack): StackItem {
    H.assert_has_one(s);
    var str = H.unwrap_string( s.pop() );
    var cps = H.utf8_to_chars( str );
    var uc = cps.map(function(c: Int): Int {
      return switch( c ) {
        case 1105: 1025; // ё -> Ё
        case i if( H.valid_for_uppercase(c) ) : i - 32;
        case _: c;
      }
    });
    s.push( StringSI( H.chars_to_utf8_string(uc)));
    return Noop;
  }

  public static function string_char_to_string(s: Stack): StackItem {
    H.assert_has_one(s);
    var cp = H.unwrap_int( s.pop() );
    s.push( StringSI( H.char_to_utf8_string(cp) ) );
    return Noop;
  }

  public static function string_chars_to_string(s: Stack): StackItem {
    H.assert_has_one(s);
    var q = H.unwrap_quote( s.pop() );
    var cps = new Array<Int>();
    for( i in q ) {
      cps.push( H.unwrap_int(i) );
    }
    s.push( StringSI( H.chars_to_utf8_string(cps) ) );
    return Noop;
  }

  public static function string_emit(s: Stack): StackItem {
    string_char_to_string(s);
    print(s);
    return Noop;
  }

  public static function string_length(s: Stack): StackItem {
    H.assert_has_one(s);
    var str = H.unwrap_string( s.pop() );
    s.push( IntSI( haxe.Utf8.length(str)));
    return Noop;
  }

  public static function string_substring_common(sv: SubstrVariant): Stack->StackItem {
    return function(s: Stack): StackItem {
      var pos: Int;
      var len = 0;
      var str: String;
      var tos: StackItem;
      var nos: StackItem;
      var nchk = 3;  // number of stack items to check
      if( sv == SUB ) nchk = 2;

      H.assert_stack_has(s, nchk);
      tos = s.pop();
      if( nchk == 3 ) {
        nos = s.pop();
        pos = H.unwrap_int( nos );
        len = H.unwrap_int( tos );
      } else
        pos = H.unwrap_int( tos );
      var str = H.unwrap_string( s.pop() );
      var cps = H.utf8_to_chars(str);

      switch( sv ) {
        case SUB      :
          s.push( StringSI( H.chars_to_utf8_string( cps.slice(pos))));
        case SUBSTR   :
          // slice (pos, ?end);
          var end : Int;
          if( len < 0 ) len = 0; // if len is 0 - we'll return empty string
          // if pos >= 0 we should add len to get end index
          // if pos < 0 we should subtract len from pos to get end index
          if( pos >= 0 ) end = pos + len;
          else end = pos - len;
          // for slice pos(=start) always must be lesser then end
          if( pos > end ) {
            H.swap_vars(pos, end);
            // correct negative indices after swapping
            // by moving them right >>
            // we need to do this because original indices before swapping
            // were [-pos, -end)
            // After swapping they are [-end, -pos)
            // That's not what we need, we need (-end, -pos]
            // so we move them both right
            if( pos < 0 ) { pos++; end++; }
          }
          s.push( StringSI( H.chars_to_utf8_string( cps.slice(pos, end))));
        case SUBRANGE :
          // here len is actually end
          var end = len;
          if( pos < 0 ) pos = 0;
          if( end < 0 ) end = 0;
          if( pos > end )
            H.swap_vars(pos, end);
          s.push( StringSI(
                H.chars_to_utf8_string( cps.slice(pos, end))));
      }

      return Noop;
    }
  }

  public static function string_to_string(s: Stack): StackItem {
    H.assert_has_one(s);
    var item = s.pop();
    s.push( StringSI( item.toString() ) );
    return Noop;
  }

  public static function subtract(s: Stack): StackItem {
    H.assert_stack_has(s, 2);
    var r = math_subtract(s);
    switch( r ) {
      case Noop : return Noop;
      case _    :
        s.push(r);
    }
    return Noop;
  }

  public static function swap(s: Stack): StackItem {
    H.assert_stack_has(s, 2);
    s.swap();
    return Noop;
  }

  // T-
  public static function temp_stack_length(s: Stack): StackItem {
    s.push( IntSI( s.tmp.length ) );
    return Noop;
  }

  public static function temp_stack_pop(s: Stack): StackItem {
    H.assert_has_one(s.tmp);
    s.push( s.tmp.pop() );
    return Noop;
  }
  public static function temp_stack_push(s: Stack): StackItem {
    H.assert_has_one(s);
    s.tmp.push( s.pop() );
    return Noop;
  }
  public static function temp_stack_show(s: Stack): StackItem {
    show_stack(s.tmp);
    return Noop;
  }

  public static function times_loop(s: Stack, interp: Interpreter): StackItem {
    H.assert_stack_has(s, 2);
    var n = s.pop();
    var body = s.pop();
    H.assert_is(n, "!Int");
    H.assert_is(body, "!Quote");
    for( i in 0 ... H.unwrap_int(n) ) {
      // var eval_r = interp.eval_item(body, Eager);
      var eval_r = interp.eval(H.unwrap_quote(body), Eager);
      if( eval_r == Break ) break;
    }
    return Noop;
  }

  public static function type(s: Stack): StackItem {
    H.assert_has_one(s);
    var item = s.pop();
    s.push( StringSI( item.type() ) );
    return Noop;
  }

  // U-
  public static function unquote_to_values(s: Stack): StackItem {
    H.assert_has_one(s);
    var q = H.unwrap_quote( s.pop() );
    for( i in q )
      s.push( i );
    return Noop;
  }

  public static function unshift_to_quote(s: Stack): StackItem {
    // V [Q] >q
    H.assert_stack_has(s, 2);
    var qt = s.pop(); // need to pop into variable here
    var v = s.pop();
    var q = H.unwrap_quote(qt);
    q.unshift(v);
    s.push(QuoteSI(q));
    return Noop;
  }

  // W-
  public static function when_conditional(s: Stack, interp: Interpreter): StackItem {
    H.assert_stack_has(s, 2);
    var then_br = s.pop();
    var cond = s.pop();
    H.assert_is(then_br, "!Quote");
    interp.eval_item(cond, Eager);
    var r = s.pop(); // supposedly from evaluation of `cond`
    switch( r ) {
      case IntSI(i) :
        if( i != 0 ) interp.eval_item(then_br, Eager);
      case _        :
        throw H.error('Condition for WHEN should leave !Int value on the stack. Found ${r.type()}');
    }
    return Noop;
  }

  public static function while_loop(s: Stack, interp: Interpreter): StackItem {
    H.assert_has_one(s);
    var body = s.pop();
    H.assert_is(body, "!Quote");
    do {
      var eval_r = interp.eval_item(body, Eager);
      if( eval_r == Break ) break;
      var r = s.pop();
      switch( r ) {
        case IntSI(i) : if( i == 0 ) break;
        case _        : throw H.error(
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

    // say(words.join(" "));
    var cur_ns = ":";
    var ns_len = 0;
    var fst_line = true;
    var sb = new StringBuf();
    for( w in words ) {
      // update namespace
      if( !w.startsWith(cur_ns) ) {
        var i = w.indexOf(":") + 1;
        cur_ns = w.substring(0, i);
        ns_len = i;
        if( fst_line )
          fst_line = false;
        else
          sb.add("\n\n");
        sb.add(cur_ns);
        sb.add("\n=-=-=-=-=\n");
      }
      sb.add("  ");
      sb.add(w.substr(ns_len));
    } // for words
    say(sb.toString());
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


  static function math_add(s: Stack): StackItem {
    var tos = s.pop();
    var nos = s.pop();
    var tos_type = tos.type();
    var nos_type = nos.type();

    // Both Int
    if( tos_type == "!Int" && nos_type == "!Int" ) {
      var fst = H.unwrap_int( tos );
      var snd = H.unwrap_int( nos );
      return add_int_int(fst, snd);
    }

    // One or both are Float
    if( tos_type == "!Float" || nos_type == "!Float" ) {
      var fst = H.unwrap_float( tos );
      var snd = H.unwrap_float( nos );
      return add_float_float(fst, snd);
    }

    // Both strings
    if( tos_type == "!String" && nos_type == "!String" ) {
      var fst = H.unwrap_string( tos );
      var snd = H.unwrap_string( nos );
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
      var fst = H.unwrap_int( tos );
      var snd = H.unwrap_int( nos );
      return subtract_int_int(snd, fst); // TOS from NOS
    }

    // Try to get floats
    var fst = H.unwrap_float( tos );
    var snd = H.unwrap_float( nos );
    return subtract_float_float(snd, fst); // TOS from NOS

    return Noop; // should be unreachable
  }

  static function math_multiply(s: Stack): StackItem {
    var tos = s.pop();
    var nos = s.pop();

    // Both Int
    if( tos.type() == "!Int" && nos.type() == "!Int" ) {
      var fst = H.unwrap_int( tos );
      var snd = H.unwrap_int( nos );
      return multiply_int_int(snd, fst);
    }

    // Try to get floats
    var fst = H.unwrap_float( tos );
    var snd = H.unwrap_float( nos );
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
}
