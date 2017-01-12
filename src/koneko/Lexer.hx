package koneko;

import haxe.Utf8;

class Lexer {
  // Since InputStream.next() returns int codepoint
  // it's good to use "x".code to compare.
  // "y".code returns char codepoint, works with utf-8
  // but this "y" has to have length of 1 codepoint
  // replacment occurs at compile-time

  public var current(default, null): Token;

  var input: InputStream;

  // leading minus is not allowed in numbers
  // number with leading minus is considered a word
  static var rx_int_hex = ~/^0x[0-9a-f]+$/i;
  static var rx_int_oct = ~/^0[0-7]+$/i;
  static var rx_int = ~/^[0-9]+$/;
  static var rx_float = ~/^\d+\.\d*$/; // 3. is a valid float number, .3 is not
  // static var rx_float_exp = // not supported (for now?)
  static var rx_defword = ~/^:[^][(){}\t\n\r \0]+$/i;
  static var rx_word = ~/^[^][(){}\t\n\r \0]+$/;

  static var rx_rparen   = ~/^\)$/;
  static var rx_rbracket = ~/^]$/;
  static var rx_rbracen  = ~/^}$/;

  // throws
  public function new(input: String) {
    this.current = None;
    this.input = new InputStream(input);
  }

  // public interface
  public function next() {
    var tok = current;
    current = None;
    return switch( tok ) {
      case None: read_next();
      case _   : tok;
    }
  }

  public function peek() {
    if( current == None )
      current = read_next();
    return current;
  }

  public inline function eof() {
    return switch( peek() ) {
      case EOF : true;
      case _   : false;
    }
  }

  public inline function croak(msg: String) { input.croak(msg); }



  // private helpers
  function read_next(): Token {
    skip_whitespace();
    if( input.eof() ) return EOF;
    var ch = input.peek();
    /* No comments for now
    if( ch == "#" ) {
      skip_comment();
      return read_next();
    }
    */
    if( ch == '"'.code ) return read_string('"');
    if( ch == "'".code ) return read_string("'");

    if( ch == "(".code ||
        ch == "[".code ||
        ch == "{".code ||
        ch == ")".code ||
        ch == "]".code ||
        ch == "}".code )
      skip_token();

    if( ch == "(".code ) return LParen;
    if( ch == "[".code ) return LBracket;
    if( ch == "{".code ) return LBrace;
    if( ch == ")".code ) return RParen;
    if( ch == "]".code ) return RBracket;
    if( ch == "}".code ) return RBrace;
    return read_atom();
  }

  function read_string(end: String): Token {
    return SomeString( read_escaped(end) );
  }

  function read_escaped(end: String): String {
    var escaped = false;
    var str = new Utf8();
    input.next();
    while( !input.eof() ) {
      var ch = input.next();
      if( escaped ) {
        str.addChar(ch);
        escaped = false;
      } else if( ch == "\\".code ) {
        escaped = true;
      } else if( ch == Utf8.charCodeAt(end, 0) ) {
        break;
      } else {
        str.addChar(ch);
      }
    }
    return str.toString();
  }

  function read_atom(): Token {
    skip_whitespace();
    var atom = read_while(is_atom_char);
    if( rx_int_hex.match(atom) ) {
      var i = Std.parseInt(atom);
      if( i == null )
        croak('Error parsing "${atom}"');
      return SomeInt(i);

    } else if( rx_int_oct.match(atom) ) {
      croak('Std.parseInt does not support octals');

    } else if( rx_int.match(atom) ) {
      var i = Std.parseInt(atom);
      if( i == null )
        croak('Error parsing "${atom}"');
      return SomeInt(i);

    } else if( rx_float.match(atom) ) {
      var f = Std.parseFloat(atom);
      if( f == null )
        croak('Error parsing ${atom}');
      return SomeFloat(f);

    } else if( rx_defword.match(atom) ) {
      return DefWord(atom.substr(1));

    } else if( rx_word.match(atom) ) {
      return Word(atom);
    }

    croak('Error parsing "${atom}"');
    return None;
  }


  // Not working :(
  // function read_while <T> (pred: T -> Bool): String {
  function read_while(pred: Int -> Bool): String {
    var str = new Utf8();
    while( !input.eof() && (pred( input.peek() )) )
      str.addChar( input.next() );
    return str.toString();
  }

  function is_whitespace(ch: Int): Bool {
    return switch( ch ) {
      case 9 | 10 | 13 | 32 : true;
      case _ : false;
    }
  }

  inline function skip_whitespace() {
    read_while(is_whitespace);
  }

  inline function skip_token(?n: Int) {
    if( n == null ) {
      input.next();
      return;
    }
    for( i in 1 ... n )
      input.next();
  }

  inline function is_not_whitespace(ch: Int): Bool {
    return !is_whitespace(ch);
  }

  function is_atom_char(ch: Int): Bool {
    return switch( ch ) {
      // whitespace
      case 9 | 10 | 13 | 32    : false;
      // misc parens
      case "(".code | ")".code : false;
      case "{".code | "}".code : false;
      case "[".code | "]".code : false;
      // else
      case _                   : true;
    }
  }


  // For testing when compiled alone
  public static function main() {
    var test_string = "'esko' fukos() [ there [ 12 42 how you doin ] it is ]\nesko\t \"goes\"  \n\n+1 'home' фибергласовый щит :say-hello";
    Sys.println(test_string);
    var lx = new Lexer(test_string);
    while( !lx.eof() )
      Sys.println(lx.next());
  }
}
