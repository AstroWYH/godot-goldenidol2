extends Node






signal droppable_nodes_updated(data: Array[Dictionary])


@export var dynamic_container: = false


var _drop_receivers: Array[Node] = []

@onready var node_utils: NodeUtils = $ / root / NodeUtils
@onready var drag_manager: DragAndDropManager = $ / root / DragAndDropManager


func _ready() -> void :
    if not dynamic_container:
        query_drop_receivers()
    drag_manager.state_changed.connect(_on_drag_manager_state_changed)


func _on_drag_manager_state_changed() -> void :
    droppable_nodes_updated.emit(get_state())


func query_drop_receivers() -> void :
    _drop_receivers = node_utils.get_nodes_by_class_name(self, DropReceiver)


func get_state() -> Array:
    return _drop_receivers.map(
        func(rcvr: DropReceiver) -> Dictionary: return rcvr.get_metadata()
    )
