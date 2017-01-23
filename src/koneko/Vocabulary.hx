package koneko;

/**
  Contains mappings from atoms to array of `StackItem`s

  'Builtin' always available namespace
  'Prelude' always available if loaded
  Other namespaces available only if used with `using`
  e.g. ["ns1" "ns2"] using
  Current ns is always available and has priority
  If a word is defined both in ns1 and ns2, ns2 version will be used,
  as word resolution goes right to left
  You can still get ns1 version with full name `ns1:word`
  So check order is from first to last with `['ns1' 'ns2'] using`:
  - current NS  <- first
  - ns2
  - ns1
  - Prelude
  - Builtin     <- last
 **/
class Vocabulary {

  var voc: Map<String, StackItem>;

  static var builtin_ns  = "Builtin";

  var        prelude_ns  : String;
  var        main_ns     : String;
  public var current_ns(default, set): String;
  public var using_list(default, set): Array<String>;

  public function new(?main_ns_name: String, ?prelude_ns: String) {
    this.main_ns = null == main_ns_name ?
      "Main" : main_ns_name;
    this.prelude_ns = null == prelude_ns ?
      "Prelude" : prelude_ns;

    this.voc = new Map<String, StackItem>();
    this.using_list = new Array<String>();
    this.current_ns = main_ns;
  }

  /**
     No namespace may contain ":". They are automatically replaced by dots.
     Cannot set 'Builtin' ns
   **/
  public function set_current_ns(v: String): String {
    if( v == "Builtin" )
      throw "Cannot set 'Builtin' namespace as current or modify words in it";
    return this.current_ns = StringTools.replace(v, ":", ".");
  }

  /**
    No restrictions on setting for now
   **/ 
  public function set_using_list(v: Array<String>): Array<String> {
    return this.using_list = v;
  }

  /**
     Check this for existance across current, Prelude, Main and named definitions
     e.g. if current NS is "File" this won't find "Dir:list" given as "list",
     but WILL find as "Dir:list"
   **/
  // TODO need `using` version
  public function exists(key: String): Bool {
    return (this.voc.exists(key) ||           // with NS
        this.voc.exists(in_current(key)) ||   // in current NS
        this.voc.exists(in_prelude(key)) ||   // in Prelude
        this.voc.exists(in_builtins(key)));       // in Main
  }

  /**
    Used for defining new words
    Check this for definitions, as we define only in current NS
   **/
  public function exists_in_current(key: String): Bool {
    return ( this.voc.exists(in_current(key) ));
  }

  // TODO need `using` version
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
    if( this.voc.exists(in_builtins(key)) )
      return voc.get(in_builtins(key));
    return Noop; // unreachable
  }

  // fluent
  public function set(key: String, value: StackItem): Vocabulary {
    // always adds word in current namespace
    voc.set(in_current(key), value);
    return this;
  }

  // alias
  public inline function add(key: String, value: StackItem): Vocabulary {
    return this.set(key, value);
  }

  public inline function add_builtin(key: String, value: StackItem): Vocabulary {
    voc.set("Builtin:" + key, value);
    return this;
  }

  // fluent
  // TODO need `using` version
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

    if( this.voc.exists(in_builtins(key)) ) {
      voc.remove(in_builtins(key));
      return this;
    }

    return this;
  }

  // alias
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
    return prelude_ns + ":" + key;
  }

  // TODO ?? remove?
  public inline function in_builtins(key: String): String {
    return builtin_ns + ":" + key;
  }


  // for standalone testing
  public static function main() {
    //
  }
}
