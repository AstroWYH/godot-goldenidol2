extends ColorRect


var tween: Tween
var animation_length: float = 1.5
var wait_length: float = 1.0
var full_color: Color = Color(1, 1, 1, 1)
var invisible_color: Color = Color(1, 1, 1, 0)
var active_element: Control
var leaving_scene: bool = false
var splash_screen_packed: PackedScene = preload("res://shared/ui/scenario_select/scenario_select.tscn")
var showing_first_logo: bool = true


@onready var color_gray_logo: VBoxContainer = % ColorGrayLogoBlock
@onready var playstack_logo: VBoxContainer = % PlaystackLogoBlock

func _ready() -> void :
    grab_focus()
    color_gray_logo.modulate = invisible_color
    playstack_logo.modulate = invisible_color
    active_element = color_gray_logo
    fade_up_logo(active_element, animation_length)


func _input(event: InputEvent) -> void :
    if GamepadUtils.handle_confirm(self, _force_exit):
        return

    if GamepadUtils.handle_back(self, _force_exit):
        return

    if not event is InputEventMouseButton:
        return

    if not event.button_index == MOUSE_BUTTON_LEFT:
        return

    if not event.is_pressed():
        return

    if showing_first_logo:
        color_gray_logo.visible = false
        active_element = playstack_logo
        fade_up_logo(active_element, animation_length)
        showing_first_logo = false
    else:
        _force_exit()



func _force_exit() -> void :

    if leaving_scene:
        return
    leaving_scene = true
    fade_out_logo(active_element, animation_length / 2)


func fade_up_logo(element: Control, length: float) -> void :
    tween = get_tree().create_tween()
    tween.tween_property(element, "modulate", full_color, length)
    tween.finished.connect(_on_fadeup_done.bind(element))


func fade_out_logo(element: Control, length: float) -> void :
    tween = get_tree().create_tween()
    tween.tween_property(element, "modulate", invisible_color, length)
    tween.finished.connect(_on_fadeout_done)


func _on_fadeup_done(element: Control) -> void :
    await get_tree().create_timer(wait_length).timeout

    if element == color_gray_logo:
        active_element = color_gray_logo
    else:
        active_element = playstack_logo
        leaving_scene = true
    fade_out_logo(active_element, animation_length)


func _on_fadeout_done() -> void :
    if is_queued_for_deletion():
        return

    if leaving_scene:
        tween.kill()
        var splash_screen: Node = splash_screen_packed.instantiate()
        get_tree().root.add_child(splash_screen)
        queue_free()
        return

    await get_tree().create_timer(wait_length).timeout
    showing_first_logo = false
    active_element = playstack_logo
    fade_up_logo(active_element, animation_length)
