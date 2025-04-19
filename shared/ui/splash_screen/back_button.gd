extends Button

@export var block_to_hide: Node


func _ready() -> void :
    block_to_hide.visible = false
    pressed.connect(_on_pressed)
    focus_entered.connect(_on_focus_entered)


func _on_pressed() -> void :
    block_to_hide.visible = false
    AudioManager.play(AudioManager.Sound.BUTTON_CLICK)


func _on_focus_entered() -> void :
    DialogManager.set_last_exploration_control(self)
