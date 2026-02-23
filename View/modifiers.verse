using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Colors }
using { /UnrealEngine.com/Temporary/UI }

using { Signals }

# ----------------- Interfaces -----------------
colorable<public>:= interface:
    SetColor<public>(InColor:color):void

tintable<public>:= interface:
    SetTint<public>(InTint:color):void

opacity_able<public>:= interface:
    SetOpacity<public>(InOpacity:opacity):void

desired_sizeable<public>:= interface:
    SetDesiredSize<public>(InSize:vector2):void

tileable<public>:= interface:
    SetTiling<public>(H:tiling, V:tiling):void

text_justifiable<public>:= interface:
    SetJustification<public>(InJustification:justification):void

text_overflowable<public>:= interface:
    SetOverflowPolicy<public>(InOverflowPolicy:overflow_policy):void

shadowable<public>:= interface:
    SetShadowOffset<public>(InOffset:vector2):void
    SetShadowColor<public>(InColor:color):void
    SetShadowOpacity<public>(InOpacity:opacity):void

clickable<public>:= interface:
    SetOnClick<public>(InHandler:type{_():void}):void

highlightable<public>:= interface:
    SetOnHighlight<public>(InHandler:type{_():void}):void
    SetOnUnhighlight<public>(InHandler:type{_():void}):void

modifier_handler(t:type) := class:
    Value:t
    InputFunction:type{_(:t):void}
    OutputFunction():void =
        InputFunction(Value)

# ----------------- Base View Modifiers -----------------
(InView:t).Padding<public>(InPadding:padding where t:subtype(view)):t =
    InView.SetPadding(InPadding)
    if (Parent := InView.ParentView?) then:
        Parent.UpdateChildSlot(InView)
    return InView

(InView:t).Padding<public>(Amount:float where t:subtype(view)):t =
    InView.SetPadding(padding {Left := Amount, Right := Amount, Top := Amount, Bottom := Amount})
    if (Parent := InView.ParentView?) then:
        Parent.UpdateChildSlot(InView)
    return InView

(InView:t).PaddingLeft<public>(Amount:float where t:subtype(view)):t =
    InView.SetPadding(padding {Left := Amount, MakePadding<constructor>(InView.MyPadding)})
    if (Parent := InView.ParentView?) then:
        Parent.UpdateChildSlot(InView)
    return InView

(InView:t).PaddingRight<public>(Amount:float where t:subtype(view)):t =
    InView.SetPadding(padding {Right := Amount, MakePadding<constructor>(InView.MyPadding)})
    if (Parent := InView.ParentView?) then:
        Parent.UpdateChildSlot(InView)
    return InView

(InView:t).PaddingTop<public>(Amount:float where t:subtype(view)):t =
    InView.SetPadding(padding {Top := Amount, MakePadding<constructor>(InView.MyPadding)})
    if (Parent := InView.ParentView?) then:
        Parent.UpdateChildSlot(InView)
    return InView

(InView:t).PaddingBottom<public>(Amount:float where t:subtype(view)):t =
    InView.SetPadding(padding {Bottom := Amount, MakePadding<constructor>(InView.MyPadding)})
    if (Parent := InView.ParentView?) then:
        Parent.UpdateChildSlot(InView)
    return InView

(InView:t).Alignment<public>(InAlign:alignment where t:subtype(view)):t =
    InView.SetHorizontalAlignment(InAlign)
    InView.SetVerticalAlignment(InAlign)
    if (Parent := InView.ParentView?) then:
        Parent.UpdateChildSlot(InView)
    return InView

(InView:t).Visibility<public>(InVisibility:visibility where t:subtype(view)):t =
    InView.SetVisibility(InVisibility)
    return InView

(InView:t).Distribution<public>(InDistribution:?float where t:subtype(view)):t =
    InView.SetDistribution(InDistribution)
    if (Parent := InView.ParentView?) then:
        Parent.UpdateChildSlot(InView)
    return InView

(InView:t).Enabled<public>(InEnabled:logic where t:subtype(view)):t =
    InView.SetEnabled(InEnabled)
    return InView

(InView:t).Background<public>(BgView:view where t:subtype(view)):t =
    InView.SetBackground(BgView)
    if (Parent := InView.ParentView?) then:
        Parent.UpdateChildSlot(InView)
    return InView

(InView:t).Foreground<public>(FgView:view where t:subtype(view)):t =
    InView.SetForeground(FgView)
    if (Parent := InView.ParentView?) then:
        Parent.UpdateChildSlot(InView)
    return InView

# ----------------- Trait Modifiers -----------------
(InView:t).Color<public>(InColor:color where t:subtype(colorable)):t =
    InView.SetColor(InColor)
    return InView

(InView:t).Tint<public>(InColor:color where t:subtype(tintable)):t =
    InView.SetTint(InColor)
    return InView

(InView:t).Opacity<public>(InOpacity:opacity where t:subtype(opacity_able)):t =
    InView.SetOpacity(InOpacity)
    return InView

(InView:t).DesiredSize<public>(InSize:vector2 where t:subtype(desired_sizeable)):t =
    InView.SetDesiredSize(InSize)
    return InView

(InView:t).Tiling<public>(H:tiling, V:tiling where t:subtype(tileable)):t =
    InView.SetTiling(H, V)
    return InView

(InView:t).Justification<public>(InJustification:justification where t:subtype(text_justifiable)):t =
    InView.SetJustification(InJustification)
    return InView

(InView:t).OverflowPolicy<public>(InOverflowPolicy:overflow_policy where t:subtype(text_overflowable)):t =
    InView.SetOverflowPolicy(InOverflowPolicy)
    return InView

(InView:t).ShadowOffset<public>(InOffset:vector2 where t:subtype(shadowable)):t =
    InView.SetShadowOffset(InOffset)
    return InView

(InView:t).ShadowColor<public>(InColor:color where t:subtype(shadowable)):t =
    InView.SetShadowColor(InColor)
    return InView

(InView:t).ShadowOpacity<public>(InOpacity:opacity where t:subtype(shadowable)):t =
    InView.SetShadowOpacity(InOpacity)
    return InView

(InView:t).OnClick<public>(InHandler:type{_():void} where t:subtype(clickable)):t =
    InView.SetOnClick(InHandler)
    return InView

(InView:t).OnClickWith<public>(InHandler:type{_(:k):void}, Value:k where t:subtype(clickable), k:type):t =
    ModifierHandler := modifier_handler(k) {Value := Value, InputFunction := InHandler}
    InView.SetOnClick(ModifierHandler.OutputFunction)
    return InView

(InView:t).OnHighlight<public>(InHandler:type{_():void} where t:subtype(highlightable)):t =
    InView.SetOnHighlight(InHandler)
    return InView

(InView:t).OnHighlightWith<public>(InHandler:type{_(:k):void}, Value:k where t:subtype(highlightable), k:type):t =
    ModifierHandler := modifier_handler(k) {Value := Value, InputFunction := InHandler}
    InView.SetOnHighlight(ModifierHandler.OutputFunction)
    return InView

(InView:t).OnUnhighlight<public>(InHandler:type{_():void} where t:subtype(highlightable)):t =
    InView.SetOnUnhighlight(InHandler)
    return InView

(InView:t).OnUnhighlightWith<public>(InHandler:type{_(:k):void}, Value:k where t:subtype(highlightable), k:type):t =
    ModifierHandler := modifier_handler(k) {Value := Value, InputFunction := InHandler}
    InView.SetOnUnhighlight(ModifierHandler.OutputFunction)
    return InView

# ----------------- Reactive Effects -----------------
UpdateVisibilityEffect<internal>(Payload:tuple(view, signal_get(visibility))):void =
    InView := Payload(0)
    Signal := Payload(1)
    InView.SetVisibility(Signal.Get())

UpdateTextEffect<internal>(Payload:tuple(text, signal_get(string))):void =
    InView := Payload(0)
    Signal := Payload(1)
    InView.SetText(Signal.Get())

UpdateEnabledEffect<internal>(Payload:tuple(view, signal_get(logic))):void =
    InView := Payload(0)
    Signal := Payload(1)
    InView.SetEnabled(Signal.Get())

UpdateColorEffect<internal>(Payload:tuple(colorable, signal_get(color))):void =
    InView := Payload(0)
    Signal := Payload(1)
    InView.SetColor(Signal.Get())

UpdateOpacityEffect<internal>(Payload:tuple(opacity_able, signal_get(opacity))):void =
    InView := Payload(0)
    Signal := Payload(1)
    InView.SetOpacity(Signal.Get())

# ----------------- Reactive Modifiers -----------------
(InView:t).BindVisibility<public>(InSignal:signal_get(visibility) where t:subtype(view)):t =
    InView.AddCancelable(EffectWith(UpdateVisibilityEffect, (InView, InSignal)))
    return InView

(InView:text).BindText<public>(InSignal:signal_get(string)):text =
    InView.AddCancelable(EffectWith(UpdateTextEffect, (InView, InSignal)))
    return InView

(InView:t).BindEnabled<public>(InSignal:signal_get(logic) where t:subtype(view)):t =
    InView.AddCancelable(EffectWith(UpdateEnabledEffect, (InView, InSignal)))
    return InView

(InView:t).BindColor<public>(InSignal:signal_get(color) where t:subtype(colorable)):t =
    Colorable:colorable = InView

    if (CastedView := view[Colorable]):
        CastedView.AddCancelable(EffectWith(UpdateColorEffect, (InView, InSignal)))
    return InView

(InView:t).BindOpacity<public>(InSignal:signal_get(opacity) where t:subtype(opacity_able)):t =
    OpacityAble:opacity_able = InView

    if (CastedView := view[OpacityAble]):
        CastedView.AddCancelable(EffectWith(UpdateOpacityEffect, (InView, InSignal)))
    return InView
