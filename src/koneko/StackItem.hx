package koneko;

enum StackItem {
  IntSI(i: Int);
  FloatSI(f: Float);
  StringSI(s: String);
  QuoteSI(q: Array<StackItem>);
  PartQuoteSI(pq: Array<StackItem>); // Partial quote, e.g. in interpreted multiline quote
}
