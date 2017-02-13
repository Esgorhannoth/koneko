package koneko;

using  StringTools;
using  koneko.StackItem;

enum StackItem {
  Noop;
  DefAtomSI;    // mode switcher
  MaybeDefSI;   // mode switcher
  IntSI       (i: Int);
  FloatSI     (f: Float);
  StringSI    (s: String);
  AtomSI      (s: String);
  QuoteSI     (q: Array<StackItem>);
  BuiltinSI   (f: Stack -> StackItem); // built-in callable static function(Stack): StackItem

  BreakSI;    // signals break for loops
  ErrSI       (e: String); // Operation resulted in error

  // not needed yet
  PartQuoteSI (p: Array<StackItem>); // Partial quote, e.g. in interpreted multiline quote
}

class StackItems {
  public static function type(si: StackItem): String {
    return switch( si ) {
      case Noop          : "!Noop";
      case IntSI     (_) : "!Int";
      case FloatSI   (_) : "!Float";
      case StringSI  (_) : "!String";
      case AtomSI    (_) : "!Atom";
      case DefAtomSI     : "!DefAtom";
      case MaybeDefSI    : "!MaybeDef";
      case QuoteSI   (_) : "!Quote";
      case BuiltinSI (_) : "!Builtin";
      case ErrSI     (_) : "!Error";
      case BreakSI       : "!Break";
      case _             : "!Unknown";
    }
  }

  public static function toString(si: StackItem): String {
    return switch( si ) {
      case Noop          : "Noop";
      case IntSI     (i) : Std.string(i);
      case FloatSI   (f) : Std.string(f);
      // case StringSI  (s) : '"${s}"';
      case StringSI  (s) : '"${s.replace("\\n","\\\\n").replace("\\t","\\\\t")}"';
      // case AtomSI    (s) : '<A:${s}>';
      case AtomSI    (s) : s;
      case DefAtomSI     : '"<DefAtom>"';
      case MaybeDefSI    : '"<MaybeDef>"';
      case QuoteSI   (q) :
        var a = new Array<String>();
        for ( i in q )
          a.push( i.toString() );
        "[" + a.join(" ") + "]";
      case BuiltinSI (_) : "<Builtin>";
      case ErrSI     (_) : "<Error>";
      case BreakSI       : "<Break>";
      case _             : "<Unknown>";
    }
  }

  public static function deepCopy(si: StackItem): StackItem {
    return switch( si ) {
      case QuoteSI(q) :
        var ar = new Array<StackItem>();
        for( i in q ) {
          ar.push( i.deepCopy() );
        }
        QuoteSI(ar);
      case _          : si;
    }
  }
}
