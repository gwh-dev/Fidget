using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/UI }

using { Signals }

# ============================================================================
#  STRUCTURAL REACTIVE VIEWS — the tree changes SHAPE from signals.
#
#  dynamic_view owns one rebuild effect: each run reads the driving signals
#  (via OnRenderChildren), tears the old children down and builds the new ones.
#  Live children are tracked in the base Children list, so disposing the
#  dynamic view (or any ancestor) tears the current subtree down with it and
#  input detection sees through it. Children built inside the run are
#  auto-scoped to the rebuild effect, so their signal bindings are purged by
#  the framework on the next run; the explicit Dispose() only releases native
#  widget subscriptions and is safe mid-run because effect.Cancel defers
#  while any dependency list is live.
#
#    when_view    structural if: Condition signal picks Then/Else subtree
#    switch_view  structural case: a comparable signal keys a builder map
#    list_view    structural for-each: an []t signal maps through ItemBuilder
#
#  Builders are function values (bound methods or module functions) — Verse
#  has no closures, so per-item context rides the builder's holder class.
# ============================================================================

dynamic_view<public> := class<abstract>(view_native(UEUI.stack_box)):
    GetOrientation<protected>():UEUI.orientation = UEUI.orientation.Vertical

    OnRenderChildren<protected>():[]view = array{}

    OnBuildNativeWidget<override>():UEUI.stack_box = UEUI.stack_box{Orientation := GetOrientation()}

    OnBuildWidget<override>():UEUI.widget =
        StackBox := GetWidget()
        AddCancelable(Effect(Rebuild))
        StackBox

    Rebuild<internal>():void =
        NewChildren := OnRenderChildren()
        StackBox := GetWidget()
        for (OldChild : Children):
            if (Native := OldChild.BuiltWidget?):
                StackBox.RemoveWidget(Native)
            OldChild.Dispose()
        for (NewChild : NewChildren):
            NewChild.SetParent(Self)
            StackBox.AddWidget(UEUI.stack_box_slot {
                Widget := NewChild.Build()
                Padding := BuildMargin(NewChild)
                HorizontalAlignment := BuildHorizontalAlignment(NewChild)
                VerticalAlignment := BuildVerticalAlignment(NewChild)
                Distribution := NewChild.DistributionValue
            })
        set Children = NewChildren

when_view<public> := class(dynamic_view):
    Condition<public>:signal_get(logic)
    Then<public>:type{_():view}
    Else<public>:?type{_():view} = false

    OnRenderChildren<override>():[]view =
        Taken := Condition.Get()
        if (Taken?):
            return array{Then()}
        if (Fallback := Else?):
            return array{Fallback()}
        array{}

switch_view<public>(t:subtype(comparable)) := class(dynamic_view):
    Match<public>:signal_get(t)
    Cases<public>:[t]type{_():view}
    Default<public>:?type{_():view} = false

    OnRenderChildren<override>():[]view =
        MatchedKey := Match.Get()
        if (FoundBuilder := Cases[MatchedKey]):
            return array{FoundBuilder()}
        if (Fallback := Default?):
            return array{Fallback()}
        array{}

list_view<public>(t:subtype(comparable)) := class(dynamic_view):
    Items<public>:signal_get([]t)
    ItemBuilder<public>:type{_(:t):view}

    OnRenderChildren<override>():[]view =
        for (ItemValue : Items.Get()):
            ItemBuilder(ItemValue)
