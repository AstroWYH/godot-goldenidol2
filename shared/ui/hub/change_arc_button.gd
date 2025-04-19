extends Button


@export var arc_meta: ArcMeta


func _ready() -> void :
    if ProgressManager.arc_visited(arc_meta.id):
        visible = true
    else:
        visible = false
        return
    pressed.connect(on_pressed)


func on_pressed() -> void :
    release_focus()
    if arc_meta:
        AudioManager.play(AudioManager.Sound.BUTTON_CLICK)
        ProgressManager.change_screen(arc_meta)
        return
