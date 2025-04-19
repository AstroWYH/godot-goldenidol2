@tool
extends Control



@export var scenario_meta: ScenarioMeta:
    set(v):
        scenario_meta = v
        if not button:
            return
        button.text = v.name
@export var disabled: bool:
    set(v):
        disabled = v
        if not button:
            return
        button.disabled = disabled
@export var scene_root: Node

@onready var button: = $Button


func _ready() -> void :
    if scenario_meta:
        button.text = scenario_meta.name
    button.disabled = disabled


func _on_button_pressed() -> void :
    AudioManager.play(AudioManager.Sound.BUTTON_CLICK)
    ProgressManager.change_screen(scenario_meta)
