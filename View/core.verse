using { /Verse.org/Simulation }

using { Signals }

view<public>:= class<abstract><transacts>:
    var Cancelables<internal>:[]cancelable = array {}
    var Children<public>:[]view = array {}
    var<private>ParentView<public>:?view = false

    var MyPadding<public>:padding = padding {}

    var HorizontalAlignment<public>:alignment = alignment.HorizontalFill
    var VerticalAlignment<public>:alignment = alignment.VerticalFill

    var MyDistribution<public>:?float = false

    var<private> MountedPlayer:?player = false

    SetPlayer<internal>(InPlayer:player):void =
        set MountedPlayer = option {InPlayer}

    GetPlayer<public>()<transacts><decides>:player =
        MountedPlayer? or ParentView?.GetPlayer[]
    
    GetParent<public>()<transacts><decides>:view =
        ParentView?

    var BuiltWidget<internal>:?UEUI.widget = false

    OnBuild<public>():view = Self

    UpdateChildSlot<public>(InChildView:view):void = {}

    var<private> NativeBackgroundConstraints:?view = false
    var<private> NativeForegroundConstraints:?view = false

    SetBackground<internal>(InView:view):void =
        set NativeBackgroundConstraints = option {InView}

    SetForeground<internal>(InView:view):void =
        set NativeForegroundConstraints = option {InView}

    OnBuildWidget<final><public>():UEUI.widget =
        if (W := BuiltWidget?) then:
            W
        else:
            BaseW := InternalBuildWidget()
            if (NativeBackgroundConstraints? or NativeForegroundConstraints?):
                Overlay := UEUI.overlay {}
                if (Bg := NativeBackgroundConstraints?):
                    Bg.SetParent(Self)
                    Overlay.AddWidget(UEUI.overlay_slot { Widget := Bg.OnBuildWidget(), Padding := BuildMargin(Bg), HorizontalAlignment := BuildHorizontalAlignment(Bg), VerticalAlignment := BuildVerticalAlignment(Bg) })
                
                Overlay.AddWidget(UEUI.overlay_slot { Widget := BaseW, HorizontalAlignment := UEUI.horizontal_alignment.Fill, VerticalAlignment := UEUI.vertical_alignment.Fill })

                if (Fg := NativeForegroundConstraints?):
                    Fg.SetParent(Self)
                    Overlay.AddWidget(UEUI.overlay_slot { Widget := Fg.OnBuildWidget(), Padding := BuildMargin(Fg), HorizontalAlignment := BuildHorizontalAlignment(Fg), VerticalAlignment := BuildVerticalAlignment(Fg) })
                
                set BuiltWidget = option {Overlay}
                Overlay
            else:
                set BuiltWidget = option {BaseW}
                BaseW

    InternalBuildWidget<protected>():UEUI.widget =
        OnBuild().OnBuildWidget()
    
    AddCancelable<final><public>(InCancelable:cancelable):void =
        set Cancelables = Cancelables + array {InCancelable}

    Dispose<final><public>():void =
        for (Cancelable : Cancelables) do:
            Cancelable.Cancel()

        for ((local:)Child : Children) do:
            (local:)Child.Dispose()

    SetPadding<internal>(InPadding:padding)<transacts>:void =
        set MyPadding = InPadding

    SetHorizontalAlignment<internal>(InHorizontalAlignment:alignment)<transacts>:void =
        set HorizontalAlignment = InHorizontalAlignment

    SetVerticalAlignment<internal>(InVerticalAlignment:alignment)<transacts>:void =
        set VerticalAlignment = InVerticalAlignment

    SetDistribution<internal>(InDistribution:?float)<transacts>:void =
        set MyDistribution = InDistribution

    SetParent<internal>(InParent:view)<transacts>:void =
        set ParentView = option {InParent}

    SetVisibility<internal>(InVisibility:visibility):void =
        OnBuildWidget().SetVisibility(ToWidgetVisibility(InVisibility))

    SetEnabled<internal>(InEnabled:logic):void =
        OnBuildWidget().SetEnabled(InEnabled)

# (InView:t).Bind<public>(InCancelable:cancelable where t:subtype(view)):t =
#     InView.AddCancelable(InCancelable)
#     return InView
