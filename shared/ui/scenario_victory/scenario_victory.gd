extends ColorRect

signal quit_to_menu_requested

@export var scenario_meta: ScenarioMeta
@onready var quit_to_menu_button: Button = % QuitToMenuButton
@onready var label: Label = % Label
@onready var sprite: Sprite2D = % Sprite2D

var _last_focus_owner: Control

func _ready() -> void :
    _last_focus_owner = get_viewport().gui_get_focus_owner()
    quit_to_menu_button.grab_focus()
    label.text = scenario_meta.victory_screen_text

    if not scenario_meta.victory_picture_path == "":
        sprite.texture = load(scenario_meta.victory_picture_path)


func _on_quit_to_menu_button_pressed() -> void :
    AudioManager.play(AudioManager.Sound.BUTTON_CLICK)
    quit_to_menu_requested.emit()
    hide()


func _on_continue_button_pressed() -> void :
    AudioManager.play(AudioManager.Sound.BUTTON_CLICK)
    _last_focus_owner.grab_focus()
    hide()


func _on_hidden() -> void :
    queue_free()
