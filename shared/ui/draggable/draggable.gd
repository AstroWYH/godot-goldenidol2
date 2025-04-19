class_name Draggable
extends Control




@export var metadata: Dictionary


@export var tag: String = ""


@export var slotted_layout_preset: LayoutPreset = PRESET_CENTER

var dragging: = false

var owner_drop_receiver: DropReceiver
var global_reset_position: Vector2
var mouse_on: bool = false

@onready var host: Control = get_parent()
@onready var constants: = preload("res://autoload/dragdrop_manager/constants.gd")


func _ready() -> void :

    global_reset_position = host.global_position
    host.z_as_relative = false
    host.set_meta(constants.DRAGGABLE_REF, self)
    if host is Control:
        host.gui_input.connect(handle_host_gui_input)
        host.mouse_entered.connect(handle_host_mouse_changed.bind(true))
        host.mouse_exited.connect(handle_host_mouse_changed.bind(false))


func _notification(what: int) -> void :
    if what != NOTIFICATION_APPLICATION_FOCUS_OUT:
        return
    dragging = false


func grab_host_focus() -> void :
    if host and host is Control:
        host.grab_focus()


func handle_host_gui_input(event: InputEvent) -> void :
    if owner_drop_receiver and owner_drop_receiver.read_only:
        return

    if GamepadUtils.accept_pressed():
        if not dragging:
            dragging = true
            DragAndDropManager.set_dragged_node(host, self, true)
            get_viewport().set_input_as_handled()
            return

    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if not dragging and DragAndDropManager.is_drag_start_valid(event):
            if SettingsManager.get_click_to_drag() and not mouse_on:

                return
            dragging = true
            DragAndDropManager.set_dragged_node(host, self)
            get_viewport().set_input_as_handled()
            return


func handle_host_mouse_changed(hovering: bool) -> void :
    mouse_on = hovering
