package protopatch;

class Proto {

    static function patch(cls, patches:Expr) {
        var ctor = null;
        var ret = Patch.patchObject(
            macro protopatch.Proto.get($cls),
            patches,
            e -> ctor = e
        );

        return switch ctor {
            case null: ret;
            default:
                switch typeof(macro $cls.new) {
                    case TFun(args, ret):

                        var clsName = switch ret.getClass().meta.extract(':native') {
                            case []: fatalError('Not applicable to classes without @:native', cls.pos);
                            case [{ params: [macro $v{(v:String)} ] }]: v;
                            case v: fatalError('Invalid or duplicate @:native directives', v[0].pos);
                        }

                        var self = ret.toComplexType();

                        function replaceSuper(e:Expr)
                            return switch e {
                                case macro super($a{args}):
                                    var args = [macro __old__].concat(args);
                                    macro (js.Syntax.construct($a{args}):$self);
                                default:
                                    e.map(replaceSuper);
                            }

                        macro {
                            var __old__ = $cls;
                            var nu = if (false) $cls.new else ${replaceSuper(ctor)};
                            untyped $i{clsName} = nu;
                        }
                    default:
                        throw 'assert';
                }
        }
    }
}