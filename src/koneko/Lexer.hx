package koneko;

class Lexer {
  // Since InputStream.next() returns int codepoint
  // it's good to use "x".code to compare.
  // "y".code returns char codepoint, works with utf-8
  // but this "y" has to have length of 1 codepoint
  // replacment occurs at compile-time

  public var current(default, null): Token;
  var input: InputStream;

  // throws
  public function new(input: String) {
    this.current = None;
    this.input = new InputStream(input);
  }

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
    return peek() == None;
  }

  public inline function croak(msg: String) { input.croak(msg); }



  // helpers
  public function read_next(): Token {
    read_while(is_whitespace);
    if( input.eof() ) return Eof;
    var ch = input.peek();
    /* No comments for now
    if( ch == "#" ) {
      skip_comment();
      return read_next();
    }
    */
    if( ch == '"' ) return read_string();
    if( ch == '[' ) return read_quote();
    // if (is_digit(ch)) return read_number();
    // if (is_id_start(ch)) return read_ident();
    return read_word_or_number();

    input.croak("Can't handle character: " + ch);
  }



  // For testing when compiled alone
  public static function main() {
    //
  }
}
