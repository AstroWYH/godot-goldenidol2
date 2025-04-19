class_name ContainerDragger
extends Control

signal dragging_started

var dragging: = false
var original_position: Vector2


@export var alternative_form: Control
@export var ideal_position: Vector2

@onready var host: Control = get_parent()


func _ready() -> void :
    host.gui_input.connect(on_host_gui_input)
    original_position = host.position


func on_host_gui_input(event: InputEvent) -> void :

    if not event is InputEventMouseButton:
        return

    if not event.button_index == MOUSE_BUTTON_LEFT:
        return

    if ProgressManager.victory_sequence_playing:
        return


    var event_position: Vector2 = get_global_mouse_position()
    if not dragging and event.pressed:

        get_viewport().set_input_as_handled()
        dragging = true
        ContainerDragAndDropManager.set_dragged_node(host, self, host.global_position - event_position, alternative_form)
        dragging_started.emit()
        return
