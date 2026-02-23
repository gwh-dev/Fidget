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
    EffectNode

signal_int<public>:= class<final>(signal(int)):
    @editable
    var Value<public>:int
    var PendingValue<private>:int = 0
    GetCurrentValue<override>()<transacts>:int = Value
    SetCurrentValue<override>(New:int)<transacts>:void = set Value = New
    GetPendingValue<override>()<transacts>:int = PendingValue
    SetPendingValue<override>(New:int)<transacts>:void = set PendingValue = New

signal_float<public>:= class<final>(signal(float)):
    @editable
    var Value<public>:float
    var PendingValue<private>:float = 0.0
    GetCurrentValue<override>()<transacts>:float = Value
    SetCurrentValue<override>(New:float)<transacts>:void = set Value = New
    GetPendingValue<override>()<transacts>:float = PendingValue
    SetPendingValue<override>(New:float)<transacts>:void = set PendingValue = New

signal_logic<public>:= class<final>(signal(logic)):
    @editable
    var Value<public>:logic
    var PendingValue<private>:logic = false
    GetCurrentValue<override>()<transacts>:logic = Value
    SetCurrentValue<override>(New:logic)<transacts>:void = set Value = New
    GetPendingValue<override>()<transacts>:logic = PendingValue
    SetPendingValue<override>(New:logic)<transacts>:void = set PendingValue = New

signal_string<public>:= class<final>(signal(string)):
    @editable
    var Value<public>:string
    var PendingValue<private>:string = ""
    GetCurrentValue<override>()<transacts>:string = Value
    SetCurrentValue<override>(New:string)<transacts>:void = set Value = New
    GetPendingValue<override>()<transacts>:string = PendingValue
    SetPendingValue<override>(New:string)<transacts>:void = set PendingValue = New


# --- UPDATED COMPUTED CLASSES ---

computed_int<public>:= class<final>(computed(int)):
    Function<public>:computed_function(int)

    @editable
    var Value<public>:int
    GetCurrentValue<override>()<transacts>:int = Value
    SetCurrentValue<override>(New:int)<transacts>:void = set Value = New
    GetComputedValue<override>()<transacts>:int = Function()

ComputedInt<public><constructor>(Function()<transacts>:int)<transacts>:=
    computed_int {Value := 0, Function := Function}

computed_float<public>:= class<final>(computed(float)):
    Function<public>:computed_function(float)

    @editable
    var Value<public>:float
    GetCurrentValue<override>()<transacts>:float = Value
    SetCurrentValue<override>(New:float)<transacts>:void = set Value = New
    GetComputedValue<override>()<transacts>:float = Function()

ComputedFloat<public><constructor>(Function()<transacts>:float)<transacts>:=
    computed_float {Value := 0.0, Function := Function}

computed_string<public>:= class<final>(computed(string)):
    Function<public>:computed_function(string)

    @editable
    var Value<public>:string
    GetCurrentValue<override>()<transacts>:string = Value
    SetCurrentValue<override>(New:string)<transacts>:void = set Value = New
    GetComputedValue<override>()<transacts>:string = Function()

ComputedString<public><constructor>(Function()<transacts>:string)<transacts>:=
    computed_string {Value := "", Function := Function}

computed_logic<public>:= class<final>(computed(logic)):
    Function<public>:computed_function(logic)

    @editable
    var Value<public>:logic
    GetCurrentValue<override>()<transacts>:logic = Value
    SetCurrentValue<override>(New:logic)<transacts>:void = set Value = New
    GetComputedValue<override>()<transacts>:logic = Function()

ComputedLogic<public><constructor>(Function()<transacts>:logic)<transacts>:=
    computed_logic {Value := true, Function := Function}

Math<public>:= module:
    using { /Verse.org/SpatialMath }

    signal_vector3<public>:= class<final>(signal(vector3)):
        @editable
        var Value<public>:vector3
        var PendingValue<private>:vector3 = vector3{}
        GetCurrentValue<override>()<transacts>:vector3 = Value
        SetCurrentValue<override>(New:vector3)<transacts>:void = set Value = New
        GetPendingValue<override>()<transacts>:vector3 = PendingValue
        SetPendingValue<override>(New:vector3)<transacts>:void = set PendingValue = New

    computed_vector3<public> := class<final>(computed(vector3)):
        Function<public>:computed_function(vector3)

        @editable
        var Value<public>:vector3
        GetCurrentValue<override>()<transacts>:vector3 = Value
        SetCurrentValue<override>(New:vector3)<transacts>:void = set Value = New
        GetComputedValue<override>()<transacts>:vector3 = Function()

    ComputedVector3<public><constructor>(Function()<transacts>:vector3)<transacts>:=
        computed_vector3 { Value := vector3{}, Function := Function}

Colors<public>:= module:
    using { /Verse.org/Colors }

    signal_color<public>:= class<final>(signal(color)):
        @editable
        var Value<public>:color
        var PendingValue<private>:color = color{}
        GetCurrentValue<override>()<transacts>:color = Value
        SetCurrentValue<override>(New:color)<transacts>:void = set Value = New
        GetPendingValue<override>()<transacts>:color = PendingValue
        SetPendingValue<override>(New:color)<transacts>:void = set PendingValue = New

    signal_color_alpha<public>:= class<final>(signal(color_alpha)):
        @editable
        var Value<public>:color_alpha
        var PendingValue<private>:color_alpha = color_alpha{}
        GetCurrentValue<override>()<transacts>:color_alpha = Value
        SetCurrentValue<override>(New:color_alpha)<transacts>:void = set Value = New
        GetPendingValue<override>()<transacts>:color_alpha = PendingValue
        SetPendingValue<override>(New:color_alpha)<transacts>:void = set PendingValue = New

    computed_color<public>:= class<final>(computed(color)):
        Function<public>:computed_function(color)

        @editable
        var Value<public>:color
        GetCurrentValue<override>()<transacts>:color = Value
        SetCurrentValue<override>(New:color)<transacts>:void = set Value = New
        GetComputedValue<override>()<transacts>:color = Function()

    ComputedColor<public><constructor>(Function()<transacts>:color)<transacts>:=
        computed_color {Value := color{}, Function := Function}

    computed_color_alpha<public>:= class<final>(computed(color_alpha)):
        Function<public>:computed_function(color_alpha)

        @editable
        var Value<public>:color_alpha
        GetCurrentValue<override>()<transacts>:color_alpha = Value
        SetCurrentValue<override>(New:color_alpha)<transacts>:void = set Value = New
        GetComputedValue<override>()<transacts>:color_alpha = Function()
    
    ComputedColorAlpha<public><constructor>(Function()<transacts>:color_alpha)<transacts>:=
        computed_color_alpha {Value := color_alpha{}, Function := Function}