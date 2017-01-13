package koneko;

class Main {
  public static function main() {
    var args = Sys.args();
    if( args.length <= 0 )
      // throw "REPL is not yet implemented.";
      repl();
    else {
      var i = new Interpreter();
      i.interpret(args[0]);
    }
  }

  static function repl() {
    var line = "";
    var i = new Interpreter();
    while(true) {
      Sys.stdout().writeString("> ");
      Sys.stdout().flush();
      line = Sys.stdin().readLine();
      i.interpret(line);
    }
  }
}
