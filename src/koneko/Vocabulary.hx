package koneko;

using  koneko.StackItem;

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
  - full-path check
  - current NS  <- first
  - ns2
  - ns1
  - Prelude
  - Builtin     <- last
 **/
class Vocabulary {

  var voc: Map<String, StackItem>;

  static var ns_delim = "/";  // namespace delimiter

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
  public function exists(key: String): Bool {
    return find_ns(key) != null;
  }

  function find_ns(key: String): String {
    // full name
    if( this.voc.exists(key) ) {
      var idx = key.indexOf(ns_delim);
      return key.substr(idx);
    }

    if( this.voc.exists(in_current(key) ))   // in current NS
      return current_ns;
    for( ns in this.using_list )
      if( this.voc.exists('${ns}${ns_delim}${key}') )
        return ns;

    if( this.voc.exists(in_prelude(key) ))   // in Prelude
      return prelude_ns;
    if( this.voc.exists(in_builtins(key) ))  // in Builtin
      return builtin_ns;
    return null; // does not exist TODO use haxe.ds.Option instead?
  }

  /**
    Used for defining new words
    Check this for definitions, as we define only in current NS
   **/
  public function exists_in_current(key: String): Bool {
    return ( this.voc.exists(in_current(key) ));
  }

  public function get(key: String, ?given_ns: String): StackItem {
    // just get it
    if( given_ns != null )
      return voc.get('${given_ns}${ns_delim}${key}');

    // no such atom
    var ns = this.find_ns(key);
    if( ns == null )
      return Noop;

    // full name with namespace
    if( this.voc.exists(key) )
      return voc.get(key);

    return voc.get('${ns}${ns_delim}${key}');
    return Noop; // unreachable
  }

  // fluent
  public function set(key: String, value: StackItem): Vocabulary {
    // always adds word in current namespace
    voc.set(in_current(key), value);
    return this;
  }

  // alias for set
  public inline function add(key: String, value: StackItem): Vocabulary {
    return this.set(key, value);
  }

  public inline function add_to_namespace(key: String, value: StackItem, ns: String): Vocabulary {
    voc.set('${ns}${ns_delim}${key}', value);
    return this;
  }
  public inline function add_builtin(key: String, value: StackItem): Vocabulary {
    this.add_to_namespace(key, value, "Builtin");
    return this;
  }

  // fluent
  public function delete(key: String): Vocabulary {
    var ns = find_ns(key);
    // no such word
    if( ns == null )
      return this;

    // full path with NS
    if( this.voc.exists(key) ) {
      voc.remove(key);
      return this;
    }

    if( ns == builtin_ns )
      throw "Cannot remove Builtin word";
    voc.remove('${ns}${ns_delim}${key}');

    return this;
  }

  // alias
  public inline function remove(key: String): Vocabulary {
    return this.delete(key);
  }

  public function get_definition(key: String): String {
    var ns = find_ns(key);
    if( null == ns )
      return 'No such word ${key}';

    if( ns == builtin_ns )
      return '${key} is Builtin word';

    return this.get(key, ns).toString();
  }

  public inline function keys(): Iterator<String> {
    return this.voc.keys();
  }

  public inline function in_current(key: String): String {
    return current_ns + ns_delim + key;
  }

  public inline function in_prelude(key: String): String {
    return prelude_ns + ns_delim + key;
  }

  public inline function in_builtins(key: String): String {
    return builtin_ns + ns_delim + key;
  }

  public inline function get_delim(): String {
    return ns_delim;
  }


  // for standalone testing
  public static function main() {
    //
  }
}
