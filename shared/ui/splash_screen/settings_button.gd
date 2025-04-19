extends Button


func _ready() -> void :
    mouse_entered.connect(_on_mouse_entered)


func _on_mouse_entered() -> void :
    if focus_mode != FOCUS_ALL:
        return
    grab_focus()
