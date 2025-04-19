extends Button



func _on_pressed() -> void :
    get_viewport().set_input_as_handled()
    get_parent().visible = false
