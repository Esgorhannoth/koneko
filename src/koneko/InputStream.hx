package koneko;

import haxe.Utf8 as Utf; // source is supposed to be utf-8

class InputStream {
  /**
    Copypaste from http://lisperator.net/pltut/parser/input-stream
   **/
  public var pos (default, null): Int;
  public var col (default, null): Int;
  public var line(default, null): Int;
  public var len (default, null): Int;
  var input: String;

  // throws
  public function new(input: String) {
    this.pos  = 0;
    this.col  = 0;
    this.line = 1;
    if( Utf.validate(input) ) {
      this.input = input;
      this.len   = Utf.length(input);
    }
    else
      throw "InputStream: Not a valid UTF-8 input";
  }

  public function next(): Int {
    var ch = Utf.charCodeAt(input, pos++);
    // == "\n"
    if (ch == 10) {
      line++;
      col = 0;
    } else
      col++;
    return ch;
  }
  public function peek(): Int
    return Utf.charCodeAt(input, pos);

  public function eof(): Bool
    return pos == len;

  public function croak(msg: String) {
    throw '$msg (${line}:${col})';
  }



  public static function main() {
    // testing if compiled separately
    var is = new InputStream("esko goes (home)");
    while( !is.eof() )
      Sys.println(is.next());
    is.croak("It's a croak! Dun Dun DUNN!");
  }
}
