using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/UI }

# A simple mount system abstracting UEFN player UI 
MountUI<public>(Player:player, RootView:view, ZOrder:type{_X:int where 0 <= _X, _X <= 2147483647}):void =
    if (PlayerUI := GetPlayerUI[Player]) then:
        RootView.SetPlayer(Player)
        NativeWidget := RootView.OnBuildWidget()
        PlayerUI.AddWidget(NativeWidget, UEUI.player_ui_slot {ZOrder := ZOrder})

UnmountUI<public>(Player:player, RootView:view):void =
    if (PlayerUI := GetPlayerUI[Player]) then:
        if (NativeWidget := RootView.BuiltWidget?):
            PlayerUI.RemoveWidget(NativeWidget)
            RootView.Dispose()
