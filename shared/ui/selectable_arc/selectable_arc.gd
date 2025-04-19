@tool
extends Control



@onready var button: = $Button

@export var arc_meta: ArcMeta:
    set(v):
        arc_meta = v
        if not button:
            return
        button.text = v.name
@export var scene_root: Node


func _ready() -> void :
    if arc_meta:
        button.text = arc_meta.name


func _on_button_pressed() -> void :
    AudioManager.play(AudioManager.Sound.BUTTON_CLICK)
    ProgressManager.change_screen(arc_meta)
