package koneko;

/**
  Contains mappings from atoms to array of `StackItem`s
 **/
class Vocabulary {

  var voc: Map<String, Array<StackItem>>;

  public function new() {
    this.voc = new Map<String, Array<StackItem>>();
  }

  public function get(key: String): StackItem {
    // no such atom
    if( !voc.exists(key) )
      return Noop;
    // no atom definition
    if( voc.get(key).length <= 0 ) {
      voc.remove(key); // remove atoms without definitions
      return Noop;
    }
    return voc.get(key)[0]; // return first definition from possible many
  }

  // fluent
  public function set(key: String, value: StackItem): Vocabulary {
    if( !voc.exists(key) ) {
      var a = new Array<StackItem>();
      a.push(value);
      voc.set(key, a);
    }
    else
      voc.get(key).unshift(value);
    return this;
  }

  public inline function add(key: String, value: StackItem): Vocabulary {
    return this.set(key, value);
  }

  // fluent
  public function delete(key: String): Vocabulary {
    if( voc.exists(key) ) {
      voc.get(key).shift();
      // if it was the last definition - remove whole record
      if( voc.get(key).length <= 0 )
        voc.remove(key);
    }
    return this;
  }

  public inline function remove(key: String): Vocabulary {
    return this.delete(key);
  }


  // for standalone testing
  public static function main() {
    //
  }
}
