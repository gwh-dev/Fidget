(InElements:[]t).Map<public>(Function(:t)<computes>:u where t:type, u:type)<computes>:[]u =
    return for (Element : InElements, Output := Function(Element)) do Output

(InElements:[]t).MapWith<public>(Function(:t, :k)<computes>:u, InData:k where t:type, k:type, u:type)<computes>:[]u =
    return for (Element : InElements, Output := Function(Element, InData)) do Output

(InElements:[]t).Filter<public>(Function(:t)<computes><decides>:void where t:type)<computes>:[]t =
    return for (Element : InElements, Function[Element]) do Element

(InElements:[]t).FilterWith<public>(Function(:t, :k)<computes><decides>:void, InData:k where t:type, k:type)<computes>:[]t =
    return for (Element : InElements, Function[Element, InData]) do Element

(InElements:[]t).Reduce<public>(Initial:u, Function(:u, :t)<computes>:u where t:type, u:type)<computes>:u =
    return InternalReduceRecursive(InElements, 0, Initial, Function)

(InElements:[]t).ReduceWith<public>(Initial:u, Function(:u, :t, :k)<computes>:u, InData:k where t:type, u:type, k:type)<computes>:u =
    InternalReduceRecursiveWith(InElements, 0, Initial, Function, InData)

InternalReduceRecursive<internal>(InElements:[]t, Index:int, CurrentAcc:u, Function(:u, :t)<computes>:u where t:type, u:type)<computes>:u =
    if (Element := InElements[Index]):
        InternalReduceRecursive(InElements, Index + 1, Function(CurrentAcc, Element), Function)
    else:
        CurrentAcc

InternalReduceRecursiveWith<internal>(Elements:[]t, Index:int, CurrentAcc:u, Function(:u, :t, :k)<computes>:u, InData:k where t:type, u:type, k:type)<computes>:u =
    if (Element := Elements[Index]):
        InternalReduceRecursiveWith(Elements, Index + 1, Function(CurrentAcc, Element, InData), Function, InData)
    else:
        CurrentAcc

(InStack:[]t).Push<public>(Element:t where t:type)<computes>:[]t =
    return InStack + array{Element}

(InStack:[]t).Pop<public>(() where t:type)<computes><decides>:tuple(t, []t) =
    TopElement := InStack[InStack.Length - 1]
    NewStack := InStack.Slice[0, InStack.Length - 1]
    return (TopElement, NewStack)

(InStack:[]t).Peek<public>(() where t:type)<computes><decides>:t =
    return InStack[InStack.Length - 1]

(InQueue:[]t).Enqueue<public>(Element:t where t:type)<computes>:[]t =
    return InQueue + array{Element}

(InQueue:[]t).Dequeue<public>(() where t:type)<computes><decides>:tuple(t, []t) =
    FrontElement := InQueue[0]
    NewQueue := InQueue.Slice[1, InQueue.Length]
    return (FrontElement, NewQueue)
