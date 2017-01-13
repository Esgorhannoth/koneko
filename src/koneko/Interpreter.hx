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
          case Noop : Sys.println('No such word "${si}"');
          case _    : eval_item(si, Eager);
        }
      case DefAtomSI (s) :  // TODO
      case QuoteSI   (q) :  // TODO
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
    add_builtin("show", Builtins.show_stack);
    add_builtin("dup",  Builtins.dup);
    add_builtin("+",    Builtins.add);
  }

  inline function add_builtin(key: String, builtin: Stack->StackItem) {
    return vocabulary.add(key, BuiltinSI(builtin));
  }


  // for standalone testing
  public static function main() {
    var i = new Interpreter();
    i.interpret("42 32 dup dup show 3 4 + show + show");
    //Sys.println(i.stack);
  }
}
