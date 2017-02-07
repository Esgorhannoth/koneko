package koneko;

import neko.vm.Loader;
import neko.vm.Module;
import koneko.Typedefs;

class ModLoader {
  static function getModule(name:String):Dynamic {
    var module = Loader.local().loadModule(name);
    var classes : Dynamic = module.exportsTable().__classes;
    return Type.createInstance(classes.koneko.KonekoMod, []);
  }

  public static function add_to(ws:Vocabulary, mod_name:String): Vocabulary
  {
    try {
      clear_cache(mod_name); // for hot reloading

      var body = getModule(mod_name);
      var ns   = body.get_namespace();
      var from:Voc = body.get_words();

      for( k in from.keys() ) {
        ws.add_to_namespace(k, BuiltinSI(from.get(k)), ns);
      }
    }
    catch(e: Dynamic) {
      throw KonekoException.Custom('Error loading module "${mod_name}" : $e');
    }
    return ws;
  }

  static inline function clear_cache(mod_name:String) {
    Loader.local().setCache(mod_name, null);
  }
}
