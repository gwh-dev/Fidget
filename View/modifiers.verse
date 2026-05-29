using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Colors }

using { Signals }

# # ----------------- Interfaces -----------------
colorable<public>:= interface:
    SetColor<public>(InColor:color):void

    (InView:t).Color<public>(InSignal:signal_get(color) where t:subtype(view)):t =
        InView.AddCancelable(EffectHandler(SetColor, InSignal))
        InView

tintable<public>:= interface:
    SetTint<public>(InTint:color):void

    (InView:t).Tint<public>(InSignal:signal_get(color) where t:subtype(view)):t =
        InView.AddCancelable(EffectHandler(SetTint, InSignal))
        InView

opacity_able<public>:= interface:
    SetOpacity<public>(InOpacity:opacity):void

    (InView:t).Opacity<public>(InSignal:signal_get(opacity) where t:subtype(view)):t =
        InView.AddCancelable(EffectHandler(SetOpacity, InSignal))
        InView

desired_sizeable<public>:= interface:
    SetDesiredSize<public>(InSize:vector2):void

tileable<public>:= interface:
    SetTiling<public>(H:tiling, V:tiling):void

text_justifiable<public>:= interface:
    SetJustification<public>(InJustification:justification):void

    (InView:t).Justification<public>(InSignal:signal_get(justification) where t:subtype(view)):t =
        InView.AddCancelable(EffectHandler(SetJustification, InSignal))
        InView

text_overflowable<public>:= interface:
    SetOverflowPolicy<public>(InOverflowPolicy:overflow_policy):void

    (InView:t).OverflowPolicy<public>(InSignal:signal_get(overflow_policy) where t:subtype(view)):t =
        InView.AddCancelable(EffectHandler(SetOverflowPolicy, InSignal))
        InView

shadowable<public>:= interface:
    SetShadowOffset<public>(InOffset:vector2):void
    SetShadowColor<public>(InColor:color):void
    SetShadowOpacity<public>(InOpacity:opacity):void

    (InView:t).ShadowColor<public>(InSignal:signal_get(color) where t:subtype(view)):t =
        InView.AddCancelable(EffectHandler(SetShadowColor, InSignal))
        InView

    (InView:t).ShadowOpacity<public>(InSignal:signal_get(opacity) where t:subtype(view)):t =
        InView.AddCancelable(EffectHandler(SetShadowOpacity, InSignal))
        InView

clickable<public>:= interface:
    SetOnClick<public>(InHandler:type{_():void}):void

highlightable<public>:= interface:
    SetOnHighlight<public>(InHandler:type{_():void}):void
    SetOnUnhighlight<public>(InHandler:type{_():void}):void

modifier_handler(t:type) := class:
    Value:t
    InputFunction:type{_(:t):void}
    OutputFunction():void = InputFunction(Value)

# # # ----------------- Base View Modifiers -----------------

UpdateChildSlotHandler(InView:view):void =
    if (Parent := InView.GetParent[]) then:
        Parent.UpdateChildSlot(InView)

EffectWatchHandler(Function:type{_(:t):void}, InValue:t where t:subtype(view)):void =
    Function(InValue)

(InView:t).Watch<public>(Function:type{_(:t):void} where t:subtype(view)):t =
    InView.AddCancelable(EffectWith(EffectWatchHandler, (Function, InView)))
    InView

(InView:t).Padding<public>(InPadding:padding where t:subtype(view)):t =
    InView.SetPadding(InPadding)
    UpdateChildSlotHandler(InView)
    InView

(InView:t).Padding<public>(Amount:float where t:subtype(view)):t =
    InView.SetPadding(padding {Left := Amount, Right := Amount, Top := Amount, Bottom := Amount})
    UpdateChildSlotHandler(InView)
    InView

(InView:t).Alignment<public>(InAlign:horizontal where t:subtype(view)):t =
    InView.SetHorizontalAlignment(InAlign)
    UpdateChildSlotHandler(InView)
    InView

(InView:t).Alignment<public>(InAlign:vertical where t:subtype(view)):t =
    InView.SetVerticalAlignment(InAlign)
    UpdateChildSlotHandler(InView)
    InView

(InView:t).Visibility<public>(InVisibility:visibility where t:subtype(view)):t =
    InView.SetVisibility(InVisibility)
    InView

(InView:t).Distribution<public>(InDistribution:?float where t:subtype(view)):t =
    InView.SetDistribution(InDistribution)
    UpdateChildSlotHandler(InView)
    InView

(InView:t).Enabled<public>(InEnabled:logic where t:subtype(view)):t =
    InView.SetEnabled(InEnabled)
    InView

(InView:t).Background<public>(BgView:view where t:subtype(view)):t =
    InView.SetBackground(BgView)
    UpdateChildSlotHandler(InView)
    InView

(InView:t).Foreground<public>(FgView:view where t:subtype(view)):t =
    InView.SetForeground(FgView)
    UpdateChildSlotHandler(InView)
    InView

# # # # ----------------- Trait Modifiers -----------------
(InView:t).Color<public>(InColor:color where t:subtype(colorable)):t =
    InView.SetColor(InColor)
    InView

(InView:t).Tint<public>(InColor:color where t:subtype(tintable)):t =
    InView.SetTint(InColor)
    InView

(InView:t).Opacity<public>(InOpacity:opacity where t:subtype(opacity_able)):t =
    InView.SetOpacity(InOpacity)
    InView

(InView:t).DesiredSize<public>(InSize:vector2 where t:subtype(desired_sizeable)):t =
    InView.SetDesiredSize(InSize)
    InView

(InView:t).Tiling<public>(H:tiling, V:tiling where t:subtype(tileable)):t =
    InView.SetTiling(H, V)
    InView

(InView:t).Justification<public>(InJustification:justification where t:subtype(text_justifiable)):t =
    InView.SetJustification(InJustification)
    InView

(InView:t).OverflowPolicy<public>(InOverflowPolicy:overflow_policy where t:subtype(text_overflowable)):t =
    InView.SetOverflowPolicy(InOverflowPolicy)
    InView

(InView:t).ShadowOffset<public>(InOffset:vector2 where t:subtype(shadowable)):t =
    InView.SetShadowOffset(InOffset)
    InView

(InView:t).ShadowColor<public>(InColor:color where t:subtype(shadowable)):t =
    InView.SetShadowColor(InColor)
    InView

(InView:t).ShadowOpacity<public>(InOpacity:opacity where t:subtype(shadowable)):t =
    InView.SetShadowOpacity(InOpacity)
    InView

(InView:t).Text<public>(InText:string where t:subtype(text)):t =
    InView.SetText(InText)
    InView

(InView:t).OnClick<public>(InHandler:type{_():void} where t:subtype(clickable)):t =
    InView.SetOnClick(InHandler)
    InView

(InView:t).OnClickWith<public>(InHandler:type{_(:k):void}, Value:k where t:subtype(clickable), k:type):t =
    ModifierHandler := modifier_handler(k) {Value := Value, InputFunction := InHandler}
    InView.SetOnClick(ModifierHandler.OutputFunction)
    InView

(InView:t).OnHighlight<public>(InHandler:type{_():void} where t:subtype(highlightable)):t =
    InView.SetOnHighlight(InHandler)
    InView

(InView:t).OnHighlightWith<public>(InHandler:type{_(:k):void}, Value:k where t:subtype(highlightable), k:type):t =
    ModifierHandler := modifier_handler(k) {Value := Value, InputFunction := InHandler}
    InView.SetOnHighlight(ModifierHandler.OutputFunction)
    InView

(InView:t).OnUnhighlight<public>(InHandler:type{_():void} where t:subtype(highlightable)):t =
    InView.SetOnUnhighlight(InHandler)
    InView

(InView:t).OnUnhighlightWith<public>(InHandler:type{_(:k):void}, Value:k where t:subtype(highlightable), k:type):t =
    ModifierHandler := modifier_handler(k) {Value := Value, InputFunction := InHandler}
    InView.SetOnUnhighlight(ModifierHandler.OutputFunction)
    InView

# # # ----------------- Reactive Bindings -----------------
EffectSetHandler(Function:type{_(:t):void}, InSignal:signal_get(t) where t:subtype(comparable)):void =
    Function(InSignal.Get())

EffectHandler(Function:type{_(:t):void}, InSignal:signal_get(t) where t:subtype(comparable)):cancelable =
    EffectWith(EffectSetHandler, (Function, InSignal))

(InView:t).Text<public>(InSignal:signal_get(string) where t:subtype(text)):t =
    InView.AddCancelable(EffectHandler(InView.SetText, InSignal))
    InView

(InView:t).Visibility<public>(InSignal:signal_get(visibility) where t:subtype(view)):t =
    InView.AddCancelable(EffectHandler(InView.SetVisibility, InSignal))
    InView

(InView:t).Enabled<public>(InSignal:signal_get(logic) where t:subtype(view)):t =
    InView.AddCancelable(EffectHandler(InView.SetEnabled, InSignal))
    InView

