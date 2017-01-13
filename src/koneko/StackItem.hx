package koneko;

enum StackItem {
  Noop;
  IntSI       (i: Int);
  FloatSI     (f: Float);
  StringSI    (s: String);
  AtomSI      (s: String);
  DefAtomSI   (s: String);
  QuoteSI     (q: Array<StackItem>);
  BuiltinSI   (f: Stack -> StackItem); // built-in callable static function(Stack): StackItem

  // not needed yet
  PartQuoteSI (p: Array<StackItem>); // Partial quote, e.g. in interpreted multiline quote
}

class StackItems {
  public static function type(si: StackItem): String {
    return switch( si ) {
      case Noop          : "Noop";
      case IntSI     (_) : "Int";
      case FloatSI   (_) : "Float";
      case StringSI  (_) : "String";
      case AtomSI    (_) : "Atom";
      case DefAtomSI (_) : "DefAtom";
      case QuoteSI   (_) : "Quote";
      case BuiltinSI (_) : "Builtin";
      case _             : "Unknown";
    }
  }
}
