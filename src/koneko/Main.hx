package koneko;


enum Action {
  Eval(s: String);
  EvalClean(s: String);
  LoadFile(f: String);
  Repl;
}

class Main {
  static var prelude    = true;
  static var start_repl = false;

  public static function main() {
    var args = Sys.args();

    // no args - repl anyway
    if( args.length <= 0 )
      repl();

    try {
      var actions = parse(args);
      run(actions);
    }
    catch(e: Dynamic) handleErrors(e);
  }

  static function parse(args: Array<String>): Array<Action> {
    var actions = new Array<Action>();
    while(true) {
      // parse args
      var arg = args.shift();
      switch( arg ) {
        case "-i" | "--repl": start_repl = true;
        case "-f" | "--load":
          var fn = args.shift();
          if( fn == null )
            throw "No filename for -f|--load";
          actions.push(LoadFile(fn));

        case "-e" | "--eval":
          var body = args.shift();
          if( body == null )
            throw "No program for -e|--eval";
          actions.push(Eval(body));

        case "-E" | "--Eval":
          var body = args.shift();
          if( body == null )
            throw "No program for -E|--Eval";
          actions.push(EvalClean(body));

        case "-n" | "--no-prelude":
          prelude = false;

        case null:
          if( actions.length <= 0 ) actions.push(Repl);
          break;

        case _   :
                   if( StringTools.startsWith(arg, "-") )
                     throw 'Unknown option: $arg';
                   else
                     actions.push(LoadFile(arg));
      }
    } // while

    if( start_repl ) actions.push(Repl);
    return actions;
  }

  static function interp(s: String, ?intp: Interpreter) {
    var i: Interpreter;
    if( null == intp ) {
      i = new Interpreter();
      i = load_prelude(i);
    } else
      i = intp;
    i.interpret(s);
  }

  static function load_file(fn: String, i: Interpreter): Interpreter {
    if( sys.FileSystem.exists(fn) ) {
      var body = sys.io.File.getContent(fn);
      i.interpret(body);
    }
    return i;
  }

  static function load_prelude(i: Interpreter): Interpreter {
    if( prelude )
      i = load_file("Prelude.kn", i);
    return i;
  }

  static function handleErrors(e: Dynamic) {
    Sys.print("Error: ");
    Sys.println(e);
  }

  static function run(actions: Array<Action>) {
    var i = new Interpreter();
    i = load_prelude(i);
    for ( a in actions ) {
      switch( a ) {
        case Eval(s) : interp(s, i);
        case EvalClean(s) : interp(s);
        case LoadFile(f): i = load_file(f, i);
        case Repl: repl(i);
      }
    }
  }

  static function repl(?intp: Interpreter) {
    var line = "";
    var i: Interpreter;
    if( null == intp ) {
      i = new Interpreter();
      i = load_prelude(i);
    } else
      i = intp;
    while(true) {
      Sys.stdout().writeString("> ");
      Sys.stdout().flush();
      line = Sys.stdin().readLine();
      i.interpret(line);
    }
  }
}
