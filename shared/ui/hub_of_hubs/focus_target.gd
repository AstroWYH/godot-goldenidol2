extends Control

const FOCUS_METHOD: StringName = &"focus_changed"
const ACCEPT_METHOD: StringName = &"accept_requested"

@onready var host: Control = get_parent()

var _focus_indicator_texturerect: TextureRect


func _ready() -> void :

    host.focus_mode = Control.FOCUS_NONE
    focus_entered.connect(_on_focus_changed.bind(true))
    focus_exited.connect(_on_focus_changed.bind(false))

    if host is TextureButton:

        _focus_indicator_texturerect = TextureRect.new()
        _focus_indicator_texturerect.texture = host.texture_focused
        _focus_indicator_texturerect.size = host.size
        _focus_indicator_texturerect.custom_minimum_size = host.custom_minimum_size
        _focus_indicator_texturerect.hide()
        host.call_deferred(&"add_child", _focus_indicator_texturerect)


func _gui_input(_event: InputEvent) -> void :
    if GamepadUtils.accept_pressed():
        host.call(ACCEPT_METHOD)
        get_viewport().set_input_as_handled()


func _on_focus_changed(focused: bool) -> void :
    if host is TextureButton and _focus_indicator_texturerect:
        _focus_indicator_texturerect.visible = focused
        _focus_indicator_texturerect.z_index = 10 if focused else 0
    host.call(FOCUS_METHOD, focused)
