using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/UI }

using { Signals }

view<public>:= class<abstract><unique><transacts>:
    var Cancelables<internal>:[]cancelable = array {}
    var Children<public>:[]view = array {}
    var<private>ParentView<public>:?view = false

    var PaddingValue<internal>:padding = padding {}

    var HorizontalAlignment<internal>:horizontal = horizontal.Center
    var VerticalAlignment<internal>:vertical = vertical.Center

    var DistributionValue<internal>:?float = false

    var<private> MountedPlayer:?player = false

    var BuiltWidget<internal>:?UEUI.widget = false

    var<internal> BackgroundLayer:?view = false
    var<internal> ForegroundLayer:?view = false

    # THE authoring hook: a composed element overrides OnRender and returns its
    # subtree. The default renders nothing. Native primitives override the
    # OnBuildWidget seam (containers) or OnBuildNativeWidget (typed leaves).
    OnRender<public>():view = spacer{}

    IsInteractable<public>()<transacts><decides>:void = false

    HasInteractableChildren<public>()<transacts>:logic =
        if (IsInteractable[]):
            return true
        if (Bg := BackgroundLayer?, Bg.HasInteractableChildren()?):
            return true
        if (Fg := ForegroundLayer?, Fg.HasInteractableChildren()?):
            return true
        for (Child : Children, Child.HasInteractableChildren()?):
            return true
        false

    OnUpdateChildSlot<public>(InChildView:view):void = {}

    Build<final><public>():UEUI.widget =
        if (W := BuiltWidget?) then:
            W
        else:
            BaseW := OnBuildWidget()
            if (BackgroundLayer? or ForegroundLayer?):
                Overlay := UEUI.overlay {}
                if (Bg := BackgroundLayer?):
                    Bg.SetParent(Self)
                    Overlay.AddWidget(UEUI.overlay_slot { Widget := Bg.Build(), Padding := BuildMargin(Bg), HorizontalAlignment := BuildHorizontalAlignment(Bg), VerticalAlignment := BuildVerticalAlignment(Bg) })

                Overlay.AddWidget(UEUI.overlay_slot { Widget := BaseW, Padding := UEUI.margin{Left:=0.0, Right:=0.0, Top:=0.0, Bottom:=0.0}, HorizontalAlignment := UEUI.horizontal_alignment.Fill, VerticalAlignment := UEUI.vertical_alignment.Fill })

                if (Fg := ForegroundLayer?):
                    Fg.SetParent(Self)
                    Overlay.AddWidget(UEUI.overlay_slot { Widget := Fg.Build(), Padding := BuildMargin(Fg), HorizontalAlignment := BuildHorizontalAlignment(Fg), VerticalAlignment := BuildVerticalAlignment(Fg) })

                set BuiltWidget = option {Overlay}
                Overlay
            else:
                set BuiltWidget = option {BaseW}
                BaseW

    # The build seam Build() realizes through. The default realizes OnRender's
    # subtree — parented and tracked in Children so Dispose, GetPlayer and
    # HasInteractableChildren all see through it. Container primitives override
    # this directly and wrap their UEUI widget; typed leaves ride view_native.
    # An OnRender override returning Self is a misuse — caught and stubbed.
    OnBuildWidget<protected>():UEUI.widget =
        Composed := OnRender()
        if (Composed = Self):
            Print("Fidget View: OnRender must return a composed subtree, not Self.")
            return UEUI.overlay{}
        Composed.SetParent(Self)
        set Children = array{Composed}
        Composed.Build()

    Dispose<final><public>():void =
        for (Cancelable : Cancelables) do:
            Cancelable.Cancel()

        for ((local:)Child : Children) do:
            (local:)Child.Dispose()

        if (Bg := BackgroundLayer?):
            Bg.Dispose()
        if (Fg := ForegroundLayer?):
            Fg.Dispose()

    SetPlayer<internal>(InPlayer:player):void =
        set MountedPlayer = option {InPlayer}

    GetPlayer<public>()<transacts><decides>:player =
        MountedPlayer? or ParentView?.GetPlayer[]

    GetParent<public>()<transacts><decides>:view =
        ParentView?

    SetBackground<internal>(InView:view):void =
        set BackgroundLayer = option {InView}

    SetForeground<internal>(InView:view):void =
        set ForegroundLayer = option {InView}

    AddCancelable<final><public>(InCancelable:cancelable):void =
        set Cancelables = Cancelables + array {InCancelable}

    SetPadding<internal>(InPadding:padding)<transacts>:void =
        set PaddingValue = InPadding

    SetHorizontalAlignment<internal>(InHorizontalAlignment:horizontal)<transacts>:void =
        set HorizontalAlignment = InHorizontalAlignment

    SetVerticalAlignment<internal>(InVerticalAlignment:vertical)<transacts>:void =
        set VerticalAlignment = InVerticalAlignment

    SetDistribution<internal>(InDistribution:?float)<transacts>:void =
        set DistributionValue = InDistribution

    SetVisibility<internal>(InVisibility:visibility):void =
        Build().SetVisibility(ToWidgetVisibility(InVisibility))

    SetEnabled<internal>(InEnabled:logic):void =
        Build().SetEnabled(InEnabled)

    SetParent<internal>(InParent:view)<transacts>:void =
        set ParentView = option {InParent}

# The generic base for every native-widget LEAF primitive: owns the typed
# lazy cache and the build seam ONCE. A primitive overrides only
# OnBuildNativeWidget (its native constructor) plus its Set* forwarders over
# GetWidget(). Naming pairs hooks with caches: Build fills BuiltWidget via
# OnBuildWidget; GetWidget fills BuiltNativeWidget via OnBuildNativeWidget —
# and the seam override routes Build through the same cache, so setters
# firing before Build and Build itself always touch ONE native widget.
view_native<public>(t:subtype(widget)) := class<abstract>(view):
    var<private>BuiltNativeWidget:?t = false

    OnBuildNativeWidget():t

    GetWidget<internal>():t =
        if (Existing := BuiltNativeWidget?):
            Existing
        else:
            New := OnBuildNativeWidget()
            set BuiltNativeWidget = option{New}
            New

    OnBuildWidget<override>():UEUI.widget = GetWidget()
