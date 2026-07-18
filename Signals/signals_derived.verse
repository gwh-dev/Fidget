using { /Verse.org/Simulation }

# ============================================================================
#  SIGNAL COMBINATORS — one-line derivations over signal_get, no bespoke
#  holder classes at call sites. Each combinator is a small adapter class
#  implementing signal_get directly: reading it inside an effect reads its
#  sources, so dependencies track through it like any signal. Adapters are
#  pass-through (no caching): re-evaluation is a cheap pure transform, and
#  the dependency still points at the underlying signal. Verse note: they
#  cannot route through Computed — extracting a bound method from a value
#  whose type uses the enclosing function's type parameters is rejected
#  ("can't access a function from a preceding type"), while plain generic
#  construction (the EffectWith idiom) is allowed.
#
#    Constant(t, Value)                        fixed value as signal_get(t)
#    Map(t, u, Source, Transform)              Transform(Source)
#    Map2(t1, t2, u, S1, S2, Transform)        Transform(S1, S2)
#    Equals / NotEquals(t, Source, Value)      comparison as signal_get(logic)
#    Select(t, Condition, WhenTrue, WhenFalse) reactive ternary, value branches
#    SelectSignal(t, Condition, S1, S2)        reactive ternary, SIGNAL branches
#                                              (only the taken branch is read,
#                                              so dependencies stay minimal;
#                                              separate name — a generic
#                                              overload pair is ambiguous)
#    FormatInt(Source, Prefix, Suffix)         "{Prefix}{Source}{Suffix}"
#    IsNonEmpty(Source)                        string has content
#
#  IRON RULE (playtest-proven, cost a full input-freeze bug): a signal read
#  NEVER sits inside a failure context. A failed condition rolls back the
#  dependency link the read just created and the subscriber silently goes
#  deaf. Every Get() here is hoisted to a local FIRST; conditions test only
#  locals.
# ============================================================================

constant_signal<internal>(t:subtype(comparable)) := class(signal_get(t)):
    Value<internal>:t
    Get<override>()<transacts>:t = Value

Constant<public>(t:subtype(comparable), Value:t):signal_get(t) =
    constant_signal(t){Value := Value}

map_signal<internal>(t:subtype(comparable), u:subtype(comparable)) := class(signal_get(u)):
    Source<internal>:signal_get(t)
    Transform<internal>:type{_(:t)<transacts>:u}
    Get<override>()<transacts>:u = Transform(Source.Get())

Map<public>(t:subtype(comparable), u:subtype(comparable), Source:signal_get(t), Transform:type{_(:t)<transacts>:u}):signal_get(u) =
    map_signal(t, u){Source := Source, Transform := Transform}

map_pair_signal<internal>(t1:subtype(comparable), t2:subtype(comparable), u:subtype(comparable)) := class(signal_get(u)):
    SourceOne<internal>:signal_get(t1)
    SourceTwo<internal>:signal_get(t2)
    Transform<internal>:type{_(:t1, :t2)<transacts>:u}
    Get<override>()<transacts>:u = Transform(SourceOne.Get(), SourceTwo.Get())

Map2<public>(t1:subtype(comparable), t2:subtype(comparable), u:subtype(comparable), SourceOne:signal_get(t1), SourceTwo:signal_get(t2), Transform:type{_(:t1, :t2)<transacts>:u}):signal_get(u) =
    map_pair_signal(t1, t2, u){SourceOne := SourceOne, SourceTwo := SourceTwo, Transform := Transform}

equality_signal<internal>(t:subtype(comparable)) := class(signal_get(logic)):
    Source<internal>:signal_get(t)
    Value<internal>:t
    Negated<internal>:logic = false
    Get<override>()<transacts>:logic =
        Current := Source.Get()
        if (Current = Value):
            return Negated? and false or true
        Negated? and true or false

Equals<public>(t:subtype(comparable), Source:signal_get(t), Value:t):signal_get(logic) =
    equality_signal(t){Source := Source, Value := Value}

NotEquals<public>(t:subtype(comparable), Source:signal_get(t), Value:t):signal_get(logic) =
    equality_signal(t){Source := Source, Value := Value, Negated := true}

select_signal<internal>(t:subtype(comparable)) := class(signal_get(t)):
    Condition<internal>:signal_get(logic)
    WhenTrue<internal>:t
    WhenFalse<internal>:t
    Get<override>()<transacts>:t =
        Taken := Condition.Get()
        if (Taken?):
            return WhenTrue
        WhenFalse

select_signal_pair<internal>(t:subtype(comparable)) := class(signal_get(t)):
    Condition<internal>:signal_get(logic)
    WhenTrue<internal>:signal_get(t)
    WhenFalse<internal>:signal_get(t)
    Get<override>()<transacts>:t =
        Taken := Condition.Get()
        if (Taken?):
            return WhenTrue.Get()
        WhenFalse.Get()

Select<public>(t:subtype(comparable), Condition:signal_get(logic), WhenTrue:t, WhenFalse:t):signal_get(t) =
    select_signal(t){Condition := Condition, WhenTrue := WhenTrue, WhenFalse := WhenFalse}

SelectSignal<public>(t:subtype(comparable), Condition:signal_get(logic), WhenTrue:signal_get(t), WhenFalse:signal_get(t)):signal_get(t) =
    select_signal_pair(t){Condition := Condition, WhenTrue := WhenTrue, WhenFalse := WhenFalse}

int_format_signal<internal> := class(signal_get(string)):
    Source<internal>:signal_get(int)
    Prefix<internal>:string
    Suffix<internal>:string
    Get<override>()<transacts>:string = "{Prefix}{Source.Get()}{Suffix}"

FormatInt<public>(Source:signal_get(int), Prefix:string, Suffix:string):signal_get(string) =
    int_format_signal{Source := Source, Prefix := Prefix, Suffix := Suffix}

StringHasContent<internal>(Value:string)<transacts>:logic =
    Value = "" and false or true

IsNonEmpty<public>(Source:signal_get(string)):signal_get(logic) =
    Map(string, logic, Source, StringHasContent)
