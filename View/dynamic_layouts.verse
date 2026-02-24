# using { /Verse.org/Simulation }
# using { /UnrealEngine.com/Temporary/UI }

# using { Signals }

# dynamic_view<public> := class<abstract>(view):
#     var<private>RenderedChildren<public>:[]view = array{}
#     var<private>NativeStackBox<public>:?UEUI.stack_box = false

#     GetOrientation<protected>():UEUI.orientation = UEUI.orientation.Vertical

#     InternalBuildWidget<override>():UEUI.widget =
#         NewStackBox := UEUI.stack_box {Orientation := GetOrientation()}
#         set NativeStackBox = option {NewStackBox}
        
#         SetupEffect()

#         NewStackBox

#     SetupEffect<protected>():void = {}

#     GetRenderedChildren<protected>()<transacts>:[]view =
#         return RenderedChildren

#     SetRenderedChildren<protected>(InChildren:[]view)<transacts>:void =
#         set RenderedChildren = InChildren

# list<public>(t:subtype(comparable)) := class(dynamic_view):
#     Items<public>:signal_get([]t)
#     ItemBuilder<public>:type{_(:t):view}

#     SetupEffect<override>():void =
#         AddCancelable(Effect(UpdateLayoutEffect))

#     UpdateLayoutEffect<private>():void =
#         UpdateView(Items.Get())

#     UpdateView<private>(NewItems:[]t):void =
#         if (StackBox := NativeStackBox?) then:
#             for (Child : GetRenderedChildren()) do:
#                 if (Native := Child.BuiltWidget?):
#                     StackBox.RemoveWidget(Native)
#                 Child.Dispose()
            
#             var NewChildren:[]view = array {}
#             for (ItemData : NewItems) do:
#                 Item := ItemBuilder(ItemData)
#                 Item.SetParent(Self)
#                 set NewChildren = NewChildren + array {Item}

#                 Slot := UEUI.stack_box_slot {
#                     Widget := Item.OnBuildWidget()
#                     Padding := BuildMargin(Item)
#                     HorizontalAlignment := BuildHorizontalAlignment(Item)
#                     VerticalAlignment := BuildVerticalAlignment(Item)
#                     Distribution := Item.MyDistribution
#                 }
#                 StackBox.AddWidget(Slot)
            
#             SetRenderedChildren(NewChildren)

# grid<public>(t:subtype(comparable)) := class(dynamic_view):
#     Columns<public>:int = 3
#     Items<public>:signal_get([]t)
#     ItemBuilder<public>:type{_(:t):view}

#     SetupEffect<override>():void =
#         AddCancelable(Effect(UpdateLayoutEffect))

#     UpdateLayoutEffect<private>():void =
#         UpdateView(Items.Get())

#     UpdateView<private>(NewItems:[]t):void =
#         if (StackBox := NativeStackBox?) then:
#             for (Child : GetRenderedChildren()) do:
#                 if (Native := Child.BuiltWidget?):
#                     StackBox.RemoveWidget(Native)
#                 Child.Dispose()
            
#             var NewChildren:[]view = array {}
#             var CurrentRowViews:[]view = array {}
#             var CurrentColCount:int = 0

#             for (AddIndex := 0..NewItems.Length - 1, ItemData := NewItems[AddIndex]) do:
#                 Item := ItemBuilder(ItemData)
#                 set CurrentRowViews = CurrentRowViews + array {Item}
#                 set CurrentColCount = CurrentColCount + 1

#                 if (CurrentColCount = Columns or AddIndex = NewItems.Length - 1) then:
#                     RowView := hstack{Children := CurrentRowViews}
#                     RowView.SetParent(Self)
#                     set NewChildren = NewChildren + array {RowView}

#                     Slot := UEUI.stack_box_slot {
#                         Widget := RowView.OnBuildWidget()
#                         Padding := BuildMargin(RowView)
#                         HorizontalAlignment := BuildHorizontalAlignment(RowView)
#                         VerticalAlignment := BuildVerticalAlignment(RowView)
#                         Distribution := RowView.MyDistribution
#                     }
#                     StackBox.AddWidget(Slot)
#                     set CurrentRowViews = array {}
#                     set CurrentColCount = 0
            
#             SetRenderedChildren(NewChildren)

# scroll_list_handler<internal>(t:subtype(comparable)) := class:
#     ListRef:scroll_list(t)
#     Index:int
#     MaxLen:int

#     HandleHighlight<internal>():void =
#         ListRef.HandleHighlightUp(Index, MaxLen)
#         ListRef.HandleHighlightDown(Index, MaxLen)

# scroll_list<public>(t:subtype(comparable)) := class(dynamic_view):
#     Orientation<public>:UEUI.orientation = UEUI.orientation.Vertical
#     MaxVisible<public>:int = 5
#     Items<public>:signal_get([]t)
#     ItemBuilder<public>:type{_(:t):view}
    
#     ScrollIndex<private>:signal_int = signal_int {Value := 0}
#     FocusIndex<private>:signal_int = signal_int {Value := -1}

#     GetOrientation<override>():UEUI.orientation = Orientation

#     SetupEffect<override>():void =
#         AddCancelable(Effect(UpdateLayoutEffect))

#     UpdateLayoutEffect<private>():void =
#         UpdateView(Items.Get(), ScrollIndex.Get())

#     HandleHighlightUp<internal>(Index:int, MaxLen:int):void =
#         CurrentOffset := ScrollIndex.Get()
#         if (Index = 0 and CurrentOffset > 0) then:
#             NewOffset := CurrentOffset - 1
#             FocusIndex.Set(0)
#             ScrollIndex.Set(if (NewOffset < 0) then 0 else NewOffset)
            
#     HandleHighlightDown<internal>(Index:int, MaxLen:int):void =
#         CurrentOffset := ScrollIndex.Get()
#         if (Index >= MaxVisible - 1 and CurrentOffset + MaxVisible < MaxLen) then:
#             NewOffset := CurrentOffset + 1
#             FocusIndex.Set(Index - 1)
#             ScrollIndex.Set(NewOffset)

#     UpdateView<private>(NewItems:[]t, CurrentIndex:int):void =
#         if (StackBox := NativeStackBox?) then:
#             for (Child : GetRenderedChildren()) do:
#                 if (Native := Child.BuiltWidget?):
#                     StackBox.RemoveWidget(Native)
#                 Child.Dispose()

#             var NewChildren:[]view = array {}
#             EndIndex := CurrentIndex + MaxVisible
            
#             var ActualEnd:int = EndIndex
#             if (ActualEnd > NewItems.Length) then:
#                 set ActualEnd = NewItems.Length

#             var DisplayIndex:int = CurrentIndex
#             if (DisplayIndex < 0) then:
#                 set DisplayIndex = 0

#             var FocusTargetWidget:?UEUI.widget = false
#             var LocalIndex:int = 0

#             if (DisplayIndex < ActualEnd) then:
#                 for (AddIndex := DisplayIndex..ActualEnd - 1, ItemData := NewItems[AddIndex]) do:
#                     Item := ItemBuilder(ItemData)
                    
#                     if (ButtonWidget := View.button[Item]) then:
#                         UnifiedHandler := scroll_list_handler(t){ListRef := Self, Index := LocalIndex, MaxLen := NewItems.Length}
#                         ButtonWidget.SetOnHighlight(UnifiedHandler.HandleHighlight)
                        
#                     Item.SetParent(Self)
#                     set NewChildren = NewChildren + array {Item}

#                     TargetIdx := FocusIndex.Get()
#                     ItemWidget := Item.OnBuildWidget()

#                     if (TargetIdx >= 0 and TargetIdx = LocalIndex) then:
#                         set FocusTargetWidget = option {ItemWidget}

#                     Slot := UEUI.stack_box_slot {
#                         Widget := ItemWidget
#                         Padding := BuildMargin(Item)
#                         HorizontalAlignment := BuildHorizontalAlignment(Item)
#                         VerticalAlignment := BuildVerticalAlignment(Item)
#                         Distribution := Item.MyDistribution
#                     }
#                     StackBox.AddWidget(Slot)
#                     set LocalIndex = LocalIndex + 1
            
#             SetRenderedChildren(NewChildren)

#             if (TargetToFocus := FocusTargetWidget?, Player := GetPlayer[], PlayerUI := GetPlayerUI[Player]) then:
#                 PlayerUI.SetFocus(TargetToFocus)
            
#             FocusIndex.Set(-1)


# scroll_grid_handler<internal>(t:subtype(comparable)) := class:
#     GridRef:scroll_grid(t)
#     Index:int
#     MaxLen:int
    
#     HandleHighlight<internal>():void =
#         GridRef.HandleHighlightUp(Index, MaxLen)
#         GridRef.HandleHighlightDown(Index, MaxLen)

# scroll_grid<public>(t:subtype(comparable)) := class(dynamic_view):
#     Orientation<public>:UEUI.orientation = UEUI.orientation.Vertical
#     Columns<public>:int = 3
#     Rows<public>:int = 3
#     Items<public>:signal_get([]t)
#     ItemBuilder<public>:type{_(:t):view}
    
#     ScrollIndex<private>:signal_int = signal_int {Value := 0}
#     FocusIndex<private>:signal_int = signal_int {Value := -1}

#     GetOrientation<override>():UEUI.orientation = Orientation

#     SetupEffect<override>():void =
#         AddCancelable(Effect(UpdateLayoutEffect))

#     UpdateLayoutEffect<private>():void =
#         UpdateView(Items.Get(), ScrollIndex.Get())

#     HandleHighlightUp<internal>(Index:int, MaxLen:int):void =
#         CurrentOffset := ScrollIndex.Get()
#         if (Index < Columns and CurrentOffset > 0) then:
#             NewOffset := CurrentOffset - Columns
#             FocusIndex.Set(Index) 
#             ScrollIndex.Set(if (NewOffset < 0) then 0 else NewOffset)
            
#     HandleHighlightDown<internal>(Index:int, MaxLen:int):void =
#         CurrentOffset := ScrollIndex.Get()
#         VisibleCount := Columns * Rows
#         if (Index >= VisibleCount - Columns and CurrentOffset + VisibleCount < MaxLen) then:
#             NewOffset := CurrentOffset + Columns
#             FocusIndex.Set(Index - Columns)
#             ScrollIndex.Set(NewOffset)

#     UpdateView<private>(NewItems:[]t, CurrentIndex:int):void =
#         if (StackBox := NativeStackBox?) then:
#             for (Child : GetRenderedChildren()) do:
#                 if (Native := Child.BuiltWidget?):
#                     StackBox.RemoveWidget(Native)
#                 Child.Dispose()

#             var NewChildren:[]view = array {}
#             var CurrentRowViews:[]view = array {}
#             var CurrentColCount:int = 0

#             MaxVisibleItems := Columns * Rows
#             EndIndex := CurrentIndex + MaxVisibleItems
            
#             var ActualEnd:int = EndIndex
#             if (ActualEnd > NewItems.Length) then:
#                 set ActualEnd = NewItems.Length

#             var DisplayIndex:int = CurrentIndex
#             if (DisplayIndex < 0) then:
#                 set DisplayIndex = 0

#             var FocusTargetWidget:?UEUI.widget = false
#             var LocalIndex:int = 0

#             if (DisplayIndex < ActualEnd) then:
#                 for (AddIndex := DisplayIndex..ActualEnd - 1, ItemData := NewItems[AddIndex]) do:
#                     Item := ItemBuilder(ItemData)
                    
#                     if (ButtonWidget := View.button[Item]) then:
#                         Handler := scroll_grid_handler(t){GridRef := Self, Index := LocalIndex, MaxLen := NewItems.Length}
#                         ButtonWidget.SetOnHighlight(Handler.HandleHighlight)

#                     set CurrentRowViews = CurrentRowViews + array {Item}
#                     set CurrentColCount = CurrentColCount + 1

#                     TargetIdx := FocusIndex.Get()
#                     ItemWidget := Item.OnBuildWidget()
#                     if (TargetIdx >= 0 and TargetIdx = LocalIndex) then:
#                         set FocusTargetWidget = option {ItemWidget}

#                     if (CurrentColCount = Columns or AddIndex = ActualEnd - 1) then:
#                         SecondaryOrientation := if (Orientation = UEUI.orientation.Vertical) then UEUI.orientation.Horizontal else UEUI.orientation.Vertical

#                         RowOrColView := if (SecondaryOrientation = UEUI.orientation.Horizontal) then hstack{Children := CurrentRowViews} else vstack{Children := CurrentRowViews}
#                         RowOrColView.SetParent(Self)
#                         set NewChildren = NewChildren + array {RowOrColView}

#                         Slot := UEUI.stack_box_slot {
#                             Widget := RowOrColView.OnBuildWidget()
#                             Padding := BuildMargin(RowOrColView)
#                             HorizontalAlignment := BuildHorizontalAlignment(RowOrColView)
#                             VerticalAlignment := BuildVerticalAlignment(RowOrColView)
#                             Distribution := RowOrColView.MyDistribution
#                         }
#                         StackBox.AddWidget(Slot)
#                         set CurrentRowViews = array {}
#                         set CurrentColCount = 0
                    
#                     set LocalIndex = LocalIndex + 1
            
#             SetRenderedChildren(NewChildren)

#             if (TargetToFocus := FocusTargetWidget?, Player := GetPlayer[], PlayerUI := GetPlayerUI[Player]) then:
#                 PlayerUI.SetFocus(TargetToFocus)
            
#             FocusIndex.Set(-1)


# switch<public>(t:subtype(comparable)) := class(dynamic_view):
#     Match<public>:signal_get(t)
#     Cases<public>:[t]type{_():view}
#     Default<public>:?type{_():view} = false

#     SetupEffect<override>():void =
#         AddCancelable(Effect(UpdateLayoutEffect))

#     UpdateLayoutEffect<private>():void =
#         UpdateView(Match.Get())

#     GetResolvedBuilder<private>(TargetKey:t)<transacts>:?type{_():view} =
#         if (FoundBuilder := Cases[TargetKey]) then:
#             option {FoundBuilder}
#         else if (FallbackBuilder := Default?):
#             option {FallbackBuilder}
#         else:
#             false

#     UpdateView<private>(TargetKey:t):void =
#         if (StackBox := NativeStackBox?) then:
#             for (Child : GetRenderedChildren()) do:
#                 if (Native := Child.BuiltWidget?):
#                     StackBox.RemoveWidget(Native)
#                 Child.Dispose()
            
#             var NewChildren:[]view = array {}
            
#             ViewBuilder := GetResolvedBuilder(TargetKey)
            
#             if (ValidBuilder := ViewBuilder?) then:
#                 NewView := ValidBuilder()
#                 NewView.SetParent(Self)
#                 set NewChildren = array {NewView}
                
#                 Slot := UEUI.stack_box_slot {
#                     Widget := NewView.OnBuildWidget()
#                     Padding := BuildMargin(NewView)
#                     HorizontalAlignment := BuildHorizontalAlignment(NewView)
#                     VerticalAlignment := BuildVerticalAlignment(NewView)
#                     Distribution := NewView.MyDistribution
#                 }
#                 StackBox.AddWidget(Slot)

#             SetRenderedChildren(NewChildren)
