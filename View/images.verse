using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Simulation }
using { /Verse.org/Colors }
using { /Verse.org/Assets }

# ============================================================================
#  IMAGE PRIMITIVES — texture, material and flat-color blocks on the generic
#  view_native(t) base: OnBuildNativeWidget + one-line Set* forwarders each.
# ============================================================================

texture_image<public> := class(view_native(UEUI.texture_block), tintable, desired_sizeable, tileable):
    DefaultImage<public>:texture

    OnBuildNativeWidget<override>():UEUI.texture_block = UEUI.texture_block{DefaultImage := DefaultImage}

    SetTint<override>(InTint:color):void = GetWidget().SetTint(InTint)
    SetDesiredSize<override>(InSize:vector2):void = GetWidget().SetDesiredSize(InSize)
    SetTiling<override>(H:tiling, V:tiling):void = GetWidget().SetTiling(ToImageTiling(H), ToImageTiling(V))

material_image<public> := class(view_native(UEUI.material_block), tintable, desired_sizeable):
    DefaultImage<public>:material

    OnBuildNativeWidget<override>():UEUI.material_block = UEUI.material_block{DefaultImage := DefaultImage}

    SetTint<override>(InTint:color):void = GetWidget().SetTint(InTint)
    SetDesiredSize<override>(InSize:vector2):void = GetWidget().SetDesiredSize(InSize)

color_image<public> := class(view_native(UEUI.color_block), colorable, opacity_able, desired_sizeable):
    DefaultColor<public>:color

    OnBuildNativeWidget<override>():UEUI.color_block = UEUI.color_block{DefaultColor := DefaultColor}

    SetColor<override>(InColor:color):void = GetWidget().SetColor(InColor)
    SetOpacity<override>(InOpacity:opacity):void = GetWidget().SetOpacity(InOpacity)
    SetDesiredSize<override>(InSize:vector2):void = GetWidget().SetDesiredSize(InSize)
