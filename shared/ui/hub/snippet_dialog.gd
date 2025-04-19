extends ColorRect
class_name SnippetDialog

@export var sequence_element_id: String


func _unhandled_input(_event: InputEvent) -> void :
    if GamepadUtils.back_pressed() or GamepadUtils.accept_pressed():
        get_viewport().set_input_as_handled()
        _close_dialog()


func _on_gui_input(event: InputEvent) -> void :
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                _close_dialog()


func _close_dialog() -> void :
    if len(sequence_element_id):
        SequenceManager.mark_handled(sequence_element_id)
    queue_free()
