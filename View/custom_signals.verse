using { /Verse.org/Simulation }

using { Signals }

opacity<public> := type{_X:float where 0.000000 <= _X, _X <= 1.000000}

signal_tiling <public>:= class<final>(signal(tiling)):
    @editable
    var Value<public>:tiling = tiling.Stretch
    var PendingValue<private>:tiling = tiling.Stretch
    GetCurrentValue<override>()<transacts>:tiling = Value
    SetCurrentValue<override>(New:tiling)<transacts>:void = set Value = New
    GetPendingValue<override>()<transacts>:tiling = PendingValue
    SetPendingValue<override>(New:tiling)<transacts>:void = set PendingValue = New

computed_tiling<public>:= class<final>(computed(tiling)):
    Function<public>:computed_function(tiling)
    @editable
    var Value<public>:tiling = tiling.Stretch
    GetCurrentValue<override>()<transacts>:tiling = Value
    SetCurrentValue<override>(New:tiling)<transacts>:void = set Value = New
    GetComputedValue<override>()<transacts>:tiling = Function()

signal_justification<public>:= class<final>(signal(justification)):
    @editable
    var Value<public>:justification = justification.Left
    var PendingValue<private>:justification = justification.Left
    GetCurrentValue<override>()<transacts>:justification = Value
    SetCurrentValue<override>(New:justification)<transacts>:void = set Value = New
    GetPendingValue<override>()<transacts>:justification = PendingValue
    SetPendingValue<override>(New:justification)<transacts>:void = set PendingValue = New

computed_justification<public>:= class<final>(computed(justification)):
    Function<public>:computed_function(justification)
    @editable
    var Value<public>:justification = justification.Left
    GetCurrentValue<override>()<transacts>:justification = Value
    SetCurrentValue<override>(New:justification)<transacts>:void = set Value = New
    GetComputedValue<override>()<transacts>:justification = Function()

signal_overflow_policy<public>:= class<final>(signal(overflow_policy)):
    @editable
    var Value<public>:overflow_policy = overflow_policy.Clip
    var PendingValue<private>:overflow_policy = overflow_policy.Clip
    GetCurrentValue<override>()<transacts>:overflow_policy = Value
    SetCurrentValue<override>(New:overflow_policy)<transacts>:void = set Value = New
    GetPendingValue<override>()<transacts>:overflow_policy = PendingValue
    SetPendingValue<override>(New:overflow_policy)<transacts>:void = set PendingValue = New

computed_overflow_policy<public>:= class<final>(computed(overflow_policy)):
    Function<public>:computed_function(overflow_policy)
    @editable
    var Value<public>:overflow_policy = overflow_policy.Clip
    GetCurrentValue<override>()<transacts>:overflow_policy = Value
    SetCurrentValue<override>(New:overflow_policy)<transacts>:void = set Value = New
    GetComputedValue<override>()<transacts>:overflow_policy = Function()

signal_opacity<public>:= class<final>(signal(opacity)):
    @editable
    var Value<public>:opacity = 1.0
    var PendingValue<private>:opacity = 1.0
    GetCurrentValue<override>()<transacts>:opacity = Value
    SetCurrentValue<override>(New:opacity)<transacts>:void = set Value = New
    GetPendingValue<override>()<transacts>:opacity = PendingValue
    SetPendingValue<override>(New:opacity)<transacts>:void = set PendingValue = New

computed_opacity<public>:= class<final>(computed(opacity)):
    Function<public>:computed_function(opacity)
    @editable
    var Value<public>:opacity = 1.0
    GetCurrentValue<override>()<transacts>:opacity = Value
    SetCurrentValue<override>(New:opacity)<transacts>:void = set Value = New
    GetComputedValue<override>()<transacts>:opacity = Function()

ComputedOpacity<public><constructor>(Function()<transacts>:opacity)<transacts>:=
    computed_opacity {Value := 1.0, Function := Function}
