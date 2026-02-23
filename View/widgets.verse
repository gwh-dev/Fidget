using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Simulation }
using { /Verse.org/Colors }

using { Signals }

StringToMessage<internal><localizes>(String:string):message = "{String}"

text<public>:= class(view, colorable, opacity_able, text_justifiable, text_overflowable, shadowable):
    Label<public>:string

    var<private>NativeTextBlock<public>:?FNUI.text_block = false

    GetWidget<internal>():FNUI.text_block =
        if (TextBlock := NativeTextBlock?) then:
            TextBlock
        else:
            Message := StringToMessage(Label)
            NewTextBlock := FNUI.text_block {DefaultText := Message}
            set NativeTextBlock = option {NewTextBlock}
            NewTextBlock
    
    InternalBuildWidget<override>():UEUI.widget =
        GetWidget()

    SetText<public>(InText:string):void =
        GetWidget().SetText(StringToMessage(InText))
            
    SetColor<override>(InColor:color):void =
        GetWidget().SetTextColor(InColor)

    SetOpacity<override>(InOpacity:opacity):void =
        GetWidget().SetTextOpacity(InOpacity)

    SetJustification<override>(InJustification:justification):void =
        GetWidget().SetJustification(ToTextJustification(InJustification))

    SetOverflowPolicy<override>(InOverflowPolicy:overflow_policy):void =
        GetWidget().SetOverflowPolicy(ToTextOverflowPolicy(InOverflowPolicy))

    SetShadowOffset<override>(InShadowOffset:vector2):void =
        GetWidget().SetShadowOffset(option {InShadowOffset})

    SetShadowColor<override>(InColor:color):void =
        GetWidget().SetShadowColor(InColor)

    SetShadowOpacity<override>(InOpacity:opacity):void =
        GetWidget().SetShadowOpacity(InOpacity)


button<public>:= class(view, clickable, highlightable):
    Child<public>:view

    var<private>NativeButton<public>:?UEUI.button = false

    GetWidget<internal>():UEUI.button =
        if (Button := NativeButton?) then:
            Button
        else:
            Child.SetParent(Self)
            Slot := UEUI.button_slot {
                Widget := Child.OnBuildWidget()
                Padding := BuildMargin(Child)
                HorizontalAlignment := BuildHorizontalAlignment(Child)
                VerticalAlignment := BuildVerticalAlignment(Child)
            }
            NewButton := UEUI.button {Slot := Slot}
            
            AddCancelable(NewButton.OnClick().Subscribe(HandleClick))
            AddCancelable(NewButton.HighlightEvent().Subscribe(HandleHighlight))
            AddCancelable(NewButton.UnhighlightEvent().Subscribe(HandleUnhighlight))

            set NativeButton = option {NewButton}
            NewButton

    InternalBuildWidget<override>():UEUI.widget =
        GetWidget()

    UpdateChildSlot<override>(InChildView:view):void =
        TargetWidget := InChildView.OnBuildWidget()
        SourceWidget := Child.OnBuildWidget()
        if (SourceWidget = TargetWidget, Button := NativeButton?) then:
            Slot := UEUI.button_slot {
                Widget := TargetWidget
                Padding := BuildMargin(Child)
                HorizontalAlignment := BuildHorizontalAlignment(Child)
                VerticalAlignment := BuildVerticalAlignment(Child)
            }
            Button.SetWidget(Slot)

    var<private>OnClickHandlers:[]type{_():void} = array{}
    var<private>OnHighlightHandlers:[]type{_():void} = array{}
    var<private>OnUnhighlightHandlers:[]type{_():void} = array{}

    SetOnClick<override>(InHandler:type{_():void}):void =
        set OnClickHandlers = OnClickHandlers + array{InHandler}

    SetOnHighlight<override>(InHandler:type{_():void}):void =
        set OnHighlightHandlers = OnHighlightHandlers + array{InHandler}

    SetOnUnhighlight<override>(InHandler:type{_():void}):void =
        set OnUnhighlightHandlers = OnUnhighlightHandlers + array{InHandler}

    HandleClick<private>(Msg:UEUI.widget_message):void =
        for (Handler : OnClickHandlers) do:
            Handler()

    HandleHighlight<private>(Msg:UEUI.widget_message):void =
        for (Handler : OnHighlightHandlers) do:
            Handler()

    HandleUnhighlight<private>(Msg:UEUI.widget_message):void =
        for (Handler : OnUnhighlightHandlers) do:
            Handler()
