extends Node

@export var id: int
@onready var constants: = preload("res://shared/puzzle/constants.gd")
@onready var dragdrop_constants: = preload("res://autoload/dragdrop_manager/constants.gd")


func _ready() -> void :
    var host: = get_parent()
    host.set_meta(constants.PUZZLE_PIECE_REF, self)
    if host.has_meta(dragdrop_constants.DRAGGABLE_REF):
        var draggable: Draggable = host.get_meta(dragdrop_constants.DRAGGABLE_REF)
        var meta: Dictionary = draggable.metadata if draggable.metadata else {}
        meta.id = id
        draggable.metadata = meta
