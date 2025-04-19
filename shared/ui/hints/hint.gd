extends Label


var revealed: bool = false

@onready var expand_button: Button = % ExpandButton
@onready var frame: MarginContainer = % Frame
@onready var expand_block: Control = % ExpandBlock

func _ready() -> void :

    expand_button.pressed.connect(_on_expand_pressed)

    if not revealed:
        self_modulate = Color(1, 1, 1, 0)
        frame.modulate = Color(1, 1, 1, 0)
        expand_block.visible = true


func _on_expand_pressed() -> void :
    AudioManager.play(AudioManager.Sound.BUTTON_CLICK)
    revealed = true
    self_modulate = Color(1, 1, 1, 1)
    frame.modulate = Color(1, 1, 1, 1)
    expand_block.visible = false
