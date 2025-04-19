class_name PhraseGridSlot
extends Control

signal global_transform_changed

@export var keep_copy_on_drop: = true:
    set = set_keep_copy_on_drop
@export var track_item_usage: bool = false

@export var protect_slotted_draggable: bool = true:
    set = set_protect_slotted_draggable

var slotted_id: int:
    get = get_slotted_id
var obscured: bool:
    set = set_obscured

@onready var drop_receiver: DropReceiver = get_child(0)


func _ready() -> void :
    for tag: Phrase.PhraseType in Mappings.tag_map:
        var value: String = Mappings.tag_map[tag]
        drop_receiver.accept_tags.append(value)
    set_obscured(obscured)
    set_keep_copy_on_drop(keep_copy_on_drop)
    focus_entered.connect(_on_focus_entered)
    focus_exited.connect(_on_focus_exited)
    mouse_entered.connect(_on_mouse_entered)
    _on_focus_exited()

    if track_item_usage:
        ProgressManager.used_items_updated.connect(_on_used_items_updated)


func set_obscured(is_obscured: bool) -> void :
    obscured = is_obscured
    var target_focus_mode: FocusMode = FOCUS_NONE if obscured else FOCUS_ALL
    focus_mode = target_focus_mode

    drop_receiver.set_slotted_node_focus_mode(target_focus_mode)


func set_protect_slotted_draggable(v: bool) -> void :
    protect_slotted_draggable = v

    if not drop_receiver:
        return

    drop_receiver.protect_slotted_draggable = v


func _notification(what: int) -> void :
    if what != NOTIFICATION_TRANSFORM_CHANGED:
        return
    global_transform_changed.emit()


func get_slotted_id() -> int:
    return drop_receiver.slotted_id


func claim_phrase(phrase: Phrase) -> void :
    drop_receiver.claim_draggable(phrase.draggable)
    if track_item_usage:
        phrase.set_usage()


func free_draggable() -> void :
    if not drop_receiver:
        return
    drop_receiver.free_draggable()


func set_keep_copy_on_drop(v: bool) -> void :
    keep_copy_on_drop = v
    if drop_receiver:
        drop_receiver.keep_copy_on_drop = v



func request_focus_mode(new_focus_mode: Control.FocusMode) -> void :
    if new_focus_mode == Control.FOCUS_ALL and obscured == true:

        return

    drop_receiver.set_slotted_node_focus_mode(new_focus_mode)
    focus_mode = new_focus_mode


func _on_used_items_updated() -> void :
    if not drop_receiver.slotted_node:
        return

    var slotted_node: Node = drop_receiver.slotted_node

    if slotted_id == 0:
        return

    if not slotted_node is Phrase:
        return

    slotted_node.set_usage()


func _on_drop_receiver_draggable_dropped(drag_node: CanvasItem, _d: Draggable, action: DragAndDropManager.DropAction) -> void :
    if action != DragAndDropManager.DropAction.GAINED_DRAGGABLE:
        return

    if not drag_node is Phrase:
        return

    drag_node.set_usage()


func _on_focus_entered() -> void :
    self_modulate = Color.WHITE
    var slotted_draggable: Variant = drop_receiver.slotted_draggable
    if slotted_draggable is Draggable and slotted_draggable != DragAndDropManager.draggable_component:

        (slotted_draggable as Draggable).grab_host_focus()


func _on_focus_exited() -> void :
    self_modulate = Color.html("ffffff61")


func _on_mouse_entered() -> void :
    if focus_mode != FOCUS_ALL:
        return
    grab_focus()
