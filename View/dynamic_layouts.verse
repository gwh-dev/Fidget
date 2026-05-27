using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/UI }

using { Signals }

dynamic_view<public> := class<abstract>(view):
    var<private>RenderedChildren<public>:[]view = array{}
    var<private>NativeStackBox<public>:?UEUI.stack_box = false

    GetOrientation<protected>():UEUI.orientation = UEUI.orientation.Vertical

    InternalBuildWidget<override>():UEUI.widget =
        NewStackBox := UEUI.stack_box {Orientation := GetOrientation()}
        set NativeStackBox = option {NewStackBox}

        SetupEffect()

        NewStackBox

    SetupEffect<protected>():void = {}

    GetRenderedChildren<protected>()<transacts>:[]view =
        return RenderedChildren

    SetRenderedChildren<protected>(InChildren:[]view)<transacts>:void =
        set RenderedChildren = InChildren

list_view<public>(t:type) := class(dynamic_view):
    ItemBuilder<public>:type{_(:t):view}

    var<private> RawItems:[]t = array{}
    Version<private>:signal_int = signal_int{Value := 0}

    SetupEffect<override>():void =
        AddCancelable(Effect(UpdateLayoutEffect))

    SetItems<public>(NewItems:[]t):void =
        set RawItems = NewItems
        Version.Set(Version.Get() + 1)

    UpdateLayoutEffect<private>():void =
        Version.Get()
        UpdateView(RawItems)

    UpdateView<private>(NewItems:[]t):void =
        if (StackBox := NativeStackBox?) then:
            for (Child : GetRenderedChildren()) do:
                if (Native := Child.BuiltWidget?):
                    StackBox.RemoveWidget(Native)
                Child.Dispose()

            var NewChildren:[]view = array{}
            for (ItemData : NewItems) do:
                Item := ItemBuilder(ItemData)
                Item.SetParent(Self)
                set NewChildren = NewChildren + array{Item}
                StackBox.AddWidget(UEUI.stack_box_slot {
                    Widget := Item.OnBuildWidget()
                    Padding := BuildMargin(Item)
                    HorizontalAlignment := BuildHorizontalAlignment(Item)
                    VerticalAlignment := BuildVerticalAlignment(Item)
                    Distribution := Item.MyDistribution
                })

            SetRenderedChildren(NewChildren)

switch_view<public>(t:subtype(comparable)) := class(dynamic_view):
    Match<public>:signal_get(t)
    Cases<public>:[t]type{_():view}
    Default<public>:?type{_():view} = false

    SetupEffect<override>():void =
        AddCancelable(Effect(UpdateLayoutEffect))

    UpdateLayoutEffect<private>():void =
        UpdateView(Match.Get())

    GetResolvedBuilder<private>(TargetKey:t)<transacts>:?type{_():view} =
        if (FoundBuilder := Cases[TargetKey]) then:
            option {FoundBuilder}
        else if (FallbackBuilder := Default?):
            option {FallbackBuilder}
        else:
            false

    UpdateView<private>(TargetKey:t):void =
        if (StackBox := NativeStackBox?) then:
            for (Child : GetRenderedChildren()) do:
                if (Native := Child.BuiltWidget?):
                    StackBox.RemoveWidget(Native)
                Child.Dispose()

            var NewChildren:[]view = array{}

            ViewBuilder := GetResolvedBuilder(TargetKey)

            if (ValidBuilder := ViewBuilder?) then:
                NewView := ValidBuilder()
                NewView.SetParent(Self)
                set NewChildren = array{NewView}

                Slot := UEUI.stack_box_slot {
                    Widget := NewView.OnBuildWidget()
                    Padding := BuildMargin(NewView)
                    HorizontalAlignment := BuildHorizontalAlignment(NewView)
                    VerticalAlignment := BuildVerticalAlignment(NewView)
                    Distribution := NewView.MyDistribution
                }
                StackBox.AddWidget(Slot)

            SetRenderedChildren(NewChildren)
