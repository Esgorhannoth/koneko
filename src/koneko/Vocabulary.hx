package koneko;

/**
  Contains mappings from atoms to array of `StackItem`s
 **/
class Vocabulary {

  var voc: Map<String, StackItem>;

  public function new() {
    this.voc = new Map<String, StackItem>();
  }

  public function exists(key: String): Bool {
    return this.voc.exists(key);
  }
  public function get(key: String): StackItem {
    // no such atom
    if( !voc.exists(key) )
      return Noop;
    // no atom definition
    return voc.get(key); // return first definition from possible many
  }

  // fluent
  public function set(key: String, value: StackItem): Vocabulary {
    voc.set(key, value);
    return this;
  }

  public inline function add(key: String, value: StackItem): Vocabulary {
    return this.set(key, value);
  }

  // fluent
  public function delete(key: String): Vocabulary {
    if( voc.exists(key) )
      voc.remove(key);
    return this;
  }

  public inline function remove(key: String): Vocabulary {
    return this.delete(key);
  }

  public inline function keys(): Iterator<String> {
    return this.voc.keys();
  }


  // for standalone testing
  public static function main() {
    //
  }
}
