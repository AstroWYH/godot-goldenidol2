class_name DropReceiver
extends Control



signal unslotted
signal draggable_removed
signal draggable_dropped(drag_node: CanvasItem, draggable: Draggable, action: DragAndDropManager.DropAction)
signal draggable_claimed(host: CanvasItem, draggable: Draggable)


@export var accept_tags: Array[String] = []


@export var drop_radius: = 10.0


@export var hide_on_drop: = false


@export var keep_copy_on_drop: = false


@export var free_draggable_on_invalid_drop: bool


@export var read_only: bool


@export var duplicate_slotted_draggable_on_drag: bool



@export var protect_slotted_draggable: bool




@export var swap_on_valid_drop: bool



@export var accept_siblings_only: bool



@export var has_static_draggable: bool


@export var metadata: Dictionary

var host_size: Vector2:
    get: return host.size
var host_global_position: Vector2:
    get: return host.global_position
var slotted_node: Control
var slotted_draggable: Draggable
var slotted_id: int:
    get: return get_metadata().get("draggable", {}).get("id", 0)
var mouse_hovering: bool
var _host_mouse_hovering: bool
var _ignore_unslot: bool
var _dragging: bool



var receiver_data: DragAndDropManager.DropReceiverData


@onready var host: CanvasItem = get_parent()
@onready var constants: = preload("res://autoload/dragdrop_manager/constants.gd")
@onready var mouse_hotzone: = $MouseHotzone


func _ready() -> void :


    DragAndDropManager.register_as_drop_receiver(self, drop_radius)
    set_meta_ref()

    if host is Control:
        host.gui_input.connect(_on_host_gui_input)
        host.resized.connect(_update_mouse_hotzone_rect)
        host.mouse_entered.connect(_on_host_mouse_entered)
        host.mouse_exited.connect(_on_host_mouse_exited)
        call_deferred("_update_mouse_hotzone_rect")


    if has_static_draggable:
        var draggable: Draggable = NodeUtils.get_first_of_class_name(host, Draggable)
        if draggable:
            draggable.ready.connect(
                func() -> void : claim_draggable(draggable), 
                CONNECT_ONE_SHOT, 
            )




func check_draggable() -> void :
    var draggable: Draggable = NodeUtils.get_first_of_class_name(host, Draggable)
    if draggable:
        claim_draggable(draggable)


func _exit_tree() -> void :
    DragAndDropManager.unregister_drop_receiver(get_instance_id())


func _on_host_mouse_entered() -> void :
    _host_mouse_hovering = true


func _on_host_mouse_exited() -> void :
    _host_mouse_hovering = false


func _on_mouse_hotzone_mouse_entered() -> void :
    mouse_hovering = true


func _on_mouse_hotzone_mouse_exited() -> void :
    mouse_hovering = false


func _on_host_gui_input(event: InputEvent) -> void :


    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            var drag_start_valid: bool = DragAndDropManager.is_drag_start_valid(event)
            if not _dragging and drag_start_valid:
                if SettingsManager.get_click_to_drag() and not _host_mouse_hovering:

                    return
                _dragging = true

                if SettingsManager.get_click_to_drag():
                    _unslot()
                    return

            if _dragging and not drag_start_valid:
                _dragging = false

        if event.button_index == MOUSE_BUTTON_RIGHT and _host_mouse_hovering and not event.pressed and not read_only and free_draggable_on_invalid_drop:
            _remove_draggable()
            return

    if GamepadUtils.accept_pressed():
        if not _dragging and slotted_draggable:
            _unslot(true)
            return

    if GamepadUtils.back_pressed() and not read_only and slotted_draggable != null and not _dragging and free_draggable_on_invalid_drop and event is InputEventJoypadButton:
        _remove_draggable()
        get_viewport().set_input_as_handled()
        return

    if event is InputEventMouseMotion and _dragging:
        _unslot()




func get_metadata() -> Dictionary:
    var data: = {
        "slot": metadata, 
    }

    if slotted_draggable:
        data.draggable = slotted_draggable.metadata

    return data


func _remove_draggable() -> void :
    if not slotted_node:
        return
    free_draggable(true)
    draggable_removed.emit()


func _on_dragged_node_set(_dragged_node: CanvasItem, _draggable_component: Draggable) -> void :
    mouse_hotzone.show()


    if is_instance_valid(slotted_node) and slotted_node is Control:
        if not slotted_node.mouse_entered.is_connected(_on_mouse_hotzone_mouse_entered):
            slotted_node.mouse_entered.connect(_on_mouse_hotzone_mouse_entered)
        if not slotted_node.mouse_exited.is_connected(_on_mouse_hotzone_mouse_exited):
            slotted_node.mouse_exited.connect(_on_mouse_hotzone_mouse_exited)


func _on_dragged_node_moved(_node: CanvasItem, _draggable: Draggable, _new_pos: Vector2, _is_candidate: bool) -> void :
    pass


func _on_dragged_node_dropped(drag_node: CanvasItem, draggable: Draggable, action: DragAndDropManager.DropAction) -> void :
    mouse_hotzone.hide()
    if is_instance_valid(slotted_node) and slotted_node is Control:
        if slotted_node.mouse_entered.is_connected(_on_mouse_hotzone_mouse_entered):
            slotted_node.mouse_entered.disconnect(_on_mouse_hotzone_mouse_entered)
        if slotted_node.mouse_exited.is_connected(_on_mouse_hotzone_mouse_exited):
            slotted_node.mouse_exited.disconnect(_on_mouse_hotzone_mouse_exited)

    if action == DragAndDropManager.DropAction.GAINED_DRAGGABLE:
        claim_draggable(draggable)

    _ignore_unslot = false
    _dragging = false
    draggable_dropped.emit(drag_node, draggable, action)


func _on_accept_draggable_query(drag_node: CanvasItem, draggable: Draggable) -> bool:
    if not host.has_method("accept_draggable"):


        var not_protected: = true
        if slotted_node and slotted_node != draggable.host:

            not_protected = not protect_slotted_draggable

        return not_protected and not read_only

    return host.accept_draggable(drag_node, draggable)


func claim_draggable(draggable: Draggable) -> void :
    DragAndDropManager.claim_draggable(self, draggable)

    var new_draggable_host: = draggable.host


    slotted_node = new_draggable_host
    slotted_draggable = draggable

    if hide_on_drop:
        new_draggable_host.hide()

    draggable_claimed.emit(new_draggable_host, draggable)


func free_draggable(emit_unslotted: bool = false, unset_read_only: bool = false) -> void :
    if not slotted_node:
        return

    slotted_node.queue_free()
    slotted_node = null
    slotted_draggable = null
    _ignore_unslot = false

    if unset_read_only:
        read_only = false

    if emit_unslotted:
        unslotted.emit()


func set_infinite(infinite: bool) -> void :
    free_draggable_on_invalid_drop = infinite


func set_meta_ref() -> void :
    host.set_meta(constants.DROP_RECEIVER_REF, self)


func set_slotted_node_focus_mode(target_focus_mode: Control.FocusMode) -> void :
    if not slotted_node or not slotted_node is Control:
        return
    slotted_node.focus_mode = target_focus_mode


func set_host_focus_mode(target_focus_mode: Control.FocusMode) -> void :


    if host.has_method("request_focus_mode"):
        (host as Control).request_focus_mode(target_focus_mode)



func _unslot(via_gamepad: bool = false) -> void :
    if not slotted_node:
        return

    if read_only:
        if not duplicate_slotted_draggable_on_drag or _ignore_unslot:
            return

        var dupe: Control = DragAndDropManager.duplicate_draggable_host(slotted_node)
        var dupe_draggable: Draggable = dupe.get_meta(constants.DRAGGABLE_REF)

        dupe_draggable.owner_drop_receiver = self
        dupe.show()
        add_child(dupe)

        DragAndDropManager.set_dragged_node(dupe, dupe_draggable, via_gamepad)
        _ignore_unslot = true
        return

    if _ignore_unslot:
        return

    _ignore_unslot = true
    unslotted.emit()

    DragAndDropManager.set_dragged_node(slotted_node, slotted_draggable, via_gamepad)

    if hide_on_drop:
        slotted_node.show()


func _update_mouse_hotzone_rect() -> void :
    if not host:
        return

    var double_drop_radius: = drop_radius * 2
    mouse_hotzone.size = Vector2(
        (host.size.x as float) + double_drop_radius, 
        (host.size.y as float) + double_drop_radius, 
    )

    mouse_hotzone.global_position = Vector2(
        (host.global_position.x as float) - drop_radius, 
        (host.global_position.y as float) - drop_radius, 
    )
