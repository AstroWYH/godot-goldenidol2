extends ColorRect

const SCROLL_SPEED: int = 1000


@onready var back_button: Control = % BackButton
@onready var scroll_container: ScrollContainer = % ScrollContainer


func _ready() -> void :
    back_button.grab_focus()


func _process(delta: float) -> void :
    var x1: float = Input.get_action_strength(GamepadUtils.ACTION_UI_UP)
    var x2: float = Input.get_action_strength(GamepadUtils.ACTION_UI_DOWN)
    scroll_container.scroll_vertical += int((x2 - x1) * SCROLL_SPEED * delta)
