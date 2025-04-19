extends ColorRect

@export var music_layers: Array[AudioStream]
@export var ambience_layers: Array[AudioStream]

var scrolling_complete: bool = false
var scroll_speed: int = 1
var faster_scroll_speed: int = 2

@onready var scroll_container: ScrollContainer = % ScrollContainer
@onready var credit_container: VBoxContainer = % AllCredits
@onready var prompt_label: Label = % PromptLabel
@onready var clickable_area: Control = % ClickableArea


func _ready() -> void :
    prompt_label.visible = false
    clickable_area.gui_input.connect(_on_gui_input)
    MusicPlayer.play_bg_audio(music_layers, ambience_layers)


func _process(_delta: float) -> void :
    if scrolling_complete:
        return

    if scroll_container.scroll_vertical >= credit_container.size.y - scroll_container.size.y:
        scrolling_complete = true
        prompt_label.visible = true
        return

    scroll_container.scroll_vertical += scroll_speed


func _unhandled_input(_event: InputEvent) -> void :
    if (GamepadUtils.accept_pressed() or GamepadUtils.back_pressed()):
        _handle_skip()
        get_viewport().set_input_as_handled()


func _on_gui_input(event: InputEvent) -> void :
    if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
        if event.pressed:
            _handle_skip()
            get_viewport().set_input_as_handled()


func _handle_skip() -> void :
    if scrolling_complete:
        ProgressManager.change_screen("res://shared/ui/thank_you.tscn")
        ProgressManager.save_final_credits_scene_shown()
        return

    scroll_speed = faster_scroll_speed
