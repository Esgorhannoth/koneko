package koneko;

class Parser {



  // TODO from lexer
  inline function skip_token(?n: Int) {
    if( n == null ) {
      input.next();
      return;
    }
    for( i in 1 ... n )
      input.next();
  }
  // TODO from lexer
  function read_quote(): Token {
    var inner = new Array<Token>();
    skip_token(); // skip `[`
    while(true) {
      var tok = read_next();
      switch( tok ) {
        case RBracket:
          skip_token();
          return if( inner.length <= 0 ) None; else Quote(inner);
        case EOF:
          croak('Unclosed quote');
          return None;
        case _:
          inner.push(tok);
      }
    }
  }

  // for standalone testing
  public static function main() {
    //
  }
}
