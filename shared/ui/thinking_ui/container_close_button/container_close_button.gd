extends Button



signal close_container(container: Control)

@onready var container: = get_parent()


func _ready() -> void :
    pressed.connect(_on_container_close_pressed)

    DragAndDropManager.dragged_node_set.connect(_change_focus_mode.bind(false))
    DragAndDropManager.dragged_node_released.connect(_change_focus_mode.bind(true))


func _on_container_close_pressed() -> void :
    var close_sound: = AudioManager.Sound.THINKING_CARD_CLICK
    if not AudioManager.is_playing_sound(close_sound):
        AudioManager.play(AudioManager.Sound.THINKING_CARD_CLICK)

    close_container.emit(container)


func _change_focus_mode(enable: bool) -> void :
    focus_mode = Control.FOCUS_ALL if enable else Control.FOCUS_NONE
