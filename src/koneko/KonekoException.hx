package koneko;

enum KonekoException {
  StackUnderflow;
  IncompatibleTypes;
  WrongAssertionParam;
  Custom(s: String);
}
