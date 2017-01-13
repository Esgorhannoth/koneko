package koneko;

class StackCell {

  public var value(default, null) : StackItem;
  public var next (default, set) : StackCell;

  public function new(value: StackItem, ?next: StackCell) {
    this.value = value;
    this.next  = next;
  }

  function set_next(v: StackCell): StackCell {
    this.next = v;
    return v;
  }



  // for standalone testing
  public static function main() {
    var sc = new StackCell(IntSI(5), null);
    var s2 = new StackCell(StringSI("esko"), sc);
    Sys.println(sc);
    Sys.println(s2);
  }
}
