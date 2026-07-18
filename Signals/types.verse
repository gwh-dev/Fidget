using { /Verse.org/Simulation }
using { /Fortnite.com }

effect_without_value<public>:= class<final>(effect):
    Function<public>:type{_():void}
    EffectFn<override>():void = Function()

Effect<public>(Function:type{_():void}):cancelable =
    Sys := GetReactiveSystem()

    EffectNode := effect_without_value {
        Function := Function
        Flags := reactive_flags{IsWatching := true, IsRecursedCheck := true}
    }

    PrevSub := Sys.PreCreateEffect(EffectNode)
    Function()
    Sys.PostCreateEffect(EffectNode, PrevSub)
    if (not Sys.ActiveSub?):
        Sys.DrainDeferredCancels()
    EffectNode

effect_with_value<public>(t:type) := class<final>(effect):
    Value<public>:t
    Function<public>:type{_(:t):void}
    EffectFn<override>():void = Function(Value)

EffectWith<public>(Function:type{_(:t):void}, InValue:t where t:type):cancelable =
    Sys := GetReactiveSystem()

    EffectNode := effect_with_value(t) {
        Value := InValue
        Function := Function
        Flags := reactive_flags{IsWatching := true, IsRecursedCheck := true}
    }

    PrevSub := Sys.PreCreateEffect(EffectNode)
    Function(InValue)
    Sys.PostCreateEffect(EffectNode, PrevSub)
    if (not Sys.ActiveSub?):
        Sys.DrainDeferredCancels()
    EffectNode