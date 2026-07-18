
opacity<public> := type{_X:float where 0.000000 <= _X, _X <= 1.000000}

padding<public>:= struct:
    Top:float = 0.0
    Left:float = 0.0
    Right:float = 0.0
    Bottom:float = 0.0

MakePadding<public>(InPadding:padding):padding = InPadding

horizontal<public>:= enum:
    Fill
    Center
    Left
    Right

vertical<public>:= enum:
    Fill
    Center
    Top
    Bottom

visibility<public>:= enum:
    Visible
    Collapsed
    Hidden

tiling<public>:= enum:
    Stretch
    Repeat

justification<public>:= enum:
    Left
    Center
    Right
    InvariantLeft
    InvariantRight

overflow_policy<public>:= enum:
    Clip
    Ellipsis

ToWidgetVisibility<public>(V:visibility):UEUI.widget_visibility =
    case(V):
        visibility.Visible => UEUI.widget_visibility.Visible
        visibility.Collapsed => UEUI.widget_visibility.Collapsed
        visibility.Hidden => UEUI.widget_visibility.Hidden

ToImageTiling<public>(V:tiling):UEUI.image_tiling =
    case(V):
        tiling.Stretch => UEUI.image_tiling.Stretch
        tiling.Repeat => UEUI.image_tiling.Repeat

ToTextJustification<public>(V:justification):UEUI.text_justification =
    case(V):
        justification.Left => UEUI.text_justification.Left
        justification.Center => UEUI.text_justification.Center
        justification.Right => UEUI.text_justification.Right
        justification.InvariantLeft => UEUI.text_justification.InvariantLeft
        justification.InvariantRight => UEUI.text_justification.InvariantRight

ToTextOverflowPolicy<public>(V:overflow_policy):UEUI.text_overflow_policy =
    case(V):
        overflow_policy.Clip => UEUI.text_overflow_policy.Clip
        overflow_policy.Ellipsis => UEUI.text_overflow_policy.Ellipsis
