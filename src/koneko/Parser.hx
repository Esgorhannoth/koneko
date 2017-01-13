package koneko;

using  koneko.Token;

/**
  Grammar:
  Item : ATOM | DEFATOM | Quote
  Quote : '[' ATOM+ ']'
  DEFATOM : ':' ATOM
  ATOM : [^][(){}]\t\n ]+
 **/
class Parser {

  /*
  public var level(default, null): Int; // level of depth for quotes:
                                        // <0> [ <1> some word [ <2> more words ] ]
   */
  var input: Lexer;

  public function new(input: String) {
    this.input = new Lexer(input);
    // this.level = 0;
  }

  public function parse(): Array<StackItem> {
    var ast = new Array<StackItem>(); // ast... lol
    while( !input.eof() ) {
      var tok = input.peek();
      switch( tok ) {
        // values
        case SomeInt(i)    : ast.push( read_int(i) );
        case SomeFloat(f)  : ast.push( read_float(f) );
        case SomeString(s) : ast.push( read_string(s) );
        // atoms
        case Atom(s)       : ast.push( read_atom(s) );
        case DefAtom(s)    : ast.push( read_defatom(s) );
        // quotes
        case LBracket      : ast.push( read_quote() );
        case RBracket      : return ast;
        // not yet implemented
        // case LParen | LBrace | RParen | RBrace : input.croak("Not yet implemented");
        case LParen | LBrace | RParen | RBrace : skip_token();
        // else
        case None : continue;
        case EOF  : break; // should be unreachable
      }
    } // while not eof

    return ast;
  }

  function read_int(i: Int)        : StackItem { input.next(); return IntSI     (i); }
  function read_float(f: Float)    : StackItem { input.next(); return FloatSI   (f); }
  function read_string(s: String)  : StackItem { input.next(); return StringSI  (s); }
  function read_atom(s: String)    : StackItem { input.next(); return AtomSI    (s); }
  function read_defatom(s: String) : StackItem { input.next(); return DefAtomSI (s); }

  function read_quote(): StackItem {
    var quote = new Array<StackItem>();
    skip_token();   // skip `[`
    while(true) {
      var tok = input.peek();
      switch( tok ) {
        case RBracket:
          skip_token(); // skip `]`
          return if( quote.length <= 0 ) Noop; else QuoteSI(quote);
        case EOF:
          input.croak('Unclosed quote');
          return Noop;
        case _:
          quote = parse();
      }
    }
  }

  // helpers
  function match(t: Token) {
    // is this func is ever used?
    var tok = input.peek();
    if( Tokens.eq(t, tok) )
      skip_token();
    else
      input.croak('Token "${tok} found, but ${t} expected"');
  }

  inline function skip_token(?n: Int) {
    if( n == null ) {
      input.next();
      return;
    }
    for( i in 1 ... n )
      input.next();
  }

  // for standalone testing
  public static function main() {
    var test_s = "stop 'right' \"there\" [ criminal [scum!] ] 42 12! 1+";
    var p = new Parser(test_s);
    var ast = p.parse();
    for ( node in ast )
      Sys.println(node);
  }
}
