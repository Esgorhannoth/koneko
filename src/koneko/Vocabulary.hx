package koneko;

/**
  Contains mappings from atoms to array of `StackItem`s
 **/
class Vocabulary {

  var voc: Map<String, StackItem>;

  var        prelude_ns_name: String;
  var        main_ns        : String;
  public var current_ns(default, set): String;

  public function new(?prelude_ns_name: String) {
    this.prelude_ns_name = null == prelude_ns_name ?
      "Prelude" : prelude_ns_name;
    this.voc = new Map<String, StackItem>();
    this.main_ns = "Main";
    this.current_ns = main_ns;
  }

  /**
     No namespace may contain ":". They are automatically replaced by dots.
   **/
  public function set_current_ns(v: String): String {
    return this.current_ns = StringTools.replace(v, ":", ".");
  }

  /**
     Check this for existance across current, Prelude, Main and named definitions
     e.g. if current NS is "File" this won't find "Dir:list" given as "list",
     but WILL find as "Dir:list"
   **/
  public function exists(key: String): Bool {
    return (this.voc.exists(key) ||           // with NS
        this.voc.exists(in_current(key)) ||   // in current NS
        this.voc.exists(in_prelude(key)) ||   // in Prelude
        this.voc.exists(in_main(key)));       // in Main
  }

  /**
    Check this for definitions, as we define only in current NS
   **/
  public function exists_in_current(key: String): Bool {
    return ( this.voc.exists(in_current(key) ));
  }

  public function get(key: String): StackItem {
    // no such atom
    if( !this.exists(key) )
      return Noop;

    // with namespace
    if( this.voc.exists(key) )
      return voc.get(key);
    // in current namespace
    if( this.voc.exists(in_current(key)) )
      return voc.get(in_current(key));
    // in Prelude
    if( this.voc.exists(in_prelude(key)) )
      return voc.get(in_prelude(key));
    // in Main
    if( this.voc.exists(in_main(key)) )
      return voc.get(in_main(key));
    return Noop; // unreachable
  }

  // fluent
  public function set(key: String, value: StackItem): Vocabulary {
    // always adds word in current namespace
    voc.set(in_current(key), value);
    return this;
  }

  public inline function add(key: String, value: StackItem): Vocabulary {
    return this.set(key, value);
  }

  // fluent
  public function delete(key: String): Vocabulary {
    if( !this.exists(key) )
      return this;

    if( this.voc.exists(key) ) {
      voc.remove(key);
      return this;
    }

    if( this.voc.exists(in_current(key)) ) {
      voc.remove(in_current(key));
      return this;
    }

    if( this.voc.exists(in_prelude(key)) ) {
      voc.remove(in_prelude(key));
      return this;
    }

    if( this.voc.exists(in_main(key)) ) {
      voc.remove(in_main(key));
      return this;
    }

    return this;
  }

  public inline function remove(key: String): Vocabulary {
    return this.delete(key);
  }

  public inline function keys(): Iterator<String> {
    return this.voc.keys();
  }

  public inline function in_current(key: String): String {
    return current_ns + ":" + key;
  }

  public inline function in_prelude(key: String): String {
    return prelude_ns_name + ":" + key;
  }

  public inline function in_main(key: String): String {
    return main_ns + ":" + key;
  }


  // for standalone testing
  public static function main() {
    //
  }
}
