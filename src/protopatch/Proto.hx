package protopatch;

class Proto {
  static public macro function patch();
  static public inline function get<A>(cls:Class<A>):A
    return untyped cls.prototype;
}