extends TextureButton

signal switch_pressed(toggled_on: bool)

const AnimationState: = preload("res://shared/ui/thinking_ui/animation_state.gd")
const TX_CLOSED: Texture2D = preload("res://shared/assets/placeholder_ui/switch_closed_small.png")
const TX_OPEN: Texture2D = preload("res://shared/assets/placeholder_ui/switch_open_small.png")

var expanded: bool = false


func _ready() -> void :
    _set_texture()


func set_switch(state: int) -> void :
    match state:
        0:
            disabled = true
            expanded = false
        1:
            disabled = false
            expanded = false
            set_pressed_no_signal(expanded)
        2:
            disabled = false
            expanded = true
            set_pressed_no_signal(expanded)

    mouse_default_cursor_shape = CursorShape.CURSOR_ARROW if state == 0 else CursorShape.CURSOR_POINTING_HAND

    _set_texture()


func _on_pressed() -> void :
    if AnimationState.animating:
        return

    var new_state: = not expanded

    AnimationState.mark_as_animating(self)
    switch_pressed.emit(new_state)

    if not disabled:
        if new_state == true:
            AudioManager.play(AudioManager.Sound.THINKING_TOGGLE_ON)
        else:
            AudioManager.play(AudioManager.Sound.THINKING_TOGGLE_OFF)

    _set_texture()


func _set_texture() -> void :


    texture_normal = TX_OPEN if expanded else TX_CLOSED
