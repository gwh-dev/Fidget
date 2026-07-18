using { /Verse.org/Colors }
using { /UnrealEngine.com/Temporary/SpatialMath }

using { Signals }

# ============================================================================
#  FRAMEWORK CONTROLS — spacer (the empty element; default OnRender target and
#  structural-view fallback via MakeEmpty) and fill_bar (a fraction signal
#  drives the fill width; the module-function + tuple payload EffectWith is
#  the closure substitute, so no driver class exists anywhere).
# ============================================================================

spacer<public> := class(view):
    OnBuildWidget<override>():UEUI.widget = UEUI.overlay{}

MakeEmpty<public>():view = spacer{}

FillBarReact<internal>(Data:tuple(color_image, float, float, signal_get(float))):void =
    RawValue := Data(3).Get()
    Clamped := RawValue < 0.0 and 0.0 or RawValue > 1.0 and 1.0 or RawValue
    Data(0).SetDesiredSize(vector2{X := Data(1) * Clamped, Y := Data(2)})

fill_bar<public> := class(view):
    Width<public>:float
    Height<public>:float
    BackColor<public>:color
    FillColor<public>:color
    Fraction<public>:signal_get(float)

    OnRender<override>():view =
        BackImage := color_image{DefaultColor := BackColor}.DesiredSize(vector2{X := Width, Y := Height})
        FillImage := color_image{DefaultColor := FillColor}.Alignment(horizontal.Left)
        FillImage.AddCancelable(EffectWith(FillBarReact, (FillImage, Width, Height, Fraction)))
        zstack{Children := array{BackImage, FillImage}}
