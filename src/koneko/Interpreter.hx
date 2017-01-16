package koneko;

enum EvalMode {
  Lazy;
  Eager;
  Definition;
}
/**
  1. Parse line
  2. Eval 'AST'
 **/

class Interpreter {

  public var vocabulary (default, null): Vocabulary;
  public var stack      (default, null): Stack;


  public function new() {
    this.vocabulary = new Vocabulary();
    this.stack      = new Stack();
    init_builtins();
  }


  public function eval_item(item: StackItem, ?how: EvalMode): EvalMode {
    if( how == null )
      how = Lazy;
    switch( item ) {
      case IntSI     (_) | FloatSI(_) | StringSI(_) : stack.push(item);
      case AtomSI    (s) :
        if( how == Definition ) {
          if( stack.is_empty() )
            throw KonekoException.StackUnderflow;
          else // bind `s` to TOS
            vocabulary.set(s, stack.pop());
          return Lazy;
        }
        var si = vocabulary.get(s);
        switch( si ) {
          case Noop : say('No such word "${s}"');
          case _    : return eval_item(si, Eager);
        }
      case DefAtomSI     : 
        throw KonekoException.Custom("DefAtom in AST 0.o");
      case QuoteSI   (q) :
        if( how == Lazy )
          stack.push(item); // just push parsed quote to stack
        else { // Eager
          for( i in q )
            eval_item(i); // Lazily
        }
      case BuiltinSI (f) :
        var si = f(stack);
        return switch( si ) {
          case DefAtomSI    : Definition;
          case _            : Lazy;
        }
      case ErrSI     (e) :
        say('\nERROR: $e');
        stack.pop();

                           // not needed yet
      case Noop          : 
      case PartQuoteSI(_): // should not meet at all
    } // switch
    return Lazy;
  }

  public function eval(ast: Array<StackItem>, ?how: EvalMode) {
    var mode = ( how == null ) ? Lazy : how;
    for( el in ast ) {
      mode = eval_item(el, mode);
    }
  }

  public function interpret(line: String) {
    try {
      var p = new Parser(line);
      var ast = p.parse();
      eval(ast);
    } catch(e: Dynamic) {
      if( Std.is(e, KonekoException) ) {
        out("ERROR: ");
        say(switch( cast(e, KonekoException) ) {
          case StackUnderflow      : "Stack Underflow";
          case IncompatibleTypes   : "Incompatible Type(s)";
          case WrongAssertionParam : "Debug: Wrong assertion parameter";
          case AssertFailureWrongType(s) : 'Wrong Type ${s}';
          case Custom(s)           : s;
        });
      }
      else
        say(e);
    }
  }

  function init_builtins() {
    add_builtin("dup",  Builtins.dup);
    add_builtin("drop", Builtins.drop);
    add_builtin("swap", Builtins.swap);
    add_builtin("over", Builtins.over);
    add_builtin("pick", Builtins.pick);
    add_builtin("rot",  Builtins.rotate_3to1);
    add_builtin("-rot",  Builtins.rotate_1to3);
    add_builtin("clear-stack", Builtins.clear_stack);

    add_builtin("type?", Builtins.type);


    add_builtin("+",      Builtins.add);
    add_builtin("-",      Builtins.subtract);
    add_builtin("*",      Builtins.multiply);
    add_builtin("negate", Builtins.negate);

    add_builtin("random", Builtins.math_random);
    add_builtin("rnd",    Builtins.math_rnd);

    add_builtin("sleep",  Builtins.sleep);

    add_builtin("echo",  Builtins.print);
    add_builtin("print", Builtins.print);
    add_builtin("puts",  Builtins.print);

    add_builtin("i",     Builtins.with_interp(this, Builtins.identity));
    add_builtin("if",    Builtins.with_interp(this, Builtins.if_conditional));
    add_builtin("when",  Builtins.with_interp(this, Builtins.when_conditional));
    add_builtin("while", Builtins.with_interp(this, Builtins.while_loop));
    add_builtin(":",     Builtins.define);

    add_builtin(".s", Builtins.show_stack);
    add_builtin(".",  Builtins.pop_and_print);
    add_builtin("words", Builtins.with_voc(vocabulary, Builtins.words_list));
    add_builtin("show-stack", Builtins.show_debug);

    add_builtin("quit/with", Builtins.quit_with);
    add_builtin("bye", Builtins.quit);
  }

  inline function add_builtin(key: String, builtin: Stack->StackItem) {
    return vocabulary.add(key, BuiltinSI(builtin));
  }


  // helpers
  static inline function out(v: Dynamic) {
    Sys.print(v);
  }

  static inline function say(v: Dynamic) {
    Sys.println(v);
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
