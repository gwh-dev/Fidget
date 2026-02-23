using { /Verse.org/Simulation }

signal_get<public>(t:subtype(comparable)) := interface<internal>:
    Get<public>()<transacts>:t

signal_set<public>(t:subtype(comparable)) := interface<internal>:
    Set<public>(:t):void

signal<public>(t:subtype(comparable)) := class<abstract>(reactive_node, signal_get(t), signal_set(t)):
    GetCurrentValue<public>()<transacts>:t
    SetCurrentValue<public>(:t)<transacts>:void

    GetPendingValue<public>()<transacts>:t
    SetPendingValue<public>(:t)<transacts>:void

    block:
        SetPendingValue(GetCurrentValue())
        set Flags.IsMutable = true

    Update<final><override>()<transacts><decides>:void =
        GetCurrentValue() <> GetPendingValue()
        SetCurrentValue(GetPendingValue())

    Get<final><override>()<transacts>:t =
        Sys := GetReactiveSystem()

        if (Flags.IsDirty?):
            if (Update[]):
                if (SubsLink := Subs?):
                    Sys.ShallowPropagate(SubsLink)

        # Walk up to find a mutable/watching subscriber
        var MaybeSub : ?reactive_node = Sys.ActiveSub
        loop:
            if (Sub := MaybeSub?):
                if (Sub.Flags.IsMutable? or Sub.Flags.IsWatching?):
                    Sys.Link(Self, Sub, Sys.Cycle)
                    break
                if (SubLink := Sub.Subs?):
                    set MaybeSub = option{SubLink.Sub}
                else:
                    break
            else:
                break

        GetCurrentValue()

    Set<final><override>(New:t):void =
        if (GetPendingValue() <> New):
            Sys := GetReactiveSystem()
            Result := InternalSet(Sys, New)
            if (Result?) then:
                Sys.Flush()

    InternalSet<final><private>(Sys:reactive_system, New:t)<transacts>:logic =
        SetPendingValue(New)
        set Flags = reactive_flags{IsMutable := true, IsDirty := true}
        if (SubsLink := Subs?):
            Sys.Propagate(SubsLink)
            if (Sys.BatchDepth = 0):
                return true
        false

computed_function<public>(t:subtype(comparable)) := type{_()<transacts>:t}
computed<public>(t:subtype(comparable)) := class<abstract>(reactive_node, signal_get(t)):
    GetCurrentValue<public>()<transacts>:t
    SetCurrentValue<public>(:t)<transacts>:void
    GetComputedValue<public>()<transacts>:t

    Update<final><override>()<transacts><decides>:void =
        # Called by CheckDirty — do the actual re-evaluation
        Sys := GetReactiveSystem()
        OldValue := GetCurrentValue()
        set Sys.Cycle = Sys.Cycle + 1
        set DepsTail = false
        set Flags = reactive_flags{IsMutable := true, IsRecursedCheck := true}
        PrevSub := Sys.SetActiveSub(option{Self})
        SetCurrentValue(GetComputedValue())
        set Sys.ActiveSub = PrevSub
        set Flags.IsRecursedCheck = false
        Sys.PurgeDeps(Self)

        OldValue <> GetCurrentValue()

    UpdateComputed<final><public>()<transacts>:logic =
        Sys := GetReactiveSystem()
        set Sys.Cycle = Sys.Cycle + 1
        set DepsTail = false
        set Flags = reactive_flags{IsMutable := true, IsRecursedCheck := true}
        PrevSub := Sys.SetActiveSub(option{Self})
        OldValue := GetCurrentValue()
        SetCurrentValue(GetComputedValue())
        set Sys.ActiveSub = PrevSub
        set Flags.IsRecursedCheck = false
        Sys.PurgeDeps(Self)
        if (OldValue <> GetCurrentValue()) then true else false

    Get<final><override>()<transacts>:t =
        Sys := GetReactiveSystem()

        var NeedUpdate : logic = false

        if (Flags.IsDirty?):
            set NeedUpdate = true
        else if (Flags.IsPending?):
            if (DepLink := Deps?):
                DirtyResult := Sys.CheckDirty(DepLink, Self)
                if (DirtyResult?):
                    set NeedUpdate = true
                else:
                    set Flags.IsPending = false

        if (NeedUpdate?):
            Result := UpdateComputed()
            if (Result?):
                if (SubsLink := Subs?):
                    Sys.ShallowPropagate(SubsLink)
        else if (not Flags.IsMutable?, not Flags.IsWatching?, not Flags.IsRecursedCheck?, not Flags.IsRecursed?, not Flags.IsDirty?, not Flags.IsPending?):
            # First access — lazy init
            set Flags = reactive_flags{IsMutable := true, IsRecursedCheck := true}
            PrevSub := Sys.SetActiveSub(option{Self})
            SetCurrentValue(GetComputedValue())
            set Sys.ActiveSub = PrevSub
            set Flags.IsRecursedCheck = false

        # Link to active subscriber
        if (Sub := Sys.ActiveSub?):
            Sys.Link(Self, Sub, Sys.Cycle)

        GetCurrentValue()

effect<public>:= class<abstract>(reactive_node, cancelable):
    Run<public>():void =
        GetReactiveSystem().RunEffect(Self)

    Cancel<override>()<transacts>:void =
        Sys := GetReactiveSystem()
        set DepsTail = false
        set Flags = reactive_flags{}
        Sys.PurgeDeps(Self)
        if (SubLink := Subs?):
            Sys.Unlink(SubLink)

CreateEffect<public>(EffectNode:effect, Function:type{_(:t):void}, Input:t where t:type):void =
    Sys := GetReactiveSystem()

    PrevSub := Sys.PreCreateEffect(EffectNode)
    Function(Input)
    Sys.PostCreateEffect(EffectNode, PrevSub)

# ==========================================================
# ADVANCED SIGNAL UTILITIES (Untrack, Peek, Batch)
# ==========================================================

# Reads a signal without establishing a dependency in the current topological scope.
Peek<public>(Signal:signal_get(t) where t:subtype(comparable))<transacts>:t =
    Sys := GetReactiveSystem()
    PrevSub := Sys.SetActiveSub(false)
    Result := Signal.Get()
    Sys.SetActiveSub(PrevSub)
    Result

# Runs a <transacts> function without establishing any reactive dependencies.
# Useful inside Computed signals where you need to check a value without subscribing.
Untrack<public>(Function:type{_()<transacts>:t} where t:type)<transacts>:t =
    Sys := GetReactiveSystem()
    PrevSub := Sys.SetActiveSub(false)
    Result := Function()
    Sys.SetActiveSub(PrevSub)
    Result

# Runs an Action with side-effects without establishing any reactive dependencies.
# Useful inside Effects when making out-of-band state queries.
UntrackAction<public>(Action:type{_():void}):void =
    Sys := GetReactiveSystem()
    PrevSub := Sys.SetActiveSub(false)
    Action()
    Sys.SetActiveSub(PrevSub)

# Groups multiple signal Set() updates together, guaranteeing that active Effects
# are only executed ONCE after all mutations have completed.
Batch<public>(Action:type{_():void}):void =
    Sys := GetReactiveSystem()
    Sys.BeginBatch()
    Action()
    Sys.EndBatch()
    
    # Flush pending effects if we've completely exited the outermost batch
    if (Sys.BatchDepth = 0):
        Sys.Flush()
