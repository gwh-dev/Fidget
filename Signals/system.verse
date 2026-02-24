using { /Verse.org/Simulation }

var ReactiveSystem:weak_map(session, reactive_system) = map{}

GetReactiveSystem<internal>()<transacts>:reactive_system =
    if (Sys := ReactiveSystem[GetSession()]):
        Sys
    else:
        NewSys := reactive_system {}
        if. set ReactiveSystem[GetSession()] = NewSys
        NewSys

reactive_flags<internal>:= struct<concrete><computes>:
    IsMutable<public>:logic = false
    IsWatching<public>:logic = false
    IsRecursedCheck<public>:logic = false
    IsRecursed<public>:logic = false
    IsDirty<public>:logic = false
    IsPending<public>:logic = false

reactive_link<internal>:= class<final><unique><transacts>:
    Dep<public>:reactive_node
    Sub<public>:reactive_node
    var PrevSub<public>:?reactive_link = false
    var NextSub<public>:?reactive_link = false
    var PrevDep<public>:?reactive_link = false
    var NextDep<public>:?reactive_link = false

    var Version<public>:int = 0

reactive_node<internal>:= class<unique><abstract><transacts>:
    var Deps<public>:?reactive_link = false
    var DepsTail<public>:?reactive_link = false
    var Subs<public>:?reactive_link = false
    var SubsTail<public>:?reactive_link = false
    var Flags<public>:reactive_flags = reactive_flags{}

    # Override in subtypes. Success = value changed.
    Update<public>()<transacts><decides>:void = false

    # Override in effect subtypes to provide the side-effect callback.
    EffectFn<public>():void = {}

stack<internal>:= class<final><computes>:
    Value:?reactive_link
    Prev:?stack = false

reactive_system<internal>:= class<final><concrete><transacts>:
    var ActiveSub:?reactive_node = false
    var Cycle:int = 0
    var BatchDepth:int = 0
    var NotifyIndex:int = 0
    var QueuedEffects:[]?reactive_node = array{}
    var QueuedLength:int = 0

    SetActiveSub(Sub:?reactive_node)<transacts>:?reactive_node =
        PrevSub := ActiveSub
        set ActiveSub = Sub
        PrevSub

    Link(Dep:reactive_node, Sub:reactive_node, InVersion:int)<transacts>:void =
        PrevDep := Sub.DepsTail

        if (PrevDepLink := PrevDep?, PrevDepLink.Dep = Dep):
            return

        NextDep := if (PrevDepLink := PrevDep?) then PrevDepLink.NextDep else Sub.Deps

        if (NextDepLink := NextDep?, NextDepLink.Dep = Dep):
            set NextDepLink.Version = InVersion
            set Sub.DepsTail = option{NextDepLink}
            return

        PrevSub := Dep.SubsTail

        if (PrevSubLink := PrevSub?, PrevSubLink.Version = InVersion, PrevSubLink.Sub = Sub):
            return

        NewLink := reactive_link{
            Version := InVersion
            Dep := Dep
            Sub := Sub
            PrevDep := PrevDep
            NextDep := NextDep
            PrevSub := PrevSub
        }
        set Sub.DepsTail = option{NewLink}
        set Dep.SubsTail = option{NewLink}

        if (NextDepLink := NextDep?):
            set NextDepLink.PrevDep = option{NewLink}

        if (PrevDepLink := PrevDep?):
            set PrevDepLink.NextDep = option{NewLink}
        else:
            set Sub.Deps = option{NewLink}

        if (PrevSubLink := PrevSub?):
            set PrevSubLink.NextSub = option{NewLink}
        else:
            set Dep.Subs = option{NewLink}

    Unlink(InLink:reactive_link)<transacts>:?reactive_link =
        Unlink(InLink, InLink.Sub)

    Unlink(InLink:reactive_link, InSub:reactive_node)<transacts>:?reactive_link =
        Dep := InLink.Dep
        PrevDep := InLink.PrevDep
        NextDep := InLink.NextDep
        NextSubVal := InLink.NextSub
        PrevSubVal := InLink.PrevSub

        if (NextDepLink := NextDep?):
            set NextDepLink.PrevDep = PrevDep
        else:
            set InSub.DepsTail = PrevDep

        if (PrevDepLink := PrevDep?):
            set PrevDepLink.NextDep = NextDep
        else:
            set InSub.Deps = NextDep

        if (NextSubLink := NextSubVal?):
            set NextSubLink.PrevSub = PrevSubVal
        else:
            set Dep.SubsTail = PrevSubVal

        if (PrevSubLink := PrevSubVal?):
            set PrevSubLink.NextSub = NextSubVal
        else:
            set Dep.Subs = NextSubVal
            if (not NextSubVal?):
                OnUnwatched(Dep)

        NextDep

    IsValidLink(CheckLink:reactive_link, Sub:reactive_node)<transacts><decides>:void =
        var MaybeLink:?reactive_link = Sub.DepsTail
        loop:
            if (L := MaybeLink?):
                if (L = CheckLink):
                    break
                set MaybeLink = L.PrevDep
            else:
                false

    Propagate(InLink:reactive_link)<transacts>:void =
        var CurLink:reactive_link = InLink
        var Next:?reactive_link = InLink.NextSub
        var StackTop:?stack = false

        loop:
            Sub := CurLink.Sub
            OrigFlags := Sub.Flags
            var ShouldNotify:logic = false
            var ShouldRecurse:logic = false

            if (not OrigFlags.IsRecursedCheck?, not OrigFlags.IsRecursed?, not OrigFlags.IsDirty?, not OrigFlags.IsPending?):
                # Branch 1: clean node → mark pending
                set Sub.Flags.IsPending = true
                set ShouldNotify = OrigFlags.IsWatching
                set ShouldRecurse = OrigFlags.IsMutable
            else if (not OrigFlags.IsRecursedCheck?, not OrigFlags.IsRecursed?):
                # Branch 2: already dirty/pending, no recurse flags → skip
                block {}
            else if (not OrigFlags.IsRecursedCheck?):
                # Branch 3: has Recursed but not RecursedCheck
                set Sub.Flags.IsRecursed = false
                set Sub.Flags.IsPending = true
                set ShouldNotify = OrigFlags.IsWatching
                set ShouldRecurse = OrigFlags.IsMutable
            else if (not OrigFlags.IsDirty?, not OrigFlags.IsPending?, IsValidLink[CurLink, Sub]):
                # Branch 4: RecursedCheck + valid link
                set Sub.Flags.IsRecursed = true
                set Sub.Flags.IsPending = true
                set ShouldRecurse = OrigFlags.IsMutable
            # else:
                # # Branch 5: skip
                # block {}

            if (ShouldNotify?):
                OnNotify(Sub)

            var Advanced : logic = false

            if (ShouldRecurse?):
                if (SubSubs := Sub.Subs?):
                    set CurLink = SubSubs
                    if (NextSubLink := SubSubs.NextSub?):
                        set StackTop = option{stack {Value := Next, Prev := StackTop}}
                        set Next = option{NextSubLink}
                    set Advanced = true

            if (not Advanced?):
                if (NextLink := Next?):
                    set CurLink = NextLink
                    set Next = NextLink.NextSub
                    set Advanced = true

            if (not Advanced?):
                var FoundInStack : logic = false
                loop:
                    if (Top := StackTop?):
                        set StackTop = Top.Prev
                        if (StackLink := Top.Value?):
                            set CurLink = StackLink
                            set Next = StackLink.NextSub
                            set FoundInStack = true
                            break
                    else:
                        break
                if (not FoundInStack?):
                    break

    CheckDirty(InLink:reactive_link, InSub:reactive_node)<transacts>:logic =
        var CurLink:reactive_link = InLink
        var Sub:reactive_node = InSub
        var StackTop:?stack = false
        var CheckDepth:int = 0
        var Dirty:logic = false

        loop:
            Dep := CurLink.Dep
            DepFlags := Dep.Flags
            var ContinueOuter : logic = false

            if (Sub.Flags.IsDirty?):
                set Dirty = true
            else if (DepFlags.IsMutable?, DepFlags.IsDirty?):
                if (Dep.Update[]):
                    if (DepSubs := Dep.Subs?):
                        if (DepSubs.NextSub?):
                            ShallowPropagate(DepSubs)
                    set Dirty = true
            else if (DepFlags.IsMutable?, DepFlags.IsPending?):
                HasSiblings := if (CurLink.NextSub?) then true else if (CurLink.PrevSub?) then true else false
                if (HasSiblings?):
                    set StackTop = option{stack{Value := option{CurLink}, Prev := StackTop}}
                if (DepDeps := Dep.Deps?):
                    set CurLink = DepDeps
                set Sub = Dep
                set CheckDepth = CheckDepth + 1
                set ContinueOuter = true

            if (not ContinueOuter?):
                if (not Dirty?):
                    if (NextDepLink := CurLink.NextDep?):
                        set CurLink = NextDepLink
                        set ContinueOuter = true

            if (not ContinueOuter?):
                loop:
                    if (CheckDepth > 0):
                        set CheckDepth = CheckDepth - 1
                        if (FirstSub := Sub.Subs?):
                            HasMultipleSubs := if (FirstSub.NextSub?) then true else false

                            if (HasMultipleSubs?):
                                if (Top := StackTop?):
                                    if (TopLink := Top.Value?):
                                        set CurLink = TopLink
                                    set StackTop = Top.Prev
                            else:
                                set CurLink = FirstSub

                            var SkipRest : logic = false
                            if (Dirty?):
                                if (Sub.Update[]):
                                    if (HasMultipleSubs?):
                                        ShallowPropagate(FirstSub)
                                    set Sub = CurLink.Sub
                                    set SkipRest = true
                                else:
                                    set Dirty = false
                            else:
                                set Sub.Flags.IsPending = false

                            if (not SkipRest?):
                                set Sub = CurLink.Sub
                                if (NextDepLink := CurLink.NextDep?):
                                    set CurLink = NextDepLink
                                    set ContinueOuter = true
                                    break
                    else:
                        break

                if (not ContinueOuter?):
                    break

        Dirty

    ShallowPropagate(InLink:reactive_link)<transacts>:void =
        var MaybeLink:?reactive_link = option{InLink}
        loop:
            if (L := MaybeLink?):
                Sub := L.Sub
                SubFlags := Sub.Flags
                if (SubFlags.IsPending?, not SubFlags.IsDirty?):
                    set Sub.Flags.IsDirty = true
                    if (SubFlags.IsWatching?, not SubFlags.IsRecursedCheck?):
                        OnNotify(Sub)
                set MaybeLink = L.NextSub
            else:
                break

    OnNotify(InEffect:reactive_node)<transacts>:void =
        var MaybeEffect:?reactive_node = option{InEffect}
        var NewEffects:[]reactive_node = array{}

        loop:
            if (E := MaybeEffect?):
                set NewEffects = NewEffects + array{E}
                set E.Flags.IsWatching = false
                if (SubLink := E.Subs?):
                    NextSub := SubLink.Sub
                    if (NextSub.Flags.IsWatching?):
                        set MaybeEffect = option{NextSub}
                    else:
                        set MaybeEffect = false
                else:
                    set MaybeEffect = false
            else:
                break

        var Reversed : []?reactive_node = array{}
        var I : int = NewEffects.Length - 1
        loop:
            if (I >= 0):
                if (E := NewEffects[I]):
                    set Reversed = Reversed + array{option{E}}
                set I = I - 1
            else:
                break

        set QueuedEffects = QueuedEffects + Reversed
        set QueuedLength = QueuedLength + Reversed.Length

    OnUnwatched(Node:reactive_node)<transacts>:void =
        if (not Node.Flags.IsMutable?):
            # Effect scope cleanup
            set Node.DepsTail = false
            set Node.Flags = reactive_flags{}
            PurgeDeps(Node)
            if (SubLink := Node.Subs?):
                Unlink(SubLink)
        else if (Node.DepsTail?):
            # Computed cleanup — reset to lazy
            set Node.DepsTail = false
            set Node.Flags = reactive_flags{IsMutable := true, IsDirty := true}
            PurgeDeps(Node)

    PurgeDeps(Sub:reactive_node)<transacts>:void =
        DepsTail := Sub.DepsTail
        var MaybeDep : ?reactive_link = if (Tail := DepsTail?) then Tail.NextDep else Sub.Deps
        loop:
            if (D := MaybeDep?):
                set MaybeDep = Unlink(D, Sub)
            else:
                break

    Flush():void =
        loop:
            if (NotifyIndex < QueuedLength):
                if (_Effect := QueuedEffects[NotifyIndex]?):
                    DequeueEffect()
                    RunEffect(_Effect)
                else:
                    AdvanceNotifyIndex()
            else:
                break

        RestoreQueuedEffectsFlags()

    RestoreQueuedEffectsFlags()<transacts>:void =
        loop:
            if (NotifyIndex < QueuedLength):
                if (_Effect := QueuedEffects[NotifyIndex]?):
                    set QueuedEffects = SetArrayElement(QueuedEffects, NotifyIndex, false)
                    set _Effect.Flags.IsWatching = true
                    set _Effect.Flags.IsRecursed = true
                set NotifyIndex = NotifyIndex + 1
            else:
                break

        set NotifyIndex = 0
        set QueuedLength = 0
        set QueuedEffects = array{}

    DequeueEffect()<transacts>:void =
        set QueuedEffects = SetArrayElement(QueuedEffects, NotifyIndex, false)
        set NotifyIndex = NotifyIndex + 1

    AdvanceNotifyIndex()<transacts>:void =
        set NotifyIndex = NotifyIndex + 1

    RunEffect(E:reactive_node):void =
        EFlags := E.Flags
        if:
            EFlags.IsDirty?
        then:
            DoRunEffect(E)
        else if:
            EFlags.IsPending?
            Deps := E.Deps?
            CheckDirty(Deps, E)?
        then:
            DoRunEffect(E)
        else:
            SetWatchingFlag(E)

    SetWatchingFlag(E:reactive_node)<transacts>:void =
        set E.Flags.IsWatching = true

    DoRunEffect(E:reactive_node):void =
        PrevSub := PreRunEffect(E)
        E.EffectFn()
        PostRunEffect(E, PrevSub)

    PreRunEffect(E:reactive_node)<transacts>:?reactive_node =
        set Cycle = Cycle + 1
        set E.DepsTail = false
        set E.Flags = reactive_flags {IsWatching := true, IsRecursedCheck := true}
        SetActiveSub(option {E})

    PostRunEffect(E:reactive_node, PrevSub:?reactive_node)<transacts>:void =
        set ActiveSub = PrevSub
        set E.Flags.IsRecursedCheck = false
        PurgeDeps(E)

    PreCreateEffect<public>(EffectNode:reactive_node)<transacts>:?reactive_node =
        PrevSub := SetActiveSub(option {EffectNode})
        if (PS := PrevSub?):
            Link(EffectNode, PS, 0)
        PrevSub

    PostCreateEffect<public>(EffectNode:reactive_node, PrevSub:?reactive_node)<transacts>:void =
        set ActiveSub = PrevSub
        set EffectNode.Flags.IsRecursedCheck = false

    BeginBatch<public>()<transacts>:void =
        set BatchDepth = BatchDepth + 1

    EndBatch<public>()<transacts>:void =
        set BatchDepth = BatchDepth - 1

SetArrayElement(InArray:[]?reactive_node, Index:int, Value:?reactive_node)<transacts>:[]?reactive_node =
    for (I -> Element : InArray):
        if (I = Index):
            Value
        else:
            Element
