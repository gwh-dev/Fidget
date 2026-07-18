using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/UI }
using { /UnrealEngine.com/Temporary/SpatialMath }

using { Signals }

# ============================================================================
#  MOUNT SYSTEM — framework-owned per-player UI roots, one per layer.
#
#    ui_layer.HUD      z10, never consumes input (ambient overlay)
#    ui_layer.Screen   z20, panels and menus
#    ui_layer.Overlay  z30, toasts and popups on top of everything
#
#  Mount(Player, Root, Layer) replaces that layer's previous root (remount
#  safe), wraps the root in one native canvas and REMOVES THAT SAME WRAPPER
#  on Unmount — the wrapper is stored, never rebuilt, so nothing leaks.
#  A screen root stretches over the whole viewport; any other root is
#  centered and sized to content.
#
#  Input: HUD is always input-transparent. Other layers auto-detect from
#  HasInteractableChildren at mount time — or pass MountWithInput an
#  InputWhen signal: the layer is ON SCREEN (with full input) only while the
#  signal is true, and fully removed when it flips false. Removal is the
#  point — re-adding a widget with InputMode None does NOT release UEFN's
#  input capture (playtest-proven: players stayed frozen after panel close),
#  so the gated layer holds nothing that must stay visible when closed.
#
#  Storage is a session-keyed store (a module weak_map over players is
#  reserved for persistence), holding one slot per layer per player. Verse
#  maps cannot drop keys, so a leaver's emptied slot record stays in the map
#  and is reused on rejoin — bounded by distinct players per session.
# ============================================================================

ui_layer<public> := enum:
    HUD
    Screen
    Overlay

mounted_root<internal> := class:
    RootView<internal>:view
    WrapperCanvas<internal>:UEUI.canvas
    var InputEffect<internal>:?cancelable = false

player_mount_slots<internal> := class:
    var Roots<internal>:[ui_layer]?mounted_root = map{}

mount_store<internal> := class:
    var Slots<internal>:[player]player_mount_slots = map{}

var FidgetMounts<internal>:weak_map(session, mount_store) = map{}

GetMountStore<internal>()<transacts>:?mount_store =
    if (Existing := FidgetMounts[GetSession()]):
        return option{Existing}
    New := mount_store{}
    if (set FidgetMounts[GetSession()] = New):
        return option{New}
    false

GetPlayerMountSlots<internal>(Player:player)<transacts>:?player_mount_slots =
    if (Store := GetMountStore()?):
        if (Existing := Store.Slots[Player]):
            return option{Existing}
        New := player_mount_slots{}
        if (set Store.Slots[Player] = New):
            return option{New}
    false

GetLayerRoot<internal>(Slots:player_mount_slots, Layer:ui_layer)<transacts>:?mounted_root =
    Slots.Roots[Layer] or false

SetLayerRoot<internal>(Slots:player_mount_slots, Layer:ui_layer, NewRoot:?mounted_root):void =
    if {set Slots.Roots[Layer] = NewRoot}

MakeLayerSlot<internal>(Layer:ui_layer, InputMode:UEUI.ui_input_mode):UEUI.player_ui_slot =
    case (Layer):
        ui_layer.HUD => UEUI.player_ui_slot{ZOrder := 10, InputMode := InputMode}
        ui_layer.Screen => UEUI.player_ui_slot{ZOrder := 20, InputMode := InputMode}
        ui_layer.Overlay => UEUI.player_ui_slot{ZOrder := 30, InputMode := InputMode}

IsFullscreenRoot<internal>(Root:view)<transacts><decides>:void =
    screen[Root] or (Root.Children.Length = 1 and IsFullscreenRoot[Root.Children[0]])

MakeWrapperCanvas<internal>(Root:view):UEUI.canvas =
    NativeWidget := Root.Build()
    if (IsFullscreenRoot[Root]):
        UEUI.canvas:
            Slots := array:
                UEUI.canvas_slot:
                    Widget := NativeWidget
                    Anchors := UEUI.anchors{Minimum := vector2{X := 0.0, Y := 0.0}, Maximum := vector2{X := 1.0, Y := 1.0}}
                    Alignment := vector2{X := 0.0, Y := 0.0}
                    SizeToContent := false
    else:
        UEUI.canvas:
            Slots := array:
                UEUI.canvas_slot:
                    Widget := NativeWidget
                    Anchors := UEUI.anchors{Minimum := vector2{X := 0.5, Y := 0.5}, Maximum := vector2{X := 0.5, Y := 0.5}}
                    Alignment := vector2{X := 0.5, Y := 0.5}
                    SizeToContent := true

input_reslot_driver<internal> := class:
    DriverPlayer<internal>:player
    Wrapper<internal>:UEUI.canvas
    Layer<internal>:ui_layer
    InputWhen<internal>:signal_get(logic)
    var LastApplied<internal>:?logic = false
    var IsAdded<internal>:logic = false

    React<internal>():void =
        Wanted := InputWhen.Get()
        if (Applied := LastApplied?, Applied = Wanted):
            return
        if (PlayerUI := GetPlayerUI[DriverPlayer]):
            if (Wanted?):
                PlayerUI.AddWidget(Wrapper, MakeLayerSlot(Layer, UEUI.ui_input_mode.All))
            else if (IsAdded?):
                PlayerUI.RemoveWidget(Wrapper)
            set IsAdded = Wanted
            set LastApplied = option{Wanted}

ComputeMountInputMode<internal>(Root:view, Layer:ui_layer):UEUI.ui_input_mode =
    if (Layer = ui_layer.HUD):
        return UEUI.ui_input_mode.None
    Root.HasInteractableChildren()? and UEUI.ui_input_mode.All or UEUI.ui_input_mode.None

Mount<public>(Player:player, Root:view, Layer:ui_layer):void =
    Unmount(Player, Layer)
    if (PlayerUI := GetPlayerUI[Player], Slots := GetPlayerMountSlots(Player)?):
        Root.SetPlayer(Player)
        Wrapper := MakeWrapperCanvas(Root)
        PlayerUI.AddWidget(Wrapper, MakeLayerSlot(Layer, ComputeMountInputMode(Root, Layer)))
        SetLayerRoot(Slots, Layer, option{mounted_root{RootView := Root, WrapperCanvas := Wrapper}})

MountWithInput<public>(Player:player, Root:view, Layer:ui_layer, InputWhen:signal_get(logic)):void =
    Unmount(Player, Layer)
    if (Slots := GetPlayerMountSlots(Player)?):
        Root.SetPlayer(Player)
        Wrapper := MakeWrapperCanvas(Root)
        Driver := input_reslot_driver{DriverPlayer := Player, Wrapper := Wrapper, Layer := Layer, InputWhen := InputWhen}
        NewRoot := mounted_root{RootView := Root, WrapperCanvas := Wrapper}
        NewEffect := Effect(Driver.React)
        set NewRoot.InputEffect = option{NewEffect}
        SetLayerRoot(Slots, Layer, option{NewRoot})

Unmount<public>(Player:player, Layer:ui_layer):void =
    if (Store := GetMountStore()?, Slots := Store.Slots[Player], Mounted := GetLayerRoot(Slots, Layer)?):
        if (ActiveEffect := Mounted.InputEffect?):
            ActiveEffect.Cancel()
        if (PlayerUI := GetPlayerUI[Player]):
            PlayerUI.RemoveWidget(Mounted.WrapperCanvas)
        Mounted.RootView.Dispose()
        SetLayerRoot(Slots, Layer, false)

UnmountAll<public>(Player:player):void =
    Unmount(Player, ui_layer.HUD)
    Unmount(Player, ui_layer.Screen)
    Unmount(Player, ui_layer.Overlay)
