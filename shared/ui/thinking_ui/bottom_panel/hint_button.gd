extends BaseButton

var dialog: = preload("res://shared/ui/hints/hint_main_menu.tscn")
var prev_focus_owner: Control

func _ready() -> void :
    pressed.connect(_on_pressed)


func _on_pressed() -> void :
    AudioManager.play(AudioManager.Sound.BUTTON_CLICK)

    var dialog_scene: Control = dialog.instantiate()
    dialog_scene.tree_exited.connect(
        func() -> void :
            if prev_focus_owner is Control:
                prev_focus_owner.grab_focus(), 
        CONNECT_ONE_SHOT, 
    )

    ProgressManager.dialog_layer.add_child(dialog_scene)
