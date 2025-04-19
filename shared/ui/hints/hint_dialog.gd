extends ColorRect

var _prevous_focus: Control


func _ready() -> void :
    gui_input.connect(_on_gui_input)





    _prevous_focus = get_viewport().gui_get_focus_owner()
    call_deferred(&"_grab_initial_focus")


func _exit_tree() -> void :
    if is_instance_valid(_prevous_focus) and _prevous_focus is Control:
        _prevous_focus.grab_focus()


func _grab_initial_focus() -> void :
    var first_button: Variant = NodeUtils.get_first_of_type(self, "Button")
    if first_button is Button:
        first_button.grab_focus()


func _unhandled_input(_event: InputEvent) -> void :
    if GamepadUtils.back_pressed():
        get_viewport().set_input_as_handled()
        queue_free()
        return


func _on_gui_input(event: InputEvent) -> void :
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                queue_free()
