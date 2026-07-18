using { /UnrealEngine.com/Temporary/SpatialMath }

# ============================================================================
#  SCREEN PLACEMENT AS VIEWS — anchoring lives in the tree, not in mount code.
#
#  screen builds one native canvas; each child gets a proportional slot.
#  Wrap a child in anchored (or the .At/.AtAligned sugar) to place it; bare
#  children land centered. A screen mounted as a root stretches over the whole
#  viewport (Mount detects it), and nested inside another view it behaves as
#  a regular sized canvas.
# ============================================================================

anchored<public> := class(view):
    Child<public>:view
    Anchor<public>:vector2 = vector2{X := 0.5, Y := 0.5}
    Alignment<public>:vector2 = vector2{X := 0.5, Y := 0.5}

    block:
        set Children = array{Child}

    OnBuildWidget<override>():UEUI.widget =
        Child.SetParent(Self)
        Child.Build()

(InView:view).At<public>(X:float, Y:float):anchored =
    anchored{Child := InView, Anchor := vector2{X := X, Y := Y}, Alignment := vector2{X := X, Y := Y}}

(InView:view).AtAligned<public>(X:float, Y:float, AlignX:float, AlignY:float):anchored =
    anchored{Child := InView, Anchor := vector2{X := X, Y := Y}, Alignment := vector2{X := AlignX, Y := AlignY}}

screen<public> := class(view):
    OnBuildWidget<override>():UEUI.widget =
        for (Child : Children):
            Child.SetParent(Self)
        Slots : []UEUI.canvas_slot = for (Child : Children):
            MakeScreenSlot(Child)
        UEUI.canvas{Slots := Slots}

    MakeScreenSlot<private>(Child:view):UEUI.canvas_slot =
        if (Placed := anchored[Child]):
            UEUI.canvas_slot{
                Anchors := UEUI.anchors{Minimum := Placed.Anchor, Maximum := Placed.Anchor},
                Alignment := Placed.Alignment,
                SizeToContent := true,
                Widget := Child.Build()
            }
        else:
            UEUI.canvas_slot{
                Anchors := UEUI.anchors{Minimum := vector2{X := 0.5, Y := 0.5}, Maximum := vector2{X := 0.5, Y := 0.5}},
                Alignment := vector2{X := 0.5, Y := 0.5},
                SizeToContent := true,
                Widget := Child.Build()
            }
