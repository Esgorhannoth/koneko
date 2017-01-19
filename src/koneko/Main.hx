package koneko;


enum Action {
  Eval(s: String);
  EvalClean(s: String);
  LoadFile(f: String);
}

class Main {
  static var prelude = true;

  public static function main() {
    var args = Sys.args();
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
      var actions = new Array<Action>();
      var arg = args.shift();
      switch( arg ) {
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
        case null: if( actions.length <= 0 ) repl();
        case _   :
                   if( StringTools.startsWith(arg, "-") )
                     throw 'Unknown option: $arg';
                   else
                     actions.push(LoadFile(arg));
      }
    } // while
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
        case LoadFile(f):
      }
    }
  }

  static function repl() {
    var line = "";
    var i = new Interpreter();
    i = load_prelude(i);
    while(true) {
      Sys.stdout().writeString("> ");
      Sys.stdout().flush();
      line = Sys.stdin().readLine();
      i.interpret(line);
    }
  }
}
