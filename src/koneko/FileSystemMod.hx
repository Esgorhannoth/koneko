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
    words.set("full-path", full_path);
    words.set("mkdir", create_directory);
    words.set("dir?", is_directory);
    words.set("read-dir", read_directory);

    // 0.o seems that without calling .keys() this method is not created at all
    words.keys();
    return words;
  }

  public static function exists(s:Stack): StackItem {
    H.assert_has_one(s);
    var name = H.unwrap_string( s.pop() );
    H.push_bool( s, FileSystem.exists(name) );
    return Noop;
  }

  public static function full_path(s:Stack): StackItem {
    H.assert_has_one(s);
    var rel_path = H.unwrap_string( s.pop() );
    try {
      H.push_string( s, FileSystem.fullPath(rel_path) );
    }
    catch(e:Dynamic) {
      throw 'No such file or directory: ${rel_path} (${e})';
    }
    return Noop;
  }

  public static function create_directory(s:Stack): StackItem {
    H.assert_has_one(s);
    var rel_path = H.unwrap_string( s.pop() );
    try {
      FileSystem.createDirectory(rel_path);
    }
    catch(e:Dynamic) {
      throw 'Cannot create directory: ${rel_path} (${e})';
    }
    return Noop;
  }

  public static function is_directory(s:Stack): StackItem {
    H.assert_has_one(s);
    var path = H.unwrap_string( s.pop() );
    if( path.length <= 0 )
      throw "Empty directory name";
    try {
      H.push_bool( s, FileSystem.isDirectory(path) );
    }
    catch(e:Dynamic) {
      throw 'No such file or directory: ${path} (${e})';
    }
    return Noop;
  }

  public static function read_directory(s:Stack): StackItem {
    H.assert_has_one(s);
    var dir = H.unwrap_string( s.pop() );
    if( dir.length <= 0 )
      throw "Empty directory name";
    try {
      var list = FileSystem.readDirectory(dir);
      list.sort(function(x:String, y:String): Int {
        if( x == y ) return 0;
        if( x > y ) return 1;
        return -1;
      });
      H.push_string_quote(s, list);
    }
    catch(e:Dynamic) {
      throw 'No such file or directory: ${dir} (${e})';
    }
    return Noop;
  }
}

