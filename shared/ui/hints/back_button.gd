extends Button

@export var remove_this_on_click: Control = null


func _ready() -> void :
    pressed.connect(_on_pressed)
    mouse_entered.connect(_on_mouse_entered)
    focus_entered.connect(_on_mouse_entered)
    mouse_exited.connect(_on_mouse_exited)
    focus_exited.connect(_on_mouse_exited)
    text = tr("HINTS_BACK")


func _on_pressed() -> void :
    AudioManager.play(AudioManager.Sound.BUTTON_CLICK)
    if remove_this_on_click:
        remove_this_on_click.queue_free()


func _on_mouse_entered() -> void :
    position.y -= 5
    grab_focus()


func _on_mouse_exited() -> void :
    position.y += 5
