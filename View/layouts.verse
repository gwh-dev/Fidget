using { Signals }

BuildMargin<internal>(InView:view):UEUI.margin =
    UEUI.margin {
        Left := InView.MyPadding.Left
        Right := InView.MyPadding.Right
        Top := InView.MyPadding.Top
        Bottom := InView.MyPadding.Bottom
    }

BuildHorizontalAlignment<internal>(InView:view):UEUI.horizontal_alignment =
    case(InView.HorizontalAlignment):
        alignment.HorizontalFill => UEUI.horizontal_alignment.Fill
        alignment.HorizontalCenter => UEUI.horizontal_alignment.Center
        alignment.HorizontalLeft => UEUI.horizontal_alignment.Left
        alignment.HorizontalRight => UEUI.horizontal_alignment.Right
        _ => Err()

BuildVerticalAlignment<internal>(InView:view):UEUI.vertical_alignment =
    case(InView.VerticalAlignment):
        alignment.VerticalFill => UEUI.vertical_alignment.Fill
        alignment.VerticalCenter => UEUI.vertical_alignment.Center
        alignment.VerticalTop => UEUI.vertical_alignment.Top
        alignment.VerticalBottom => UEUI.vertical_alignment.Bottom
        _ => Err()

BuildStack<internal>(InChildren:[]view, InOrientation:UEUI.orientation):UEUI.widget =
    Slots : []UEUI.stack_box_slot = for (_Child : InChildren) do:
        UEUI.stack_box_slot {
            Widget := _Child.OnBuildWidget()
            Padding := BuildMargin(_Child)
            HorizontalAlignment := BuildHorizontalAlignment(_Child)
            VerticalAlignment := BuildVerticalAlignment(_Child)
            Distribution := _Child.MyDistribution
        }
    
    UEUI.stack_box {Orientation := InOrientation, Slots := Slots}

vstack<public> := class(view):
    InternalBuildWidget<override>():UEUI.widget =
        for (Child : Children) do:
            Child.SetParent(Self)
        BuildStack(Children, UEUI.orientation.Vertical)

    UpdateChildSlot<override>(InChildView:view):void =
        if (NativeStackBox := UEUI.stack_box[BuiltWidget?]) then:
            var IndexToRemove:int = -1
            TargetWidget := InChildView.OnBuildWidget()
            for (Index -> Child : Children) do:
                SourceWidget := Child.OnBuildWidget()
                if (SourceWidget = TargetWidget) then:
                    set IndexToRemove = Index
            
            if (IndexToRemove >= 0) then:
                for (Index := IndexToRemove..Children.Length - 1) do:
                    if (ChildToRemove := Children[Index]) then:
                        NativeStackBox.RemoveWidget(ChildToRemove.OnBuildWidget())
                
                for (Index := IndexToRemove..Children.Length - 1) do:
                    if (ChildToAdd := Children[Index]) then:
                        NewSlot := UEUI.stack_box_slot {
                            Widget := ChildToAdd.OnBuildWidget()
                            Padding := BuildMargin(ChildToAdd)
                            HorizontalAlignment := BuildHorizontalAlignment(ChildToAdd)
                            VerticalAlignment := BuildVerticalAlignment(ChildToAdd)
                            Distribution := ChildToAdd.MyDistribution
                        }
                        NativeStackBox.AddWidget(NewSlot)

hstack<public> := class(view):
    InternalBuildWidget<override>():UEUI.widget =
        for (Child : Children) do:
            Child.SetParent(Self)
        BuildStack(Children, UEUI.orientation.Horizontal)

    UpdateChildSlot<override>(InChildView:view):void =
        if (NativeStackBox := UEUI.stack_box[BuiltWidget?]) then:
            var IndexToRemove:int = -1
            TargetWidget := InChildView.OnBuildWidget()
            for (Index -> Child : Children) do:
                SourceWidget := Child.OnBuildWidget()
                if (SourceWidget = TargetWidget) then:
                    set IndexToRemove = Index
            
            if (IndexToRemove >= 0) then:
                for (Index := IndexToRemove..Children.Length - 1) do:
                    if (ChildToRemove := Children[Index]) then:
                        NativeStackBox.RemoveWidget(ChildToRemove.OnBuildWidget())
                
                for (Index := IndexToRemove..Children.Length - 1) do:
                    if (ChildToAdd := Children[Index]) then:
                        NewSlot := UEUI.stack_box_slot {
                            Widget := ChildToAdd.OnBuildWidget()
                            Padding := BuildMargin(ChildToAdd)
                            HorizontalAlignment := BuildHorizontalAlignment(ChildToAdd)
                            VerticalAlignment := BuildVerticalAlignment(ChildToAdd)
                            Distribution := ChildToAdd.MyDistribution
                        }
                        NativeStackBox.AddWidget(NewSlot)

zstack<public> := class(view):
    InternalBuildWidget<override>():UEUI.widget =
        for (Child : Children) do:
            Child.SetParent(Self)
        Slots : []UEUI.overlay_slot = for (_Child : Children) do:
            UEUI.overlay_slot {
                Widget := _Child.OnBuildWidget()
                Padding := BuildMargin(_Child)
                HorizontalAlignment := BuildHorizontalAlignment(_Child)
                VerticalAlignment := BuildVerticalAlignment(_Child)
            }
        
        UEUI.overlay {Slots := Slots}

    UpdateChildSlot<override>(InChildView:view):void =
        if (NativeOverlay := UEUI.overlay[BuiltWidget?]) then:
            var IndexToRemove:int = -1
            TargetWidget := InChildView.OnBuildWidget()
            for (Index -> Child : Children) do:
                SourceWidget := Child.OnBuildWidget()
                if (SourceWidget = TargetWidget) then:
                    set IndexToRemove = Index
            
            if (IndexToRemove >= 0) then:
                for (Index := IndexToRemove..Children.Length - 1) do:
                    if (ChildToRemove := Children[Index]) then:
                        NativeOverlay.RemoveWidget(ChildToRemove.OnBuildWidget())
                
                for (Index := IndexToRemove..Children.Length - 1) do:
                    if (ChildToAdd := Children[Index]) then:
                        NewSlot := UEUI.overlay_slot {
                            Widget := ChildToAdd.OnBuildWidget()
                            Padding := BuildMargin(ChildToAdd)
                            HorizontalAlignment := BuildHorizontalAlignment(ChildToAdd)
                            VerticalAlignment := BuildVerticalAlignment(ChildToAdd)
                        }
                        NativeOverlay.AddWidget(NewSlot)
