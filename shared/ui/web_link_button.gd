extends Button

@export var url: String = ""


func _ready() -> void :
    pressed.connect(_on_pressed)


func _on_pressed() -> void :
    OS.shell_open(url)
    AudioManager.play(AudioManager.Sound.BUTTON_CLICK)
