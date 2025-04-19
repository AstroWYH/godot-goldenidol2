class_name PuzzleComponent
extends Node


signal value_updated(value: Variant)

const HOST_VALUE_METHOD = "get_puzzle_component_value"


@export var id: int




@export var valid_by_default: = false

@onready var dragdrop_constants: = preload("res://autoload/dragdrop_manager/constants.gd")
@onready var puzzle_constants: = preload("res://shared/puzzle/constants.gd")
@onready var host: Node = get_parent()

var value: int:
    get = _get_value
var local_value: Variant

var drop_receiver: DropReceiver
var _prev_local_value: Variant = null



func integrate() -> void :
    if host.has_meta(dragdrop_constants.DROP_RECEIVER_REF):
        connect_drop_receiver(host.get_meta(dragdrop_constants.DROP_RECEIVER_REF) as DropReceiver)
    set_ref_meta()


func _get_value() -> Variant:
    if host.has_method(HOST_VALUE_METHOD):
        return host.call(HOST_VALUE_METHOD)

    return local_value


func set_ref_meta() -> void :
    host.set_meta(puzzle_constants.PUZZLE_COMPONENT_REF, self)


func connect_drop_receiver(hosts_drop_receiver: DropReceiver) -> void :
    drop_receiver = hosts_drop_receiver
    drop_receiver.draggable_dropped.connect(_on_draggable_dropped)
    drop_receiver.draggable_removed.connect(_on_draggable_removed)
    var slotted_id: int = drop_receiver.slotted_id
    if slotted_id > 0:
        local_value = slotted_id
        _prev_local_value = local_value


func _emit_slotted_value() -> void :
    var slotted_id: int = drop_receiver.slotted_id

    @warning_ignore("incompatible_ternary")
    local_value = null if not slotted_id else slotted_id

    if local_value != _prev_local_value:
        value_updated.emit(local_value)
        _prev_local_value = local_value


func _on_draggable_removed() -> void :
    if not drop_receiver:
        return
    _emit_slotted_value()


func _on_draggable_dropped(_drag_node: CanvasItem, _d: Draggable, _a: DragAndDropManager.DropAction) -> void :


    if not drop_receiver:
        return

    _emit_slotted_value()
