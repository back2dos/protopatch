package protopatch;

class Patch {
    static function object(__target__, patches)
        return patchObject(__target__, patches, e -> fatalError('constructor not allowed', e.pos));

    static function replaceKeywords(e:Expr)
        return switch e {
            case macro super($a{args}):
                var args = [macro js.Lib.nativeThis].concat(args);
                macro (cast __old__).call($a{args});
            case { expr: EConst(CString(s, SingleQuotes)) }:
                s.formatString(e.pos).map(replaceKeywords);
            case macro this: macro (if (false) __target__ else js.Lib.nativeThis);
            default: e.map(replaceKeywords);
        }

    static public function patchObject(target, patches:Expr, ctor) {
        target = storeExpr(target);

        return switch patches.expr {
            case EObjectDecl(fields):
                var changes = [for (f in fields) switch f.field {
                    case 'constructor':

                        ctor(f.expr);
                        continue;

                    case name:

                        var patch = replaceKeywords(f.expr),
                            t = typeof(macro @:pos(f.expr.pos) $target.$name).toComplexType();

                        switch patch.expr {
                            case EObjectDecl(fields):

                                for (f in fields) {
                                    function as(ct)
                                        f.expr = macro @:pos(f.expr.pos) cast (${f.expr}:$ct);
                                    switch f.field {
                                        case 'get': as(macro : () -> $t);
                                        case 'set': as(macro : $t -> Void);
                                    }
                                }

                                macro @:pos(patch.pos) js.lib.Object.defineProperty(__target__, $v{name}, ($patch:js.lib.Object.ObjectPropertyDescriptor));
                            default:
                                if (t != null) patch = macro @:pos(patch.pos) ($patch:$t);
                                macro @:pos(patch.pos) {
                                    var __old__ = if (false) __target__.$name else (cast __target__).$name;
                                    (cast __target__).$name = ${patch};
                                }
                        }
                }];

                macro {
                    var __target__ = $target;
                    $b{changes};
                }
            default:
                fatalError('Object literal expected', patches.pos);
        }
    }
}