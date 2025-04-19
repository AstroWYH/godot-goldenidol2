extends ColorRect

var hint_button_list: Array = []
var title: String
var previous_focus: Control

@onready var hint_button_parent: Control = % HintChoices
@onready var title_label: Label = % HintTitle

func _ready() -> void :


    gui_input.connect(_on_gui_input)
    if not previous_focus is Control:
        previous_focus = get_viewport().gui_get_focus_owner()

    title_label.text = title
    hint_button_list = hint_button_parent.get_children()
    var active_button: BaseButton
    for button: BaseButton in hint_button_list:
        button.pressed.connect(_on_hint_level_pressed.bind(button))
        if button.selected_by_default:
            active_button = button
    if active_button:
        set_button_active(active_button)
    call_deferred(&"_grab_initial_focus", active_button)


func _unhandled_input(_event: InputEvent) -> void :
    if GamepadUtils.back_pressed():
        get_viewport().set_input_as_handled()
        queue_free()
        return

func _on_gui_input(event: InputEvent) -> void :
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                queue_free()


func _exit_tree() -> void :
    if is_instance_valid(previous_focus) and previous_focus is Control:
        previous_focus.grab_focus()


func _grab_initial_focus(button_to_focus: Variant) -> void :
    var focus_target: Control

    if button_to_focus is Button:
        focus_target = button_to_focus
    else:
        focus_target = NodeUtils.get_first_of_type(self, "Button")

    if focus_target is Control:
        focus_target.grab_focus()


func set_button_active(active_button: BaseButton) -> void :
    for button: BaseButton in hint_button_list:
        button.disabled = false
        button.content.visible = false

    active_button.disabled = true
    active_button.content.visible = true


func _on_hint_level_pressed(pressed_button: BaseButton) -> void :
    AudioManager.play(AudioManager.Sound.BUTTON_CLICK)
    set_button_active(pressed_button)
