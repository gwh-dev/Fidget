(InMap:[k]v).Keys<public>(() where k:subtype(comparable), v:type)<computes>:[]k=
    return for (Key -> Val : InMap) do Key

(InMap:[k]v).Values<public>(() where k:subtype(comparable), v:type)<computes>:[]v =
    return for (Key -> Val : InMap) do Val

(InMap:[k]v).Invert<public>(() where k:subtype(comparable), v:subtype(comparable))<computes>:[v]k =
    Results := for (Key -> Val : InMap) do map {Val => Key}
    Results.Reduce(map {}, InternalConcatMapReducer)

(InMap:[k]v).RemoveKey<public>(InKey:k where k:subtype(comparable), v:subtype(comparable))<computes>:[k]v =
    Results := for (Key -> Val : InMap, InKey <> Key) do map {Key => Val}
    Results.Reduce(map {}, InternalConcatMapReducer)

(InMap:[k]v).RemoveValue<public>(InValue:v where k:subtype(comparable), v:subtype(comparable))<computes>:[k]v =
    Results := for (Key -> Val : InMap, InValue <> Val) do map {Key => Val}
    Results.Reduce(map {}, InternalConcatMapReducer)

(InMap:[k]v).MapValue<public>(Function(:v)<computes>:u where k:subtype(comparable), v:type, u:type)<computes>:[k]u =
    Results := for (Key -> Val : InMap) do map {Key => Function(Val)}
    Results.Reduce(map {}, InternalConcatMapReducer)

(InMap:[k]v).FilterKey<public>(Function(:k)<computes><decides>:void where k:subtype(comparable), v:type)<computes>:[k]v =
    Results := for (Key -> Val : InMap, Function[Key]) do map {Key => Val}
    Results.Reduce(map {}, InternalConcatMapReducer)

(InMap:[k]v).FilterValue<public>(Function(:v)<computes><decides>:void where k:subtype(comparable), v:type)<computes>:[k]v =
    Results := for (Key -> Val : InMap, Function[Val]) do map {Key => Val}
    Results.Reduce(map {}, InternalConcatMapReducer)

InternalConcatMapReducer<internal>(AccumulatedMap:[k]u, Map:[k]u where k:subtype(comparable), u:type)<computes>:[k]u =
    ConcatenateMaps(AccumulatedMap, Map)

(InMap:[k]v).Any<public>(Function(:k, :v)<computes><decides>:void where k:subtype(comparable), v:type)<computes><decides>:void =
    Loop := for (Key -> Val : InMap, Function[Key, Val]) do true
    Loop.Length > 0

(InMap:[k]v).All<public>(Function(:k, :v)<computes><decides>:void where k:subtype(comparable), v:type)<computes><decides>:void =
    Failures := for (Key -> Val : InMap, not Function[Key, Val]) do true
    Failures.Length = 0
