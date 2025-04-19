extends Button

@export var chapter_meta: ArcMeta


func _ready() -> void :
    if not ResourceLoader.exists(chapter_meta.hub_scene_path):
        disabled = true
        return
    pressed.connect(_on_pressed)
    mouse_entered.connect(_on_mouse_entered)


func _unhandled_input(_event: InputEvent) -> void :
    GamepadUtils.handle_confirm(self, _on_pressed)


func _on_pressed() -> void :
    release_focus()
    AudioManager.play(AudioManager.Sound.BUTTON_CLICK)
    ProgressManager.change_screen(chapter_meta)


func _on_mouse_entered() -> void :
    if focus_mode != FOCUS_ALL:
        return
    grab_focus()
