using { /Verse.org/Simulation }

using { Signals }

view<public>:= class<abstract><transacts>:
    var Cancelables<internal>:[]cancelable = array {}
    var Children<public>:[]view = array {}
    var<private>ParentView<public>:?view = false

    var MyPadding<public>:padding = padding {}

    var HorizontalAlignment<public>:horizontal = horizontal.Center
    var VerticalAlignment<public>:vertical = vertical.Center

    var MyDistribution<public>:?float = false

    var<private> MountedPlayer:?player = false

    var BuiltWidget<internal>:?UEUI.widget = false

    var<internal> NativeBackgroundConstraints:?view = false
    var<internal> NativeForegroundConstraints:?view = false

    OnBuild<public>():view = Self

    IsInteractable<public>()<transacts><decides>:void = false

    HasInteractableChildren<public>()<transacts>:logic =
        if (IsInteractable[]):
            return true
        if (Bg := NativeBackgroundConstraints?, Bg.HasInteractableChildren()?):
            return true
        if (Fg := NativeForegroundConstraints?, Fg.HasInteractableChildren()?):
            return true
        for (Child : Children, Child.HasInteractableChildren()?):
            return true
        false

    UpdateChildSlot<public>(InChildView:view):void = {}

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
                
                Overlay.AddWidget(UEUI.overlay_slot { Widget := BaseW, Padding := UEUI.margin{Left:=0.0, Right:=0.0, Top:=0.0, Bottom:=0.0}, HorizontalAlignment := UEUI.horizontal_alignment.Fill, VerticalAlignment := UEUI.vertical_alignment.Fill })

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

    Dispose<final><public>():void =
        for (Cancelable : Cancelables) do:
            Cancelable.Cancel()

        for ((local:)Child : Children) do:
            (local:)Child.Dispose()

    SetPlayer<internal>(InPlayer:player):void =
        set MountedPlayer = option {InPlayer}

    GetPlayer<public>()<transacts><decides>:player =
        MountedPlayer? or ParentView?.GetPlayer[]
    
    GetParent<public>()<transacts><decides>:view =
        ParentView?

    SetBackground<internal>(InView:view):void =
        set NativeBackgroundConstraints = option {InView}

    SetForeground<internal>(InView:view):void =
        set NativeForegroundConstraints = option {InView}

    
    AddCancelable<final><public>(InCancelable:cancelable):void =
        set Cancelables = Cancelables + array {InCancelable}

    SetPadding<internal>(InPadding:padding)<transacts>:void =
        set MyPadding = InPadding

    SetHorizontalAlignment<internal>(InHorizontalAlignment:horizontal)<transacts>:void =
        set HorizontalAlignment = InHorizontalAlignment
    
    SetVerticalAlignment<internal>(InVerticalAlignment:vertical)<transacts>:void =
        set VerticalAlignment = InVerticalAlignment

    SetDistribution<internal>(InDistribution:?float)<transacts>:void =
        set MyDistribution = InDistribution
    
    SetVisibility<internal>(InVisibility:visibility):void =
        OnBuildWidget().SetVisibility(ToWidgetVisibility(InVisibility))
    
    SetEnabled<internal>(InEnabled:logic):void =
        OnBuildWidget().SetEnabled(InEnabled)

    SetParent<internal>(InParent:view)<transacts>:void =
        set ParentView = option {InParent}

