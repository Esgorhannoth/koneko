package koneko;

enum KonekoException {
  StackUnderflow;
  IncompatibleTypes;
  WrongAssertionParam;
  AssertFailureWrongType(s: String);
  Custom(s: String);
}
