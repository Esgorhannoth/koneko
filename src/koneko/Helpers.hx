package koneko;

import haxe.macro.Expr;

using  StringTools;
using  koneko.StackItem; // for .type and .toString

class Helpers {

  public static inline function error(s: String): KonekoException {
    return KonekoException.Custom(s);
  }

  // side-effect: `i` is updated after evaluation
  public static function load_file(fn: String, i: Interpreter) {
    if( sys.FileSystem.exists(fn) ) {
      try {
        var body = sys.io.File.getContent(fn);
        i.interpret(body);
      }
      catch(e: Dynamic)
        throw error('Could not get contents of file: ${fn}');
    }
    else
      throw error('Could not find file: ${fn}');
  }

  // 0-based
  public static function nth(s: Stack, n: Int): StackCell {
    assert_stack_has(s, n+1);
    var cell = s.head;
    while( n-- > 0 ) {
      cell = cell.next;
    } 
    return cell;
  }

  public static function assert_has_one(s: Stack) {
    if( s.is_empty() )
      throw KonekoException.StackUnderflow;
  }

  public static function assert_stack_has(s: Stack, n: Int) {
    if( n < 0 )
      throw KonekoException.WrongAssertionParam;
    if( s.length < n )
      throw KonekoException.StackUnderflow;
  }

  public static inline function assert_is(si: StackItem, type: String) {
    if( si.type() != type )
      throw KonekoException.AssertFailureWrongType(si.type(), type);
  }

  public static inline function assert_is_number(si: StackItem) {
    if( si.type() != "!Int" && si.type() != "!Float" )
      throw error('Expected number, but found ${si.type()}');
  }

  public static inline function assert_one_of(si: StackItem, types: Array<String>) {
    var type = si.type();
    for( t in types )
      if( t == type ) return;
    throw KonekoException.AssertFailureWrongType(si.type(), types.join(" | "));
  }

  public static function assert_valid_utf8(s: String) {
    if( !haxe.Utf8.validate(s) )
      throw error("Not a valid UTF-8 string");
  }

  public static inline function unwrap_int(si: StackItem): Int {
    return switch( si ) {
      case IntSI(i): i;
      case _ : throw error('Expected !Int, but found ${si.type()}');
    }
  }

  public static inline function unwrap_float(si: StackItem): Float {
    return switch( si ) {
      case IntSI(i)  : cast(i, Float);
      case FloatSI(f): f;
      case _ : throw error('Expected either !Int or !Float, but found ${si.type()}');
    }
  }

  public static inline function unwrap_bool(si: StackItem): Bool {
    var r = switch( si ) {
      case IntSI(i)  : cast(i, Float);
      case FloatSI(f): f;
      case _ : throw error('Expected either !Int or !Float as boolean, but found ${si.type()}');
    }
    return r != 0; // false for 0, true for everything else
  }

  public static inline function unwrap_string(si: StackItem): String {
    return switch( si ) {
      case StringSI(s): s;
      case _ : throw error('Expected !String, but found ${si.type()}');
    }
  }

  public static inline function unwrap_string_or(si: StackItem, val: String): String {
    return switch( si ) {
      case StringSI(s): s;
      case _          : val;
    }
  }

  public static inline function unwrap_quote(si: StackItem): Array<StackItem> {
    return switch( si ) {
      case QuoteSI(q) : q;
      case _          : throw error('Expected !Quote, but found ${si.type()}');
    }
  }

  public static inline function unwrap_atom(si: StackItem): String {
    return switch( si ) {
      case AtomSI(s)  : s;
      case _          : throw error('Expected !Quote, but found ${si.type()}');
    }
  }



  public static inline function push_bool(s:Stack, val:Bool) {
    if( val )
      s.push( IntSI( -1 ));
    else
      s.push( IntSI( 0 ));
  }

  public static inline function push_string(s: Stack, val:String) {
    s.push( StringSI(val) );
  }

  public static inline function push_int(s: Stack, val:Int) {
    s.push( IntSI(val) );
  }

  // ??
  public static inline function push_string_quote(s:Stack, val:Array<String>) {
    var arr = new Array<StackItem>();
    for( i in val )
      arr.push( StringSI(i) );
    s.push( QuoteSI(arr) );
  }




  //
  // Array
  //



  //
  // Chars
  //
  public static function char_to_utf8_string(char: Int): String {
    // TODO
    var u = new haxe.Utf8();
    u.addChar(char);
    return u.toString();
  }

  public static function utf8_to_chars(str: String): Array<Int> {
    var cps = new Array<Int>();
    for( i in 0 ... haxe.Utf8.length(str) )
      cps.push( haxe.Utf8.charCodeAt(str, i) );
    return cps;
  }

  public static function chars_to_utf8_string(chars: Array<Int>): String {
    // TODO
    var u = new haxe.Utf8();
    for ( i in chars )
      u.addChar(i);
    return u.toString();
  }

  public static function valid_for_uppercase(c: Int): Bool {
    // 65-90, 97-122 ascii, 1040-1071, 1072-1103, 1025+1105(80 diff)
    return (c >= 97 && c <= 122) || // ascii lower
      (c >= 1072 && c <= 1103);     // utf-8 cyrillic lower
  }

  public static function valid_for_lowercase(c: Int): Bool {
    // 65-90, 97-122 ascii, 1040-1071, 1072-1103, 1025+1105(80 diff)
    return (c >= 65 && c <= 90) || // ascii upper
      (c >= 1040 && c <= 1071);     // utf-8 cyrillic upper
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

  macro public static function swap_vars(a: Expr, b: Expr): Expr {
    return macro {
      var tmp = $a;
      $a = $b;
      $b = tmp;
    }
  }
}
