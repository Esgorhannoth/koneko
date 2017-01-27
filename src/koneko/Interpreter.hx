package koneko;

import koneko.Helpers as H;

enum EvalMode {
  Lazy;
  Eager;
  Definition;
  MaybeDefinition;
  Break;     // ??  for breaking out of loops
}
/**
  1. Parse line
  2. Eval 'AST'
 **/

class Interpreter {

  public var vocabulary (default, null): Vocabulary;
  public var stack      (default, null): Stack;


  public function new(?main_ns: String, ?prelude_ns: String) {
    this.vocabulary = new Vocabulary(main_ns, prelude_ns); // "Main" and "Prelude" as default
    this.stack      = new Stack(true); // with temporary stack inside
    init_builtins();
  }


  public function eval_item(item: StackItem, ?how: EvalMode): EvalMode {
    if( how == null )
      how = Lazy;
    switch( item ) {
      case IntSI     (_) | FloatSI(_) | StringSI(_) : stack.push(item);
      case AtomSI    (s) :
        // define
        if( how == Definition ) {
          if( stack.is_empty() )
            throw KonekoException.StackUnderflow;
          else // bind `s` to TOS
            vocabulary.set(s, stack.pop());
          return Lazy;
        }

        // Maybe define
        if( how == MaybeDefinition ) {
          if( stack.is_empty() )
            throw KonekoException.StackUnderflow;
          else // bind `s` to TOS
            if( vocabulary.exists_in_current(s) ) {
              stack.pop(); // pop possible definition anyway
              throw KonekoException.AlreadyDefined(s);
            }
            else
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
      case MaybeDefSI    : 
        throw KonekoException.Custom("MaybeDef in AST 0.o");
      case BreakSI       :
        throw KonekoException.Custom("Break in AST 0.o");
      case QuoteSI   (q) :
        if( how == Lazy )
          stack.push(item); // just push parsed quote to stack
        else { // Eager
          var r = eval(q);
          return r;
        }
      case BuiltinSI (f) :
        var si = f(stack);
        return switch( si ) {
          case DefAtomSI    : Definition;
          case MaybeDefSI   : MaybeDefinition;
          case BreakSI      : Break;
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
      if( mode == Break )
        break;
    }
    return mode;
  }

  public function interpret(line: String) {
    try {
      var p = new Parser(line);
      var ast = p.parse();
      eval(ast);
    }
    catch(e: Dynamic)
      handleErrors(e);
  }

  function handleErrors(e: Dynamic) {
    if( Std.is(e, KonekoException) ) {
      out("ERROR: ");
      say(switch( cast(e, KonekoException) ) {
        case AssertFailureWrongType(s, ex) : 'Wrong Type ${s}, expected ${ex}';
        case StackUnderflow      : "Stack Underflow";
        case IncompatibleTypes   : "Incompatible Type(s)";
        case WrongAssertionParam : "Debug: Wrong assertion parameter";
        case Custom(s)           : s;
        case DivisionByZero      : "Cannot divide by zero";
        case AlreadyDefined(s)   : 'Word $s is already defined';
      });
    }
    else
      say(e);
  }

  function init_builtins() {
    // assertion
    add_builtin("assert",        Builtins.assert_true);
    add_builtin("assert/msg",    Builtins.assert_true_msg);

    // stack manipulation
    add_builtin("dup",           Builtins.dup);
    add_builtin("drop",          Builtins.drop);
    add_builtin("swap",          Builtins.swap);
    add_builtin("over",          Builtins.over);
    add_builtin("pick",          Builtins.pick);
    add_builtin("rot",           Builtins.rotate_3to1);
    add_builtin("-rot",          Builtins.rotate_1to3);
    add_builtin("clear-stack",   Builtins.clear_stack);
    add_builtin(".s",            Builtins.show_stack);
    add_builtin(".sl",           Builtins.stack_length);
    add_builtin(".",             Builtins.pop_and_print);
    add_builtin("show-stack",    Builtins.show_debug);

    // temp stack manipulation
    add_builtin(">t",            Builtins.temp_stack_push);
    add_builtin("<t",            Builtins.temp_stack_pop);
    add_builtin(".t",            Builtins.temp_stack_show);
    add_builtin(".tl",           Builtins.temp_stack_length);

    // Strings
    add_builtin("string-length", Builtins.string_length);
    add_builtin("at",            Builtins.string_at);
    add_builtin("to-str",        Builtins.string_to_string);
    add_builtin("sub",           Builtins.string_substring_common(SUB));
    add_builtin("substr",        Builtins.string_substring_common(SUBSTR));
    add_builtin("subrange",      Builtins.string_substring_common(SUBRANGE));
    add_builtin("backw",         Builtins.string_backwards);
    add_builtin("uc",            Builtins.string_case_upper);
    add_builtin("lc",            Builtins.string_case_lower);

    add_builtin("atc",           Builtins.string_atc);
    add_builtin("emit",          Builtins.string_emit);
    add_builtin("chr->str",      Builtins.string_char_to_string);
    add_builtin("chars->str",    Builtins.string_chars_to_string);


    // Math
    add_builtin("+",             Builtins.add);
    add_builtin("-",             Builtins.subtract);
    add_builtin("*",             Builtins.multiply);
    add_builtin("/",             Builtins.math_division);
    add_builtin("div",           Builtins.math_int_division);
    add_builtin("mod",           Builtins.math_modulo);
    add_builtin("negate",        Builtins.math_negate);
    add_builtin("=",             Builtins.math_compare(EQ));
    add_builtin("!=",            Builtins.math_compare(NQ));
    add_builtin(">",             Builtins.math_compare(GT));
    add_builtin("<",             Builtins.math_compare(LT));
    add_builtin(">=",            Builtins.math_compare(GE));
    add_builtin("<=",            Builtins.math_compare(LE));

    add_builtin("not",           Builtins.math_logical(NOT));
    add_builtin("and",           Builtins.math_logical(AND));
    add_builtin("or",            Builtins.math_logical(OR));
    add_builtin("xor",           Builtins.math_logical(XOR));

    add_builtin("ceil",          Builtins.math_rounding(Math.ceil));
    add_builtin("floor",         Builtins.math_rounding(Math.floor));
    add_builtin("round",         Builtins.math_rounding(Math.round));

    add_builtin("random",        Builtins.math_random);
    add_builtin("rnd",           Builtins.math_rnd);


    // Quotes
    add_builtin("i",             H.with_interp(this, Builtins.identity));
    add_builtin("quote",         Builtins.quote_values);
    add_builtin("unquote",       Builtins.unquote_to_values);
    add_builtin("q<",            Builtins.push_to_quote);
    add_builtin(">q",            Builtins.unshift_to_quote);
    add_builtin("<q",            Builtins.shift_from_quote);
    add_builtin("q>",            Builtins.pop_from_quote);
    add_builtin("ql",            Builtins.quote_length);
    add_builtin("reverse",       Builtins.reverse_quote);
    add_builtin("concat",        Builtins.concat_quotes);

    // looping and branching
    add_builtin("if",            H.with_interp(this, Builtins.if_conditional));
    add_builtin("when",          H.with_interp(this, Builtins.when_conditional));
    add_builtin("while",         H.with_interp(this, Builtins.while_loop));
    add_builtin("times",         H.with_interp(this, Builtins.times_loop));

    // Definitions
    add_builtin(":",             Builtins.define);
    add_builtin("is!",           Builtins.define);
    add_builtin("is",            Builtins.careful_define);
    add_builtin("def?",          H.with_voc(vocabulary, Builtins.define_check_word));
    add_builtin("undef",         H.with_voc(vocabulary, Builtins.define_undefine));
    add_builtin("see",           H.with_voc(vocabulary, Builtins.define_see_source));

    add_builtin("break",         Builtins.break_loop);

    // Utils
    add_builtin("all-words",     H.with_voc(vocabulary, Builtins.words_list));
    add_builtin("type?",         Builtins.type);

    // namespace
    add_builtin("ns",            H.with_voc(vocabulary, Builtins.namespace_set));
    add_builtin("ns?",           H.with_voc(vocabulary, Builtins.namespace_get));
    add_builtin("ns-def?",       H.with_voc(vocabulary, Builtins.namespace_check_defined));
    add_builtin("ns-words",      H.with_voc(vocabulary, Builtins.namespace_words_list));
    add_builtin("words",         H.with_voc(vocabulary, Builtins.namespace_cur_words));
    add_builtin("using",         H.with_voc(vocabulary, Builtins.namespace_using));
    add_builtin("active-nss",    H.with_voc(vocabulary, Builtins.namespace_active_nss));

    // Exiting
    add_builtin("quit/with",     Builtins.quit_with);
    add_builtin("bye",           Builtins.quit);

    // Outer unverse
    add_builtin("args",          Builtins.args_from_cli);
    add_builtin("read-line",     Builtins.read_line_stdin);
    add_builtin("print",         Builtins.print);
    add_builtin("sleep",         Builtins.sleep);

    // Modules
    add_builtin("load",          H.with_voc(vocabulary, Builtins.load_module));
  }

  inline function add_builtin(key: String, builtin: Stack->StackItem) {
    return vocabulary.add_builtin(key, BuiltinSI(builtin));
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
