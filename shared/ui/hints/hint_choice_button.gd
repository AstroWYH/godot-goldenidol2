extends Button

var locked: bool = true
var hint_title: String
var hint_path: String
var hint_id: int

func _ready() -> void :
    pressed.connect(_on_pressed)


func _on_pressed() -> void :
    AudioManager.play(AudioManager.Sound.BUTTON_CLICK)
    if len(hint_path):
        var new_dialog: Control = load(hint_path).instantiate()
        new_dialog.title = hint_title
        ProgressManager.dialog_layer.add_child(new_dialog)
