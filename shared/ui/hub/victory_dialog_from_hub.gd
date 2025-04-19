extends ColorRect

@onready var label: Label = % Label
@onready var sprite: Sprite2D = % Sprite2D

var _caller: Control


func configure(scenario_meta: ScenarioMeta, caller: Control) -> void :
    label.text = scenario_meta.victory_screen_text
    sprite.texture = load(scenario_meta.victory_picture_path)
    _caller = caller


func _unhandled_input(_event: InputEvent) -> void :
    if GamepadUtils.back_pressed() or GamepadUtils.accept_pressed():
        _close()


func _on_gui_input(event: InputEvent) -> void :
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                _close()


func _close() -> void :
    get_viewport().set_input_as_handled()
    queue_free()
    _caller.grab_focus()
