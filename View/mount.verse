using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/UI }
using { /UnrealEngine.com/Temporary/SpatialMath }

# A simple mount system abstracting UEFN player UI 
MountUI<public>(Player:player, RootView:view, ZOrder:type{_X:int where 0 <= _X, _X <= 2147483647}):void =
    if (PlayerUI := GetPlayerUI[Player]) then:
        RootView.SetPlayer(Player)
        NativeWidget := RootView.OnBuildWidget()
        
        # Wrap in a canvas to prevent stretching across the whole screen and center it.
        RootCanvas := UEUI.canvas:
            Slots := array:
                UEUI.canvas_slot:
                    Widget := NativeWidget
                    Anchors := UEUI.anchors{Minimum := vector2{X:=0.5, Y:=0.5}, Maximum := vector2{X:=0.5, Y:=0.5}}
                    Alignment := vector2{X:=0.5, Y:=0.5}
                    SizeToContent := true
        
        InputMode := if (RootView.HasInteractableChildren()?) then ui_input_mode.All else ui_input_mode.None
        PlayerUI.AddWidget(RootCanvas, UEUI.player_ui_slot {ZOrder := ZOrder, InputMode := InputMode})

UnmountUI<public>(Player:player, RootView:view):void =
    if (PlayerUI := GetPlayerUI[Player]) then:
        if (NativeWidget := RootView.BuiltWidget?):
            PlayerUI.RemoveWidget(NativeWidget)
            RootView.Dispose()
