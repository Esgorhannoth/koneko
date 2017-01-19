package koneko;

enum KonekoException {
  StackUnderflow;
  IncompatibleTypes;
  WrongAssertionParam;
  AssertFailureWrongType(s: String, expect: String);
  Custom(s: String);
  DivisionByZero;
}
