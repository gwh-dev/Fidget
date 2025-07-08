using { /UnrealEngine.com/Temporary/UI }
using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }


UI := module {

    widget_component<public>:= class<abstract><final_super>(component) {
        Build():widget
        Update():void

        var MaybeWidget<final><private>:?widget = false

        GetWidget<final><protected>():widget = {
            return MaybeWidget? or Build()
        }

        SetWidget<final><protected>(Widget:widget):widget = {
            set MaybeWidget = option{Widget}
            return Widget
        }
    }

    widget_container_component<public>:= class<abstract>(widget_component) {
        AddWidget(Widget:widget):void
        RemoveWidget(Widget:widget):void
    }

    widget_padding_component := class<final><final_super>(component) {
        @editable
        var Left<private>:float = 0.0
        @editable
        var Right<private>:float = 0.0
        @editable
        var Top<private>:float = 0.0
        @editable
        var Bottom<private>:float = 0.0

        GetPadding<public>():margin = margin {
            Left := Left
            Right := Right
            Top := Top
            Bottom := Bottom
        }

        SetLeft<public>(InLeft:float):void = {
            set Left = InLeft
        }

        SetRight<public>(InRight:float):void = {
            set Right = InRight 
        }

        SetTop<public>(InTop:float):void = {
            set Top = InTop 
        }

        SetBottom<public>(InBottom:float):void = {
            set Bottom = InBottom 
        }
    }

    widget_alignment_compoennt := class<final><final_super>(component) {
        @editable
        var HorizontalAlignment<private>:horizontal_alignment = horizontal_alignment.Fill
        @editable
        var VerticalAlignment<private>:vertical_alignment = vertical_alignment.Fill

        GetHorizontal<private>():horizontal_alignment = {
            return HorizontalAlignment
        }

        GetVertical<private>():vertical_alignment = {
            return VerticalAlignment
        }

        SetHorizontal(Horizontal:horizontal_alignment):void = {
            set HorizontalAlignment = Horizontal
        }

        SetVertical(Vertical:vertical_alignment):void = {
            set VerticalAlignment = Vertical
        }
    }
}
