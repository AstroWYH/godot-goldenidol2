extends ColorRect

var hint_list: Array[HintMeta] = []
var _prevous_focus: Control

@onready var title_label: Label = % SectionTitleLabel
@onready var icon: TextureRect = % ContextualVisual
@onready var hint_container: Control = % HintContainer


func _ready() -> void :
    gui_input.connect(_on_gui_input)

    _prevous_focus = get_viewport().gui_get_focus_owner()
    call_deferred(&"_grab_initial_focus")

    var passed_icon: Texture
    if ProgressManager.current_scenario:
        for hint_meta: HintMeta in ProgressManager.current_scenario.scenario_meta.hint_meta_list:
            hint_list.append(hint_meta)

        title_label.text = ProgressManager.current_scenario.scenario_meta.name
        passed_icon = ProgressManager.current_scenario.scenario_meta.picture

    elif ProgressManager.current_chapter_meta:
        for hint_meta: HintMeta in ProgressManager.current_chapter_meta.hint_meta_list:
            hint_list.append(hint_meta)
        title_label.text = ProgressManager.current_chapter_meta.name
        passed_icon = ProgressManager.current_chapter_meta.picture

    if passed_icon:
        icon.texture = passed_icon

    for hint_meta in hint_list:
        var choice_button: BaseButton = load("res://shared/ui/hints/hint_choice_button_2.tscn").instantiate()
        choice_button.hint_path = hint_meta.path
        choice_button.hint_title = hint_meta.hint_name
        choice_button.hint_id = hint_meta.id
        hint_container.add_child(choice_button)
        choice_button.custom_minimum_size.x = 520


func _unhandled_input(_event: InputEvent) -> void :
    if GamepadUtils.back_pressed():
        get_viewport().set_input_as_handled()
        queue_free()
        return


func _exit_tree() -> void :
    if _prevous_focus is Control:
        _prevous_focus.grab_focus()


func _grab_initial_focus() -> void :
    var first_button: Variant = NodeUtils.get_first_of_type(self, "Button")
    if first_button is Button:
        first_button.grab_focus()


func _on_gui_input(event: InputEvent) -> void :
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                queue_free()
