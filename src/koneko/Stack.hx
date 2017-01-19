package koneko;

interface IStack {
  public function tos(): StackItem; // Top Of Stack
  public function nos(): StackItem; // Next On Stack

  public function push(e: StackItem): Stack; // fluent interface ?
  public function pop(): StackItem;  // Returns TOS and removes it from stack

  public function dup(): Stack;      // DUPs TOS, fluent
  public function swap(): Stack;     // Swaps TOS and NOS

  public function is_empty(): Bool;   // if stack is empty
  public function clear(): Stack;    // Remove all elements, fluent

  public function iterator(): StackIterator;
}

class Stack implements IStack {

  // public var head  (default, default): StackCell;
  public var head                 : StackCell;
  public var length(default, null): Int;

  public var tmp                  : Stack; // additional stack for holding temporary values

  public function new(?with_tmp: Bool) {
    if( null == with_tmp )
      with_tmp = false;
    this.length = 0;
    if( with_tmp )
      this.tmp = new Stack();
  }

  public function push(e: StackItem): Stack // fluent interface ?
  {
    head = new StackCell(e, head);
    length++;
    return this;
  }

  public function pop(): StackItem  // Returns TOS and removes it from stack
  {
    var elt = head.value;
    head = head.next;
    length--;
    return elt;
  }

  public function tos(): StackItem // Top Of Stack
  {
    return (head == null) ? Noop : head.value;
  }

  public function nos(): StackItem // Next On Stack
  {
    return (head.next == null) ? Noop : head.next.value;
  }

  public function dup(): Stack      // DUPs TOS, fluent
  {
    if( length <= 0 )
      throw KonekoException.StackUnderflow;
    head = new StackCell(head.value, head);
    length++;
    return this;
  }

  public function swap(): Stack     // Swaps TOS and NOS
  {
    if( length < 2 )
      throw KonekoException.StackUnderflow;
    var nos_next = head.next.next;
    head.next.next = head;     // make NOS point to TOS
    head = head.next;          // 'move' NOS to TOS
    head.next.next = nos_next; // make new NOS point to old NOS's next
    return this;
  }

  public inline function is_empty(): Bool // if stack is empty
  {
    return this.length <= 0;
  }

  public function clear(): Stack    // Remove all elements, fluent
  {
    head   = null;
    length = 0;
    return this;
  }

  public function iterator(): StackIterator 
  {
    return new StackIterator(this);
  }

  public function toString() {
    var a = new Array<StackItem>();
    var elt = head;
    while( elt != null ) {
      a.push( elt.value );
      elt = elt.next;
    }
    return "\n[\n  // Top to bottom\n  " + a.join("\n  ") + "\n]";
  }


  // for standalone testing
  public static function main() {
    var s = new Stack();
    s.push(IntSI(5));
    s.push(StringSI("esko"));
    Sys.println(s);
    Sys.println ('Length: ${s.length}');

    Sys.println("SWAP'ing...");
    s.swap();
    Sys.println(s);

    Sys.println("DUP'ing...");
    s.dup();
    Sys.println(s);
    Sys.println ('Length: ${s.length}');

    s.push(QuoteSI([IntSI(42),StringSI("Gollum")]));
    Sys.println(s);
  }
}

class StackIterator {
  var head: StackCell;
  public function new(s: Stack) {
    this.head = s.head;
  }

  public function hasNext(): Bool {
    return (head == null) ? false : true;
  }

  public function next(): StackItem {
    var tos = head.value;
    head = head.next;
    return tos;
  }
}
