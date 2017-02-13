package koneko;

import koneko.Helpers as H;
import koneko.Typedefs;


class KonekoMod {
  public function new() {}

  static var Namespace = "sys";

  public inline function get_namespace() {
    return Namespace;
  }

  public function get_words(): Voc // just for testing now
  {
    // add them to the map manually :-/
    var words = new Voc();
    words.set("time", sys_time);

    // 0.o seems that without calling .keys() this method is not created at all
    words.keys();
    return words;
  }

  public static inline function sys_time(s:Stack): StackItem {
    H.push_float( s, Sys.time() );
    return Noop;
  }
}
