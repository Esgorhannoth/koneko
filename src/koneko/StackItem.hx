package koneko;

enum StackItem {
  Noop;
  IntSI       (i: Int);
  FloatSI     (f: Float);
  StringSI    (s: String);
  AtomSI      (s: String);
  DefAtomSI   (s: String);
  QuoteSI     (q: Array<StackItem>);
  PartQuoteSI (p: Array<StackItem>); // Partial quote, e.g. in interpreted multiline quote
}
