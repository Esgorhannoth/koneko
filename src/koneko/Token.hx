package koneko;

enum Token {
  SomeInt(i: Int);
  SomeFloat(f: Float);
  SomeString(s: String);

  DefAtom(w: String);       // Same as Atom, but starts with ":", e.g. :say-hello
  Atom(w: String);          // Almost any char, except all parens `[]{}()`
                            // and can't start with `:`
  // Quote(a: Array<Token>);

  LParen;    // `(`
  LBracket;  // `[`
  LBrace;    // `{`
  RParen;    // `)`
  RBracket;  // `]`
  RBrace;    // `}`

  None;
  EOF;
}

class Tokens {
  public static function type(a: Token): String {
    return switch( a ) {
      case SomeInt(_)    : "Int";
      case SomeFloat(_)  : "Float";
      case SomeString(_) : "String";
      case DefAtom(_)    : "DefAtom";
      case Atom(_)       : "Atom";
      case LParen        : "LParen";
      case LBracket      : "LBracket";
      case LBrace        : "LBrace";
      case RParen        : "RParen";
      case RBracket      : "RBracket";
      case RBrace        : "RBrace";
      case None          : "None";
      case EOF           : "EOF";
    }
  } // type

  public static function eq_type(a: Token, b: Token): Bool {
    return type(a) == type(b);
  }

  public static function eq(a: Token, b: Token): Bool {
    if( !eq_type(a, b) )
      return false;

    return switch( a ) {
      // subcases can be macroed out, but I'm lazy
      case SomeInt(i)    :
        switch( b ) {
          case SomeInt(ib) : i == ib;
          case _           : false;
        }
      case SomeFloat(f)  :
        switch( b ) {
          case SomeFloat(fb) : f == fb;
          case _             : false;
        }
      case SomeString(s) :
        switch( b ) {
          case SomeString(sb) : s == sb;
          case _              : false;
        }
      case DefAtom(s)    :
        switch( b ) {
          case DefAtom(sb) : s == sb;
          case _           : false;
        }
      case Atom(s)       :
        switch( b ) {
          case Atom(sb) : s == sb;
          case _        : false;
        }
      case _             : true;
    }
  }
}
