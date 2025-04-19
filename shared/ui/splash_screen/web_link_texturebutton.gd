extends TextureButton

@export var url: String = ""


func _ready() -> void :
    pressed.connect(_on_pressed)
    mouse_entered.connect(_on_mouse_entered)


func _on_pressed() -> void :
    OS.shell_open(url)
    AudioManager.play(AudioManager.Sound.BUTTON_CLICK)


func _on_mouse_entered() -> void :
    if focus_mode != FOCUS_ALL:
        return
    grab_focus()
