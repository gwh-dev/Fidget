using { Signals }

BuildMargin<internal>(InView:view)<transacts>:UEUI.margin =
    UEUI.margin {
        Left := InView.PaddingValue.Left
        Right := InView.PaddingValue.Right
        Top := InView.PaddingValue.Top
        Bottom := InView.PaddingValue.Bottom
    }

BuildHorizontalAlignment<internal>(InView:view)<transacts>:UEUI.horizontal_alignment =
    case(InView.HorizontalAlignment):
        horizontal.Fill => UEUI.horizontal_alignment.Fill
        horizontal.Center => UEUI.horizontal_alignment.Center
        horizontal.Left => UEUI.horizontal_alignment.Left
        horizontal.Right => UEUI.horizontal_alignment.Right

BuildVerticalAlignment<internal>(InView:view)<transacts>:UEUI.vertical_alignment =
    case(InView.VerticalAlignment):
        vertical.Fill => UEUI.vertical_alignment.Fill
        vertical.Center => UEUI.vertical_alignment.Center
        vertical.Top => UEUI.vertical_alignment.Top
        vertical.Bottom => UEUI.vertical_alignment.Bottom

BuildStack<internal>(InChildren:[]view, InOrientation:UEUI.orientation):UEUI.widget =
    Slots : []UEUI.stack_box_slot = for (_Child : InChildren) do:
        UEUI.stack_box_slot {
            Widget := _Child.Build()
            Padding := BuildMargin(_Child)
            HorizontalAlignment := BuildHorizontalAlignment(_Child)
            VerticalAlignment := BuildVerticalAlignment(_Child)
            Distribution := _Child.DistributionValue
        }
    
    UEUI.stack_box {Orientation := InOrientation, Slots := Slots}

UpdateStackBoxSlot<internal>(NativeStackBox:UEUI.stack_box, InChildren:[]view, InChildView:view):void =
    var IndexToRemove:int = -1
    TargetWidget := InChildView.Build()
    for (Index -> Child : InChildren) do:
        Widget := Child.Build()
        if (Widget = TargetWidget) then:
            set IndexToRemove = Index

    if (IndexToRemove >= 0) then:
        for (Index := IndexToRemove..InChildren.Length - 1) do:
            if (ChildToRemove := InChildren[Index]) then:
                NativeStackBox.RemoveWidget(ChildToRemove.Build())

        for (Index := IndexToRemove..InChildren.Length - 1) do:
            if (ChildToAdd := InChildren[Index]) then:
                NativeStackBox.AddWidget(UEUI.stack_box_slot {
                    Widget := ChildToAdd.Build()
                    Padding := BuildMargin(ChildToAdd)
                    HorizontalAlignment := BuildHorizontalAlignment(ChildToAdd)
                    VerticalAlignment := BuildVerticalAlignment(ChildToAdd)
                    Distribution := ChildToAdd.DistributionValue
                })

vstack<public> := class(view):
    OnBuildWidget<override>():UEUI.widget =
        for (Child : Children) do:
            Child.SetParent(Self)
        BuildStack(Children, UEUI.orientation.Vertical)

    OnUpdateChildSlot<override>(InChildView:view):void =
        if (NativeStackBox := UEUI.stack_box[BuiltWidget?]) then:
            UpdateStackBoxSlot(NativeStackBox, Children, InChildView)

hstack<public> := class(view):
    OnBuildWidget<override>():UEUI.widget =
        for (Child : Children) do:
            Child.SetParent(Self)
        BuildStack(Children, UEUI.orientation.Horizontal)

    OnUpdateChildSlot<override>(InChildView:view):void =
        if (NativeStackBox := UEUI.stack_box[BuiltWidget?]) then:
            UpdateStackBoxSlot(NativeStackBox, Children, InChildView)

zstack<public> := class(view):
    OnBuildWidget<override>():UEUI.widget =
        for (Child : Children) do:
            Child.SetParent(Self)
        Slots : []UEUI.overlay_slot = for (_Child : Children) do:
            UEUI.overlay_slot {
                Widget := _Child.Build()
                Padding := BuildMargin(_Child)
                HorizontalAlignment := BuildHorizontalAlignment(_Child)
                VerticalAlignment := BuildVerticalAlignment(_Child)
            }
        
        UEUI.overlay {Slots := Slots}

    OnUpdateChildSlot<override>(InChildView:view):void =
        if (NativeOverlay := UEUI.overlay[BuiltWidget?]) then:
            var IndexToRemove:int = -1
            TargetWidget := InChildView.Build()
            for (Index -> Child : Children) do:
                SourceWidget := Child.Build()
                if (SourceWidget = TargetWidget) then:
                    set IndexToRemove = Index
            
            if (IndexToRemove >= 0) then:
                for (Index := IndexToRemove..Children.Length - 1) do:
                    if (ChildToRemove := Children[Index]) then:
                        NativeOverlay.RemoveWidget(ChildToRemove.Build())
                
                for (Index := IndexToRemove..Children.Length - 1) do:
                    if (ChildToAdd := Children[Index]) then:
                        NewSlot := UEUI.overlay_slot {
                            Widget := ChildToAdd.Build()
                            Padding := BuildMargin(ChildToAdd)
                            HorizontalAlignment := BuildHorizontalAlignment(ChildToAdd)
                            VerticalAlignment := BuildVerticalAlignment(ChildToAdd)
                        }
                        NativeOverlay.AddWidget(NewSlot)
