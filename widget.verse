
WidgetComponents<public>:= module {
    using { /Fortnite.com/Game }
    using { /Fortnite.com/Playspaces }
    using { /Fortnite.com/UI }
    using { /UnrealEngine.com/Temporary/SpatialMath }
    using { /UnrealEngine.com/Temporary/UI }
    using { /Verse.org/Assets }
    using { /Verse.org/Colors }
    using { /Verse.org/SceneGraph }
    using { /Verse.org/Simulation }

    ToMessage<localizes><internal>(InString:string):message = "{InString}"

    WidgetComponentsMessages<internal>:= module {
        PaddingCategory<public><localizes>:message = "Padding"
        AlignmentCategory<public><localizes>:message = "Alignment"
        TilingCategory<public><localizes>:message = "Tiling"
        ShadowCategory<public><localizes>:message = "Shadow"
    }

    opacity<public>:= type {_X:float where 0.000000 <= _X, _X <= 1.000000}

    colorable<public>:= interface<internal>{
        @editable
        var<private>Color<public><final>:color = color{}

        SetColor<public><final>(New:color):void = {
            set Color = New
            WidgetComponent := widget_component[Self] or Err("ERROR: widget editable")
            WidgetComponent.UpdateWidget()
        }
    }

    tintable<public>:= interface<internal>{
        @editable
        var<private>Tint<public><final>:color = color{}

        SetTint<public><final>(New:color):void = {
            set Tint = New
            WidgetComponent := widget_component[Self] or Err("ERROR: widget editable")
            WidgetComponent.UpdateWidget()
        }
    }

    fadeable<public>:= interface<internal>{
        @editable
        var<private>Opacity<public><final>:opacity = 1.0

        SetOpacity<public><final>(New:opacity):void = {
            set Opacity = New
            WidgetComponent := widget_component[Self] or Err("ERROR: widget editable")
            WidgetComponent.UpdateWidget()
        }
    }

    sizeable<public>:= interface<internal>{
        @editable
        var<private>DesiredSize<public><final>:vector2 = vector2{}

        SetDesiredSize<public><final>(New:vector2):void = {
            set DesiredSize = New
            WidgetComponent := widget_component[Self] or Err("ERROR: widget editable")
            WidgetComponent.UpdateWidget()
        }
    }

    tileable<public>:= interface<internal>{
        @editable{Categories := array{WidgetComponentsMessages.TilingCategory}}
        var<private>HorizontalTiling<public><final>:image_tiling = image_tiling.Stretch
        @editable{Categories := array{WidgetComponentsMessages.TilingCategory}}
        var<private>VerticalTiling<public><final>:image_tiling = image_tiling.Stretch

        SetHorizontalTiling<public><final>(New:image_tiling):void = {
            set HorizontalTiling = New
            WidgetComponent := widget_component[Self] or Err("ERROR: widget editable")
            WidgetComponent.UpdateWidget()
        }

        SetVerticalAlignment<public><final>(New:image_tiling):void = {
            set VerticalTiling = New
            WidgetComponent := widget_component[Self] or Err("ERROR: widget editable")
            WidgetComponent.UpdateWidget()
        }
    }

    paddable<public>:= interface<internal>{
        @editable{Categories := array{WidgetComponentsMessages.PaddingCategory}}
        var<private>Left<public><final>:float = 0.0
        @editable{Categories := array{WidgetComponentsMessages.PaddingCategory}}
        var<private>Top<public><final>:float = 0.0
        @editable{Categories := array{WidgetComponentsMessages.PaddingCategory}}
        var<private>Right<public><final>:float = 0.0
        @editable{Categories := array{WidgetComponentsMessages.PaddingCategory}}
        var<private>Bottom<public><final>:float = 0.0

        GetPadding<public><final>():margin = margin {
            Left := Left
            Top := Top
            Right := Right
            Bottom := Bottom
        }

        SetPadding<public><final>(New:margin):void = {
            Margin := GetPadding()
            set Left = New.Left
            set Top = New.Top
            set Right = New.Right
            set Bottom = New.Bottom
            WidgetComponent := widget_component[Self] or Err("ERROR: widget editable")
            WidgetComponent.Entity.UpdateSlotContainer()
        }
    }

    alignable<public>:= interface<internal>{
        @editable{Categories := array{WidgetComponentsMessages.AlignmentCategory}}
        var<private>HorizontalAlignment<public><final>:horizontal_alignment = horizontal_alignment.Left
        @editable{Categories := array{WidgetComponentsMessages.AlignmentCategory}}
        var<private>VerticalAlignment<public><final>:vertical_alignment = vertical_alignment.Top

        SetHorizontalAlignment<public><final>(New:horizontal_alignment):void = {
            set HorizontalAlignment = New
            WidgetComponent := widget_component[Self] or Err("ERROR: widget editable")
            WidgetComponent.Entity.UpdateSlotContainer()
        }

        SetVerticalAlignment<public><final>(New:vertical_alignment):void = {
            set VerticalAlignment = New
            WidgetComponent := widget_component[Self] or Err("ERROR: widget editable")
            WidgetComponent.Entity.UpdateSlotContainer()
        }
    }

    container<internal>(t:subtype(comparable)) := interface {
        BuildSlot<internal>(:widget_component):t
        OnAddSlot<internal>(:t):void
        OnRemoveWidget<internal>(:widget):void

        var Slots<private><final>:[widget_component]t = map{}

        GetSlots<public><final>():[widget_component]t = {
            return Slots
        }

        SetSlots<public><final>(InWidgetComponent:widget_component, Slot:t):void = {
            if { set Slots[InWidgetComponent] = Slot }
        }

        UpdateSlot<public><final>(InEntity:entity):void = {
            if (WidgetComponent := InEntity.GetComponent[widget_component]) then {

                ChildSlot := BuildSlot(WidgetComponent)
                ChildWidget := WidgetComponent.GetWidget()

                if (OldSlot := Slots[WidgetComponent]) then {

                    if (OldSlot = ChildSlot) then {
                        return
                    }

                    OnRemoveWidget(ChildWidget)
                    OnAddSlot(ChildSlot)
                } else {
                    OnAddSlot(ChildSlot)
                }

                if {set Slots[WidgetComponent] = ChildSlot}
            }
        }

        AddWidget<public><final>(InEntity:entity):void = {
            if (WidgetComponent := InEntity.GetComponent[widget_component]) then {
                NewSlot := BuildSlot(WidgetComponent)
                OnAddSlot(NewSlot)
                if {
                    set Slots[WidgetComponent] = NewSlot
                }
            }
        }

        RemoveWidget<public><final>(InEntity:entity):void = {
            if (WidgetComponent := InEntity.GetComponent[widget_component], OldSlot := Slots[WidgetComponent]) then {
                Widget := WidgetComponent.GetWidget()
                OnRemoveWidget(Widget)
            }
        }
    }

    widget_component<public>:= class<final_super><abstract><internal>(component, enableable, paddable, alignable) {
        @editable
        Preview<private><final>:logic = false
        @editable
        var IsEnable<private><final>:logic = false
        @editable
        var<private>Visibility<public><final>:widget_visibility = widget_visibility.Visible

        var MaybeWidget<private><final>:?widget = false
        var RoundStartedHandler<private><final>:?cancelable = false

        BuildWidget<protected>():widget

        UpdateWidget<internal>():void = {
            Widget := GetWidget()
            WidgetIsEnabled := Widget.IsEnabled()
            WidgetVisibility := Widget.GetVisibility()

            if (IsEnable <> WidgetIsEnabled) then Widget.SetEnabled(IsEnable)
            if (Visibility <> WidgetVisibility) then Widget.SetVisibility(Visibility)
        }

        GetWidget<public><final>():widget = {
            if (Widget := MaybeWidget?) then {
                return Widget
            } else {
                Widget := BuildWidget()
                SetWidget(Widget)
                return Widget
            }
        }

        SetWidget<public><final>(New:widget):void = {
            set MaybeWidget = option{New}
            Entity.UpdateSlotContainer()
        }

        OnAddedToScene<override>():void = {
            Entity.AddToContainer()
            UpdateWidget()
        }

        OnSimulate<override>()<suspends>:void = {
            if (Preview?) then {
                Widget := GetWidget()

                for (Player : Entity.GetPlayspaceForEntity[].GetPlayers(), PlayerUI := GetPlayerUI[Player]) do {
                    PlayerUI.AddWidget(Widget)
                }

                if (RoundManager := Entity.GetFortRoundManager[]) then {
                    Subscribe := RoundManager.SubscribeRoundStarted(OnRoundStarted)
                    set RoundStartedHandler = option{Subscribe}
                }

                loop {
                    Sleep(3.0)
                    UpdateWidget()
                }
            }
        }

        OnRoundStarted():void = {
            Widget := GetWidget()

            if (RoundStartedSubscribed := RoundStartedHandler?) then {
                RoundStartedSubscribed.Cancel()
            }

            for (Player : Entity.GetPlayspaceForEntity[].GetPlayers(), PlayerUI := GetPlayerUI[Player]) do {
                PlayerUI.RemoveWidget(Widget)
            }
        }

        OnRemovingFromScene<override>():void = {
            Entity.RemoveFromContainer()
        }

        SetVisibility(New:widget_visibility):void = {
            set Visibility = New
            UpdateWidget()
        }

        IsEnabled<final><override>()<transacts><decides>:void = IsEnable?

        Enable<final><override>():void = {
            set IsEnable = true
            UpdateWidget()
        }

        Disable<final><override>():void = {
            set IsEnable = false
            UpdateWidget()
        }
    }

    widget_container_component<public>:= class<abstract><internal>(widget_component) {
        var<private>AddWidget<public>:     entity -> void
        var<private>RemoveWidget<public>:  entity -> void
        var<private>UpdateSlot<public>:    entity -> void

        (InContainer:container(t)).InitContainer<internal>(() where t:subtype(comparable))<transacts>:void = {
            if (WidgetContainerComponent := widget_container_component[InContainer]) then {
                set WidgetContainerComponent.AddWidget =    InContainer.AddWidget
                set WidgetContainerComponent.RemoveWidget = InContainer.AddWidget
                set WidgetContainerComponent.UpdateSlot =   InContainer.AddWidget
            }
        }

        UpdateWidget<override>():void = {
            (super:)UpdateWidget()

            if (not IsEnabled[]) then return

            for (WidgetEntity : Entity.GetEntities(), WidgetComponent := WidgetEntity.GetComponent[widget_component]) do {
                AddWidget(WidgetEntity)
            }
        }
    }

    (InEntity:entity).AddToContainer<internal>():void = {
        if (ParentEntity := InEntity.GetParent[], WidgetContainerComponent := ParentEntity.GetComponent[widget_container_component]) then {
            WidgetContainerComponent.AddWidget(InEntity)
        }
    }

    (InEntity:entity).RemoveFromContainer<internal>():void = {
        if (ParentEntity := InEntity.GetParent[], WidgetContainerComponent := ParentEntity.GetComponent[widget_container_component]) then {
            WidgetContainerComponent.RemoveWidget(InEntity)
        }
    }

    (InEntity:entity).UpdateSlotContainer<internal>():void = {
        if (ParentEntity := InEntity.GetParent[], WidgetContainerComponent := ParentEntity.GetComponent[widget_container_component]) then {
            WidgetContainerComponent.UpdateSlot(InEntity)
        }
    }

    widget_container_overlay_component<public>:= class<final>(widget_container_component, container(overlay_slot)) {
        block { InitContainer() }

        BuildWidget<override>():widget = overlay {}

        BuildSlot<override>(InWidgetComponent:widget_component):overlay_slot = overlay_slot {
            let {
                Widget := InWidgetComponent.GetWidget()
                Padding := InWidgetComponent.GetPadding()
                Horizontal := InWidgetComponent.HorizontalAlignment
                Vertical := InWidgetComponent.VerticalAlignment
            }

            Widget := Widget
            Padding := Padding
            HorizontalAlignment := Horizontal
            VerticalAlignment := Vertical
        }

        OnAddSlot<override>(InSlot:overlay_slot):void = {
            Widget := GetWidget()
            Overlay := overlay[Widget] or Err()
            Overlay.AddWidget(InSlot)
        }

        OnRemoveWidget<override>(InWidget:widget):void = {
            Widget := GetWidget()
            Overlay := overlay[Widget] or Err()
            Overlay.RemoveWidget(InWidget)
        }
    }

    widget_stack_box_slot_distribution_component := class<final_super>(component) {
        @editable
        var<private>Distribution<public>:?float = false

        OnBeginSimulation<override>():void = {
            (super:)OnBeginSimulation()
        }

        SetDistribution(New:?float):void = {
            set Distribution = New
            Entity.UpdateSlotContainer()
        }
    }

    (InEntity:entity).GetStackBoxWidgetDistribution():?float = {
        if (WidgetStackBoxDistributionComponent := InEntity.GetComponent[widget_stack_box_slot_distribution_component]) then {
            return WidgetStackBoxDistributionComponent.Distribution
        }

        return false
    }

    widget_container_stack_box_component<public>:= class<final>(widget_container_component, container(stack_box_slot)) {
        block { InitContainer() }

        @editable
        var<private>Orientation<public>:orientation = orientation.Horizontal

        SetOrientation(New:orientation):void = {
            set Orientation = New
            UpdateWidget()
        }

        BuildWidget<override>():widget = stack_box {
            Orientation := Orientation
        }

        BuildSlot<override>(InWidgetComponent:widget_component):stack_box_slot = stack_box_slot{
            let {
                Widget := InWidgetComponent.GetWidget()
                Padding := InWidgetComponent.GetPadding()
                Horizontal := InWidgetComponent.HorizontalAlignment
                Vertical := InWidgetComponent.VerticalAlignment
                Distribution := InWidgetComponent.Entity.GetStackBoxWidgetDistribution()
            }

            Widget := Widget
            Padding := Padding
            HorizontalAlignment := Horizontal
            VerticalAlignment := Vertical
            Distribution := Distribution
        }

        UpdateWidget<override>():void = {
            (super:)UpdateWidget()

            if (not IsEnabled[]) then return

            Widget := GetWidget()
            StackBox := stack_box[Widget] or Err()

            if (StackBox.Orientation <> Orientation) then {
                SetWidget(BuildWidget())
                Entity.UpdateSlotContainer()
            }

            (super:)UpdateWidget()
        }

        OnAddSlot<override>(InSlot:stack_box_slot):void = {
            Widget := GetWidget()
            StackBox := stack_box[Widget] or Err()
            StackBox.AddWidget(InSlot)
        }

        OnRemoveWidget<override>(InWidget:widget):void = {
            Widget := GetWidget()
            StackBox := stack_box[Widget] or Err()
            StackBox.RemoveWidget(InWidget)
        }
    }

    # im not doing this.
    # widget_container_button_component<public>:= class<final_super>(component) {

    # }

    widget_block_color_component<public>:= class<final>(widget_component, colorable, fadeable, sizeable) {

        BuildWidget<override>()<transacts>:widget = color_block {
            DefaultColor := Color
            DefaultOpacity := Opacity
            DefaultDesiredSize := DesiredSize
        }

        UpdateWidget<override>():void = {
            (super:)UpdateWidget()

            if (not IsEnabled[]) then return

            Widget := GetWidget()
            ColorBlock := color_block[Widget] or Err()
            CurrentColor := ColorBlock.GetColor()
            CurrentOpacity := ColorBlock.GetOpacity()
            CurrentDesiredSize := ColorBlock.GetDesiredSize()
            if (CurrentColor <> Color) then ColorBlock.SetColor(Color)
            if (CurrentOpacity <> Opacity) then ColorBlock.SetOpacity(Opacity)
            if (CurrentDesiredSize <> DesiredSize) then ColorBlock.SetDesiredSize(DesiredSize)
        }
    }

    widget_block_material_component<public>:= class<final>(widget_component, tintable, sizeable) {
        @editable
        var<private>Material<public>:?material = false

        # it's best to not use it
        # edit material that already set before instead
        SetMaterial<public>(New:material):void = {
            Widget := GetWidget()

            set Material = option{New}

            if (MaterialBlock := material_block[Widget]) then {
                MaterialBlock.SetImage(New)
            } else {
                SetWidget(BuildWidget())
            }
        }

        BuildWidget<override>()<transacts>:widget = {
            return material_block {
                DefaultImage := Material?
                DefaultTint := Tint
                DefaultDesiredSize := DesiredSize
            } or color_block {
                DefaultColor := Tint
                DefaultDesiredSize := DesiredSize
            }
        }

        UpdateWidget<override>():void = {
            (super:)UpdateWidget()

            if (not IsEnabled[]) then return

            InitialWidget := GetWidget()

            Widget := if (Material? and material_block[InitialWidget]) then {
                InitialWidget
            } else {
                SetWidget(BuildWidget())
                GetWidget()
            }

            if (MaterialBlock := material_block[Widget]) then {
                CurrentTint := MaterialBlock.GetTint()
                CurrentDesiredSize := MaterialBlock.GetDesiredSize()
                if (CurrentTint <> Tint) then MaterialBlock.SetTint(Tint)
                if (CurrentDesiredSize <> DesiredSize) then MaterialBlock.SetDesiredSize(DesiredSize)
            } else {
                ColorBlock := color_block[Widget] or Err()
                CurrentColor := ColorBlock.GetColor()
                CurrentDesiredSize := ColorBlock.GetDesiredSize()
                if (CurrentColor <> Tint) then ColorBlock.SetColor(Tint)
                if (CurrentDesiredSize <> DesiredSize) then ColorBlock.SetDesiredSize(DesiredSize)
            }
        }
    }

    widget_block_texture_component<public>:= class<final>(widget_component, tintable, sizeable, tileable) {
        @editable
        var<private>Texture<public>:?texture = false

        SetTexture<public>(New:texture):void = {
            Widget := GetWidget()

            set Texture = option{New}

            if (TextureBlock := texture_block[Widget]) then {
                TextureBlock.SetImage(New)
            } else {
                SetWidget(BuildWidget())
            }
        }

        BuildWidget<override>():widget = {
            return texture_block {
                DefaultImage := Texture?
                DefaultTint := Tint
                DefaultDesiredSize := DesiredSize
                DefaultHorizontalTiling := HorizontalTiling
                DefaultVerticalTiling := VerticalTiling
            } or color_block {
                DefaultColor := Tint
                DefaultDesiredSize := DesiredSize
            }
        }

        UpdateWidget<override>():void = {
            (super:)UpdateWidget()

            if (not IsEnabled[]) then return

            InitialWidget := GetWidget()

            Widget := if (Texture? and texture_block[InitialWidget]) then {
                InitialWidget
            } else {
                SetWidget(BuildWidget())
                GetWidget()
            }

            if (TextureBlock := texture_block[Widget]) then {
                CurrentTint := TextureBlock.GetTint()
                CurrentDesiredSize := TextureBlock.GetDesiredSize()
                CurrentTiling := TextureBlock.GetTiling()
                if (CurrentTint <> Tint) then TextureBlock.SetTint(Tint)
                if (CurrentDesiredSize <> DesiredSize) then TextureBlock.SetDesiredSize(DesiredSize)
                if (CurrentTiling <> (HorizontalTiling, VerticalTiling)) then TextureBlock.SetTiling(HorizontalTiling, VerticalTiling)
            } else {
                ColorBlock := color_block[Widget] or Err()
                CurrentColor := ColorBlock.GetColor()
                CurrentDesiredSize := ColorBlock.GetDesiredSize()
                if (CurrentColor <> Tint) then ColorBlock.SetColor(Tint)
                if (CurrentDesiredSize <> DesiredSize) then ColorBlock.SetDesiredSize(DesiredSize)
            }
        }
    }

    widget_block_text_component<public>:= class<final>(widget_component, colorable, fadeable) {
        @editable_text_box {MultiLine := true}
        var<private>Text<public>:string = "Text Here"
        @editable_number(float){}
        var<private>TextSize:float = 10.0
        @editable
        var<private>Justification:text_justification = text_justification.Center
        @editable
        var<private>OverflowPolicy:text_overflow_policy = text_overflow_policy.Clip

        @editable{Categories := array{WidgetComponentsMessages.ShadowCategory}}
        var<private>ShadowOffset<public>:?vector2 = false
        @editable{Categories := array{WidgetComponentsMessages.ShadowCategory}}
        var<private>ShadowColor<public>:color = color{}
        @editable{Categories := array{WidgetComponentsMessages.ShadowCategory}}
        var<private>ShadowOpacity<public>:opacity = 1.0

        SetText<public>(New:string):void = {
            set Text = New
            UpdateWidget()
        }

        SetTextSize<public>(New:float):void = {
            set TextSize = New
            UpdateWidget()
        }

        SetJustification<public>(New:text_justification):void = {
            set Justification = New
            UpdateWidget()
        }

        SetOverflowPolicy<public>(New:text_overflow_policy):void = {
            set OverflowPolicy = New
            UpdateWidget()
        }

        SetShadowOffset<public>(New:?vector2):void = {
            set ShadowOffset = New
            UpdateWidget()
        }

        SetShadowColor<public>(New:color):void = {
            set ShadowColor = New
            UpdateWidget()
        }

        SetShadowOpacity<public>(New:opacity):void = {
            set ShadowOpacity = New
            UpdateWidget()
        }


        BuildWidget<override>():widget = text_block {
            DefaultText := ToMessage(Text)
            DefaultTextColor := Color
            DefaultTextSize := TextSize
            DefaultTextOpacity := Opacity
            DefaultJustification := Justification
            DefaultOverflowPolicy := OverflowPolicy
            DefaultShadowOffset := ShadowOffset
            DefaultShadowColor := ShadowColor
            DefaultShadowOpacity := ShadowOpacity
        }

        UpdateWidget<override>():void = {
            (super:)UpdateWidget()

            if (not IsEnabled[]) then return

            Widget := GetWidget()
            TextBlock := text_block[Widget] or Err()

            CurrentText := TextBlock.GetText()
            CurrentTextColor := TextBlock.GetTextColor()
            CurrentTextSize := TextBlock.GetTextSize()
            CurrentTextOpacity := TextBlock.GetTextOpacity()
            CurrentTextJustification := TextBlock.GetJustification()
            CurrentTextOverflowPolicy := TextBlock.GetOverflowPolicy()

            if (CurrentText <> Text) then TextBlock.SetText(ToMessage(Text))
            if (CurrentTextColor <> Color) then TextBlock.SetTextColor(Color)
            if (CurrentTextSize <> TextSize) then TextBlock.SetTextSize(TextSize)
            if (CurrentTextOpacity <> Opacity) then TextBlock.SetTextOpacity(Opacity)
            if (CurrentTextJustification <> Justification) then TextBlock.SetJustification(Justification)
            if (CurrentTextOverflowPolicy <> OverflowPolicy) then TextBlock.SetOverflowPolicy(OverflowPolicy)
            
            if (ShadowOffset?) then {
                CurrentShadowOffset := TextBlock.GetShadowOffset()
                CurrentShadowColor := TextBlock.GetShadowColor()
                CurrentShadowOpacity := TextBlock.GetShadowOpacity()

                if (CurrentShadowOpacity <> ShadowOffset?) then TextBlock.SetShadowOffset(ShadowOffset)
                if (CurrentShadowColor <> ShadowColor) then TextBlock.SetShadowColor(ShadowColor)
                if (CurrentShadowOpacity <> ShadowOpacity) then TextBlock.SetShadowOpacity(ShadowOpacity)
            } else {
                CurrentShadowOpacity := TextBlock.GetShadowOpacity()
                if (CurrentShadowOpacity <> 0.0) then TextBlock.SetShadowOpacity(0.0)
            }
        }
    }

    button_style<public>:= enum {
        Loud
        Quiet
        Regular
    }

    widget_block_button_component<public>:= class(widget_component) {
        @editable_text_box {MultiLine:= true}
        var<private>Text<public>:string = "Text Here"
        @editable
        var<private>ButtonStyle<public>:button_style = button_style.Regular

        var CurrentButtonClickHandler<private>:?cancelable = false

        # Use this
        OnClick(:widget_message):void = {}

        OnRemovingFromScene<override>():void = {
            (super:)OnRemovingFromScene()

            if (Sub := CurrentButtonClickHandler?) then {
                Sub.Cancel()
            }
        }

        SetButtonStyle<public>(New:button_style):void = {
            set ButtonStyle = New
            UpdateWidget()
        }

        BuildWidget<override>():widget = {
            TextMessage := ToMessage(Text)

            return case(ButtonStyle) {
                button_style.Loud => button_loud {DefaultText := TextMessage}
                button_style.Quiet => button_quiet {DefaultText := TextMessage}
                button_style.Regular => button_regular {DefaultText := TextMessage}
            }
        }

        UpdateWidget<override>():void = {
            (super:)UpdateWidget()

            if (not IsEnabled[]) then return

            Widget := GetWidget()
            Button := text_button_base[Widget] or Err()

            CurrentStyle := button_loud[Button] and button_style.Loud or button_quiet[Button] and button_style.Quiet or button_style.Regular
            CurrentText := Button.GetText()

            if (CurrentStyle <> ButtonStyle) then {
                NewWidget := BuildWidget()
                NewButton := text_button_base[NewWidget] or Err()
                NewSubscribe := NewButton.OnClick().Subscribe(OnClick)

                if (Sub := CurrentButtonClickHandler?) then {
                    Sub.Cancel()
                }

                set CurrentButtonClickHandler = option{NewSubscribe}

                SetWidget(NewButton)
                Entity.UpdateSlotContainer()
            }

            if (CurrentText <> Text) then Button.SetText(ToMessage(Text))
        }
    }
}
