using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Simulation }
using { /Verse.org/Colors }
using { /Verse.org/Assets }

texture_image<public> := class(view, tintable, desired_sizeable, tileable):
    DefaultImage<public>:texture

    var<private>NativeTextureBlock<public>:?UEUI.texture_block = false

    GetWidget<internal>():UEUI.texture_block =
        if (TextureBlock := NativeTextureBlock?) then:
            TextureBlock
        else:
            NewTextureBlock := UEUI.texture_block {DefaultImage := DefaultImage}
            set NativeTextureBlock = option {NewTextureBlock}
            NewTextureBlock

    InternalBuildWidget<override>():UEUI.widget =
        GetWidget()

    SetTint<override>(InTint:color):void =
        GetWidget().SetTint(InTint)

    SetDesiredSize<override>(InSize:vector2):void =
        GetWidget().SetDesiredSize(InSize)

    SetTiling<override>(H:tiling, V:tiling):void =
        GetWidget().SetTiling(ToImageTiling(H), ToImageTiling(V))


material_image<public> := class(view, tintable, desired_sizeable):
    DefaultImage<public>:material

    var<private>NativeMaterialBlock<public>:?UEUI.material_block = false

    GetWidget<internal>():UEUI.material_block =
        if (MaterialBlock := NativeMaterialBlock?) then:
            MaterialBlock
        else:
            NewMaterialBlock := UEUI.material_block {DefaultImage := DefaultImage}
            set NativeMaterialBlock = option {NewMaterialBlock}
            NewMaterialBlock

    InternalBuildWidget<override>():UEUI.widget =
        GetWidget()

    SetTint<override>(InTint:color):void =
        GetWidget().SetTint(InTint)

    SetDesiredSize<override>(InSize:vector2):void =
        GetWidget().SetDesiredSize(InSize)


color_image<public> := class(view, colorable, opacity_able, desired_sizeable):
    DefaultColor<public>:color

    var<private>NativeColorBlock<public>:?UEUI.color_block = false

    GetWidget<internal>():UEUI.color_block =
        if (ColorBlock := NativeColorBlock?) then:
            ColorBlock
        else:
            NewColorBlock := UEUI.color_block {DefaultColor := DefaultColor}
            set NativeColorBlock = option {NewColorBlock}
            NewColorBlock

    InternalBuildWidget<override>():UEUI.widget =
        GetWidget()

    SetColor<override>(InColor:color):void =
        GetWidget().SetColor(InColor)

    SetOpacity<override>(InOpacity:opacity):void =
        GetWidget().SetOpacity(InOpacity)

    SetDesiredSize<override>(InSize:vector2):void =
        GetWidget().SetDesiredSize(InSize)
