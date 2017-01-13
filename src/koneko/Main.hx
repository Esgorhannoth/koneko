package koneko;

class Main {
  public static function main() {
    var args = Sys.args();
    if( args.length <= 0 )
      throw "REPL is not yet implemented.";
    else {
      var i = new Interpreter();
      i.interpret(args[0]);
    }
  }
}
