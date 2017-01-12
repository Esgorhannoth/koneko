package koneko;

enum Token {
  SomeInt(i: Int);
  SomeFloat(f: Float);
  SomeString(s: String);

  DefWord(w: String);       // Same as Word, but starts with ":", e.g. :say-hello
  Word(w: String);          // Almost any char, except all parens `[]{}()`
                            // and can't start with `:`
  Quote(a: Array<Token>);

  LParen;    // `(`
  LBracket;  // `[`
  LBrace;    // `{`
  RParen;    // `)`
  RBracket;  // `]`
  RBrace;    // `}`

  None;
  EOF;
}
