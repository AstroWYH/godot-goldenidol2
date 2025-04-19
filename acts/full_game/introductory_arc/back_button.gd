extends Button

@export var target_screen_path: String


func _ready() -> void :
	focus_entered.connect(_on_focus_entered)


func _on_pressed() -> void :
	release_focus()
	AudioManager.play(AudioManager.Sound.BUTTON_CLICK)
	ProgressManager.change_screen(target_screen_path)


func _on_focus_entered() -> void :
	DialogManager.set_last_exploration_control(self)
