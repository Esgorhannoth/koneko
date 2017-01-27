package koneko;

import sys.FileSystem;
import koneko.Helpers as H;
import koneko.Typedefs;


class KonekoMod {
  public function new() {}

  static var Namespace = "fs";

  public inline function get_namespace() {
    return Namespace;
  }
  public function get_words(): Voc // just for testing now
  {
    // add them to the map manually :-/
    var words = new Voc();
    words.set("exists?", exists);
    words.set("exist?", exists);
    // 0.o seems that without calling .keys() this method is not created at all
    words.keys();
    return words;
  }

  public static function exists(s:Stack): StackItem {
    H.assert_has_one(s);
    var name = H.unwrap_string( s.pop() );
    if( FileSystem.exists(name) )
      s.push( IntSI( -1 ) ); // true
    else
      s.push( IntSI( 0 ) );  // false
    return Noop;
  }
}

