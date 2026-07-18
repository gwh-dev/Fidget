using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Colors }

using { Signals }

# ============================================================================
#  MODIFIERS — capability contracts + the chainable property surface.
#
#  Capability interfaces are PURE contracts (Set*/wire methods only). Every
#  chainable modifier lives at module scope, is generic over the receiving
#  class, and returns t — the REAL class of the receiver — so chains never
#  widen to view or an interface and class members stay reachable after any
#  modifier.
#
#  Properties come in const/signal pairs with one call shape: .Text("hi")
#  sets once, .Text(Signal) binds an effect that re-applies on every change
#  (EffectHandler wraps the setter; the cancelable joins the receiver's
#  Cancelables and dies with it). Signal binders constrain t to a CLASS
#  (view / text), never to a capability interface: extracting a bound setter
#  needs a class-typed receiver, and interface-hosted extension methods do
#  not resolve on class receivers.
#
#  Event modifiers hand the handler straight to the receiver's Set wire,
#  which subscribes it DIRECTLY on the native widget event (see button) —
#  payload variants ride modifier_handler, the no-closure adapter binding
#  one value to one handler.
# ============================================================================

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

textable<public>:= interface:
    SetText<public>(InText:string):void

clickable<public>:= interface:
    SetOnClick<public>(InHandler:type{_():void}):void

highlightable<public>:= interface:
    SetOnHighlight<public>(InHandler:type{_():void}):void
    SetOnUnhighlight<public>(InHandler:type{_():void}):void

modifier_handler(t:type) := class:
    Value:t
    InputFunction:type{_(:t):void}
    OutputFunction():void = InputFunction(Value)

EffectSetHandler(Function:type{_(:t):void}, InSignal:signal_get(t) where t:subtype(comparable)):void =
    Function(InSignal.Get())

EffectHandler(Function:type{_(:t):void}, InSignal:signal_get(t) where t:subtype(comparable)):cancelable =
    EffectWith(EffectSetHandler, (Function, InSignal))

UpdateChildSlotHandler(InView:view):void =
    if (Parent := InView.GetParent[]) then:
        Parent.OnUpdateChildSlot(InView)

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

(InView:t).Text<public>(InText:string where t:subtype(textable)):t =
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

(InView:t).Text<public>(InSignal:signal_get(string) where t:subtype(text)):t =
    InView.AddCancelable(EffectHandler(InView.SetText, InSignal))
    InView

(InView:t).Color<public>(InSignal:signal_get(color) where t:subtype(text)):t =
    InView.AddCancelable(EffectHandler(InView.SetColor, InSignal))
    InView

(InView:t).Visibility<public>(InSignal:signal_get(visibility) where t:subtype(view)):t =
    InView.AddCancelable(EffectHandler(InView.SetVisibility, InSignal))
    InView

(InView:t).Enabled<public>(InSignal:signal_get(logic) where t:subtype(view)):t =
    InView.AddCancelable(EffectHandler(InView.SetEnabled, InSignal))
    InView
