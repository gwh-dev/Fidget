using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Simulation }
using { /Verse.org/Colors }

using { Signals }

# ============================================================================
#  NATIVE PRIMITIVES — text and button, on the generic view_native(t) base:
#  each declares OnBuildNativeWidget (its native constructor) and one-line
#  Set* forwarders; caching and the build seam live in view_native. Button
#  event wires subscribe handlers DIRECTLY on the native widget events via
#  native_event_adapter (widget_message -> plain handler), so there are no
#  handler arrays and no fan-out methods anywhere.
# ============================================================================

StringToMessage<internal><localizes>(String:string)<computes>:message = "{String}"

native_event_adapter<internal> := class:
    Handler<internal>:type{_():void}
    Invoke<internal>(Message:UEUI.widget_message):void = Handler()

text<public>:= class(view_native(FNUI.text_block), textable, colorable, opacity_able, text_justifiable, text_overflowable, shadowable):
    OnBuildNativeWidget<override>():FNUI.text_block = FNUI.text_block{}

    SetText<override>(InText:string):void = GetWidget().SetText(StringToMessage(InText))
    SetColor<override>(InColor:color):void = GetWidget().SetTextColor(InColor)
    SetOpacity<override>(InOpacity:opacity):void = GetWidget().SetTextOpacity(InOpacity)
    SetJustification<override>(InJustification:justification):void = GetWidget().SetJustification(ToTextJustification(InJustification))
    SetOverflowPolicy<override>(InOverflowPolicy:overflow_policy):void = GetWidget().SetOverflowPolicy(ToTextOverflowPolicy(InOverflowPolicy))
    SetShadowOffset<override>(InShadowOffset:vector2):void = GetWidget().SetShadowOffset(option{InShadowOffset})
    SetShadowColor<override>(InColor:color):void = GetWidget().SetShadowColor(InColor)
    SetShadowOpacity<override>(InOpacity:opacity):void = GetWidget().SetShadowOpacity(InOpacity)

button<public>:= class(view_native(UEUI.button), clickable, highlightable):
    IsInteractable<override>()<transacts><decides>:void = {}

    Child<public>:view

    block:
        set Children = array{Child}

    OnBuildNativeWidget<override>():UEUI.button =
        Child.SetParent(Self)
        UEUI.button{Slot := UEUI.button_slot{
            Widget := Child.Build()
            Padding := BuildMargin(Child)
            HorizontalAlignment := BuildHorizontalAlignment(Child)
            VerticalAlignment := BuildVerticalAlignment(Child)
        }}

    OnUpdateChildSlot<override>(InChildView:view):void =
        TargetWidget := InChildView.Build()
        SourceWidget := Child.Build()
        if (SourceWidget = TargetWidget):
            Button := GetWidget()
            Button.SetWidget(UEUI.button_slot{
                Widget := TargetWidget
                Padding := BuildMargin(Child)
                HorizontalAlignment := BuildHorizontalAlignment(Child)
                VerticalAlignment := BuildVerticalAlignment(Child)
            })

    SetOnClick<override>(InHandler:type{_():void}):void = AddCancelable(GetWidget().OnClick().Subscribe(native_event_adapter{Handler := InHandler}.Invoke))
    SetOnHighlight<override>(InHandler:type{_():void}):void = AddCancelable(GetWidget().HighlightEvent().Subscribe(native_event_adapter{Handler := InHandler}.Invoke))
    SetOnUnhighlight<override>(InHandler:type{_():void}):void = AddCancelable(GetWidget().UnhighlightEvent().Subscribe(native_event_adapter{Handler := InHandler}.Invoke))
