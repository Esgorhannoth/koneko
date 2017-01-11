package ;

enum StackObject {
  IntObj(i:Int);
  FloatObj(f:Float);
  StringObj(s:String);
  ArrayObj(a:Array<StackObject>);
}

class EnumArray {
  public static function main() {
    var i = IntObj(3);
    var f = FloatObj(3.14);
    var s = StringObj("esko goes home");
    var a = new Array<StackObject>();
    a.push(i);
    a.push(f);
    a.push(s);
    Sys.println(i);
    Sys.println(f);
    Sys.println(s);
    Sys.println(a);
  }
}
