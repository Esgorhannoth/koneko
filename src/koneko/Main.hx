package koneko;

class Main {
  public static function main() {
    var args = Sys.args();
    if( args.length <= 0 )
      // throw "REPL is not yet implemented.";
      repl();
    else {
      var i = new Interpreter();
      try {
        if( (args[0] == "e" || args[0] == "-e") && (args.length >= 2) ) {
          i.interpret(args[1]);
        }
        // not 'e' or '-e'
        else {
          var fn = args[0];
          if( sys.FileSystem.exists(fn) ) {
            var body = sys.io.File.getContent(fn);
            i.interpret(body);
          }
          else
            throw 'File $fn not found.';
        }

      }
      catch(e: Dynamic) {
        Sys.print("Error: ");
        Sys.println(e);
      }
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
