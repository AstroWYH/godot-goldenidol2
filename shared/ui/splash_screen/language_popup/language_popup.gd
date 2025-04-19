extends CanvasLayer


@onready var close_button: Button = % CloseButton
@onready var ingame_lang_switcher: OptionButton = % IngameLanguageSwitcher


func _ready() -> void :
    close_button.pressed.connect(_on_close_button_pressed)
    close_button.gui_input.connect(_on_close_button_gui_input)
    visibility_changed.connect(_on_visibility_changed)


func _unhandled_input(_event: InputEvent) -> void :
    if not visible:
        return

    if GamepadUtils.back_pressed():
        hide()
        get_viewport().set_input_as_handled()
        return



    if ingame_lang_switcher.is_visible_in_tree():
        GamepadUtils.handle_confirm(ingame_lang_switcher, ingame_lang_switcher.show_popup)
        return

    if not Input.is_action_just_pressed("ui_cancel"):
        return

    hide()
    get_viewport().set_input_as_handled()


func _on_close_button_pressed() -> void :
    hide()


func _on_visibility_changed() -> void :
    if visible:
        ingame_lang_switcher.grab_focus()


func _on_close_button_gui_input(_event: InputEvent) -> void :
    GamepadUtils.handle_confirm(close_button, hide)


func _on_color_rect_gui_input(event: InputEvent) -> void :
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                hide()
