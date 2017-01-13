package koneko;

enum EvalMode {
  Lazy;
  Eager;
}
/**
  1. Parse line
  2. Eval 'AST'
 **/

class Interpreter {

  public var vocabulary (default, null): Vocabulary;
  public var stack      (default, null): Stack;
  // public var parser     (default, null): Parser;

  public function new() {
    this.vocabulary = new Vocabulary();
    this.stack      = new Stack();
    init_builtins();
  }

  public function eval_item(item: StackItem, ?how: EvalMode) {
    if( how == null )
      how = Lazy;
    switch( item ) {
      case IntSI     (_) | FloatSI(_) | StringSI(_) : stack.push(item);
      case AtomSI    (s) :
        var si = vocabulary.get(s);
        switch( si ) {
          case Noop : Sys.println('No such word "${s}"');
          case _    : eval_item(si, Eager);
        }
      case DefAtomSI (s) : 
        if( stack.is_empty() )
          throw KonekoException.StackUnderflow;
        // bind `s` to TOS
        vocabulary.set(s, stack.pop());
      case QuoteSI   (q) :
        if( how == Lazy )
          stack.push(item); // just push parsed quote to stack
        else {
          for( i in q )
            eval_item(i);
        }
      case BuiltinSI (f) : f(stack);

                           // not needed yet
      case Noop: 
      case PartQuoteSI(_):  // should not meet at all
    }
  }

  public function eval(ast: Array<StackItem>, ?how: EvalMode) {
    if( how == null )
      how = Lazy;
    for( el in ast ) {
      eval_item(el, how);
    }
  }

  public function interpret(line: String) {
    try {
      var p = new Parser(line);
      var ast = p.parse();
      eval(ast);
    } catch(e: Dynamic) {
      Sys.println(e);
    }

  }

  function init_builtins() {
    // vocabulary.add("show", BuiltinSI( Builtins.show_stack ));
    // vocabulary.add("dup", BuiltinSI( Builtins.dup ));
    add_builtin("dup",  Builtins.dup);
    add_builtin("drop", Builtins.drop);
    add_builtin("swap", Builtins.swap);
    add_builtin("+",    Builtins.add);

    add_builtin("echo",  Builtins.print);
    add_builtin("print", Builtins.print);
    add_builtin("puts",  Builtins.print);

    // add_builtin("show", Builtins.show_stack);
    add_builtin(".s", Builtins.show_stack);
    add_builtin(".",  Builtins.pop_and_print);
    add_builtin("show-stack", Builtins.show_debug);

    add_builtin("bye", Builtins.quit);
  }

  inline function add_builtin(key: String, builtin: Stack->StackItem) {
    return vocabulary.add(key, BuiltinSI(builtin));
  }


  // for standalone testing
  public static function main() {
    var i = new Interpreter();
    // i.interpret("42 32 dup dup show 3 4 + show + show");
    // i.interpret("'esko ' 'goes ' 'home' + + echo .s" );
    i.stack.clear();
    i.interpret("12 42 .s + '||' print .s show-stack");
    //Sys.println(i.stack);
  }
}
