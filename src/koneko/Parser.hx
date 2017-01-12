package koneko;

/**
  Grammar:
  Item : WORD | DEFWORD | Quote
  Quote : '[' WORD+ ']'
  DEFWORD : ':' WORD
 **/
class Parser {

  public var level(default, null): Int; // level of depth for quotes:
                                        // <0> [ <1> some word [ <2> more words ] ]
  var input: Lexer;

  public function new(input: String) {
    this.level = 0;
  }

  public function parse(input: String) {
    this.input = new Lexer(input);
    var ast = new Array<StackItem>(); // ast... lol
    while( !input.eof() ) {
      var tok = input.peek();
      switch( tok ) {
        case SomeInt(i) : ast.push( IntSI(i) );
        case SomeFloat(i) : ast.push( FloatSI(i) );
        case SomeString(i) : ast.push( StringSI(i) );
        case LBracket : input.croak("Not yet implemented");
        case RBracket : input.croak("Not yet implemented");
        case LParen | LBrace | RParen | RBrace : input.croak("Not yet implemented");
      } // switch
    } // while
  }

  function match(t: Token) {
    var tok = input.peek()
    if( Tokens.eq(t, tok) )
      input.next();
    else
      croak('Token "${tok} found, but ${t} expected"');
  }


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
