extends Node






signal state_changed
signal dragged_node_set
signal dragged_node_released
signal refocused_post_drop(new_focus_owner: Control)
signal side_focus_requested(side: Constants.FocusSide)

enum DropAction{

    NONE, 


    GAINED_DRAGGABLE, 


    LOST_DRAGGABLE, 
}

enum DropBehavior{
    DEFAULT, 
    CANCEL, 
    REMOVE, 
}

const constants: = preload("res://autoload/dragdrop_manager/constants.gd")

const CALLABLE_DRAGGED_NODE_SET = "_on_dragged_node_set"
const CALLABLE_DRAGGED_NODE_MOVED = "_on_dragged_node_moved"
const CALLABLE_DRAGGED_NODE_DROPPED = "_on_dragged_node_dropped"
const CALLABLE_ACCEPT_DRAGGABLE_QUERY = "_on_accept_draggable_query"

const GAMEPAD_DRAGGABLE_OFFSET: Vector2 = Vector2(10, -10)

var _drop_receivers: Array[DropReceiverData]
var _prev_focus_owner: Control = null
var _enabled: bool = true


var dragged_node: CanvasItem


var draggable_component: Draggable

var gamepad_mode: bool = false



var dummy_focus_receiver: Control = Control.new()

var offset: Vector2

var is_dragging: bool:
    get: return ! !dragged_node

var hovered_drop_node: Control = null
var hovered_drop_receiver: DropReceiver = null


static func is_drag_start_valid(event: InputEvent) -> bool:
    return event.pressed if not SettingsManager.get_click_to_drag() else not event.pressed


func _ready() -> void :
    get_viewport().gui_focus_changed.connect(_on_gui_focus_changed)
    dummy_focus_receiver.focus_mode = Control.FOCUS_ALL
    dummy_focus_receiver.name = "dummy"
    add_child(dummy_focus_receiver)


func _process(_delta: float) -> void :
    _position_dragged_node()


func disable() -> void :
    _enabled = false
    drop_dragged_node(DropBehavior.CANCEL)


func enable() -> void :
    _enabled = true





func set_dragged_node(new_dragged_node: Control, new_draggable_component: Draggable, via_gamepad: bool = false) -> void :
    if not _enabled:
        return

    if new_dragged_node == dragged_node:
        return

    set_process(true)


    gamepad_mode = via_gamepad

    dragged_node = new_dragged_node
    draggable_component = new_draggable_component
    dragged_node_set.emit()

    _position_dragged_node()
    _configure_focus(new_draggable_component, new_dragged_node)



    var dialog_layer: CanvasLayer = get_node("/root/DialogLayer")
    dialog_layer.layer = 3

    var phrase_size: Vector2 = dragged_node.size
    var phrase_pos: Vector2 = dragged_node.global_position

    dragged_node.get_parent().remove_child(dragged_node)
    dialog_layer.add_child(dragged_node)
    dragged_node.size = phrase_size
    dragged_node.global_position = phrase_pos
    dragged_node.scale = SettingsManager.get_ui_scale()

    dragged_node.z_as_relative = false
    dragged_node.z_index = 5


    dragged_node.mouse_filter = dragged_node.MOUSE_FILTER_IGNORE
    if SettingsManager.get_click_to_drag():
        offset = - (new_dragged_node.size / 2)
    else:
        offset = new_dragged_node.get_screen_position() - get_viewport().get_mouse_position()
    new_draggable_component.global_reset_position = new_draggable_component.global_reset_position + offset

    _call_or_noop(
        dragged_node, 
        CALLABLE_DRAGGED_NODE_SET, 
        []
    )

    for drop_receiver in _drop_receivers:
        var target: = drop_receiver.component

        if not drop_receiver.accept_draggable(draggable_component):
            drop_receiver.component.set_host_focus_mode(Control.FOCUS_NONE)
            continue

        _call_or_noop(
            target, 
            CALLABLE_DRAGGED_NODE_SET, 
            [dragged_node, draggable_component]
        )

    AudioManager.play(AudioManager.Sound.PHRASE_DRAG_START, SoundParams.new().with_pitch_range(Vector2(-0.2, 0.2)))


func _input(event: InputEvent) -> void :
    _handle_dummy_focusout(event)

    if not dragged_node:
        return

    _handle_gamepad_input(event)

    if not dragged_node:

        return

    _handle_mouse_input(event)


func _notification(what: int) -> void :
    if what != NOTIFICATION_APPLICATION_FOCUS_OUT:
        return
    drop_dragged_node(DropBehavior.CANCEL)



func set_dragged_position(new_position: Vector2) -> void :
    if not dragged_node:
        return

    _on_dragged_node_moved(new_position)




func drop_dragged_node(behavior: DropBehavior = DropBehavior.DEFAULT) -> Variant:
    if not dragged_node:
        return

    set_process(false)

    var drop_target: CanvasItem

    dragged_node.scale = Vector2.ONE

    match behavior:
        DropBehavior.DEFAULT:

            drop_target = _get_drop_target()
        DropBehavior.CANCEL:

            drop_target = draggable_component.owner_drop_receiver
        DropBehavior.REMOVE:

            drop_target = draggable_component.owner_drop_receiver if draggable_component.owner_drop_receiver.read_only else null

    var prev_target: DropReceiver = draggable_component.owner_drop_receiver
    var destroy_on_drop: = prev_target and prev_target.free_draggable_on_invalid_drop
    var has_new_state: = drop_target != prev_target
    var draggable_is_duplicate: = prev_target and prev_target.duplicate_slotted_draggable_on_drag

    var swap_made: = false

    if not drop_target and prev_target and not destroy_on_drop and not draggable_is_duplicate:
        drop_target = prev_target

    if drop_target and prev_target and drop_target != prev_target:

        var swap_siblings_only: bool = drop_target.accept_siblings_only or prev_target.accept_siblings_only
        var are_siblings: bool = _are_siblings(drop_target, prev_target)
        var is_swap_candidate: bool = \
drop_target.swap_on_valid_drop\
and drop_target.slotted_node\
and not prev_target.read_only\
and ( not swap_siblings_only\
or are_siblings)

        if prev_target.keep_copy_on_drop and not is_swap_candidate and not are_siblings:


            var dupe: = duplicate_draggable_host(dragged_node)
            var duped_draggable: Draggable = NodeUtils.get_first_of_class_name(dupe, Draggable)


            prev_target.add_child(dupe)
            prev_target.claim_draggable(duped_draggable)
            _reset_z_index(dupe)


            if dragged_node is Control and dupe is Control:
                GamepadUtils.reroute_neigbor_focus(dragged_node as Control, dupe as Control)
            dupe.show()

        elif is_swap_candidate:

            var target_slotted_node: CanvasItem = drop_target.slotted_node

            var drop_target_slotted_draggable: Draggable = drop_target.slotted_draggable


            if prev_target.receiver_data.accept_draggable(drop_target_slotted_draggable):
                prev_target.claim_draggable(drop_target_slotted_draggable)
                swap_made = true
                if not prev_target.hide_on_drop:
                    target_slotted_node.show()
            else:




                prev_target.slotted_node = null
                prev_target.slotted_draggable = null

        elif not prev_target.duplicate_slotted_draggable_on_drag:


            prev_target.slotted_node = null
            prev_target.slotted_draggable = null

        if drop_target.slotted_node and not drop_target.protect_slotted_draggable and not swap_made:

            drop_target.slotted_node.queue_free()
            drop_target.slotted_node = null
            drop_target.slotted_draggable = null

    elif not drop_target and destroy_on_drop and prev_target and not draggable_is_duplicate:

        prev_target.slotted_node = null
        prev_target.slotted_draggable = null

    for drop_receiver in _drop_receivers:
        var target: = drop_receiver.component

        target.set_host_focus_mode(Control.FOCUS_ALL)

        if not drop_receiver.accept_draggable(draggable_component):
            continue

        var action: = DropAction.NONE
        if drop_target == target:
            action = DropAction.GAINED_DRAGGABLE
        elif prev_target == target and not draggable_is_duplicate and not swap_made:
            action = DropAction.LOST_DRAGGABLE

        _call_or_noop(target, CALLABLE_DRAGGED_NODE_DROPPED, [
            dragged_node, 
            draggable_component, 
            action, 
        ])

    if drop_target:
        draggable_component.owner_drop_receiver = drop_target
    elif destroy_on_drop or draggable_is_duplicate:
        dragged_node.queue_free()
    else:
        dragged_node.global_position = draggable_component.global_reset_position

    var previous_dragged_node: Node = dragged_node
    _reset_z_index(dragged_node)
    dragged_node.mouse_filter = dragged_node.MOUSE_FILTER_PASS
    draggable_component.dragging = false
    dragged_node = null
    draggable_component = null
    dragged_node_released.emit()
    gamepad_mode = false


    if prev_target == drop_target or swap_made:
        _refocus_post_drop(previous_dragged_node, drop_target)

    if has_new_state:
        state_changed.emit()

    AudioManager.play(AudioManager.Sound.PHRASE_DRAG_END)

    return drop_target


func register_as_drop_receiver(drop_receiver: DropReceiver, drop_radius: = 1.0) -> void :
    var new_drop_receiver_data: = DropReceiverData.new()
    new_drop_receiver_data.component = drop_receiver
    new_drop_receiver_data.drop_radius = drop_radius
    drop_receiver.receiver_data = new_drop_receiver_data
    _drop_receivers.append(new_drop_receiver_data)




func request_drop_receiver_state_check() -> void :
    for receiver in _drop_receivers:
        receiver.component.check_draggable()


func claim_draggable(drop_receiver: DropReceiver, draggable: Draggable) -> void :
    if not draggable:
        return

    draggable.global_reset_position = drop_receiver.global_position
    draggable.owner_drop_receiver = drop_receiver
    draggable.host.reparent(drop_receiver.host)
    draggable.host.set_anchors_and_offsets_preset(draggable.slotted_layout_preset, Control.PRESET_MODE_MINSIZE)


func unregister_drop_receiver(receiver_instance_id: int) -> void :
    _drop_receivers = _drop_receivers.filter(
        func(rcv: DropReceiverData) -> bool:
            return (rcv.component as Node).get_instance_id() != receiver_instance_id
    )


func center_in_container(container: CanvasItem, target: CanvasItem) -> Vector2:
    return container.global_position + container.size / 2 - target.size / 2


func duplicate_draggable_host(node: CanvasItem) -> CanvasItem:
    var flags: = DUPLICATE_GROUPS | DUPLICATE_SIGNALS | DUPLICATE_SCRIPTS
    var new_node: = node.duplicate(flags)
    new_node.mouse_filter = new_node.MOUSE_FILTER_PASS

    for c in new_node.get_children():
        if c is Draggable:
            new_node.set_meta(constants.DRAGGABLE_REF, c)
            c.host = new_node
            break
    return new_node


func dummy_focus(force: bool = false) -> void :
    var focus_owner: Control = get_viewport().gui_get_focus_owner()

    if not focus_owner:
        return

    if not gamepad_mode and not force:
        return

    dummy_focus_receiver.grab_focus()
    if dragged_node:
        dragged_node.hide()


func _on_dragged_node_moved(new_position: Vector2) -> void :
    var snap_target: DropReceiver = _get_drop_target()

    for drop_receiver in _drop_receivers:
        var target: DropReceiver = drop_receiver.component

        if not drop_receiver.accept_draggable(draggable_component):
            continue

        _call_or_noop(target, CALLABLE_DRAGGED_NODE_MOVED, [
            dragged_node, 
            draggable_component, 
            new_position, 
            snap_target == target, 
        ])

    dragged_node.global_position = center_in_container(snap_target, dragged_node) if snap_target else new_position


func _call_or_noop(target: Object, method_name: String, args: Array) -> Variant:
    return Callable(target, method_name).callv(args)


func _get_drop_target() -> Variant:
    var drop_target: CanvasItem
    var drop_target_mouse_distance: float
    var mouse_pos: Vector2 = dragged_node.get_global_mouse_position()

    if gamepad_mode:
        var focused_drop_receiver: DropReceiver = _get_drop_receiver_from_focus_owner()
        if not focused_drop_receiver:
            return null

        if not focused_drop_receiver.receiver_data.accept_draggable(draggable_component):
            return null

        if focused_drop_receiver.accept_siblings_only and not _validate_sibling(focused_drop_receiver):
            return null

        drop_target = focused_drop_receiver
    else:

        for drop_receiver: DropReceiverData in _drop_receivers:
            var target: DropReceiver = drop_receiver.component

            if not target.mouse_hovering:
                continue

            if not target.host.is_visible_in_tree():
                continue

            if not drop_receiver.accept_draggable(draggable_component):
                continue

            if target.accept_siblings_only and not _validate_sibling(target):
                continue

            var host_x: = target.host_global_position.x
            var host_y: = target.host_global_position.y

            var closest_point: Vector2 = Vector2(
                clamp(host_x, mouse_pos.x, host_x + target.host_size.x) as float, 
                clamp(host_y, mouse_pos.y, host_y + target.host_size.y) as float, 
            )
            var distance_to_mouse: float = closest_point.distance_to(mouse_pos)

            if not drop_target or distance_to_mouse < drop_target_mouse_distance:
                drop_target = target
                drop_target_mouse_distance = distance_to_mouse

    if drop_target and _call_or_noop(
            drop_target, 
            CALLABLE_ACCEPT_DRAGGABLE_QUERY, 
            [dragged_node, draggable_component]
        ):
            return drop_target

    return null


func check_drop_receiver(host: Control, drop_receiver: DropReceiver) -> void :
    var tag_matching: bool = false
    for tag in drop_receiver.accept_tags:
        if tag == draggable_component.tag:
            tag_matching = true
            break

    if not tag_matching:
        return

    hovered_drop_node = host
    hovered_drop_receiver = drop_receiver


func clean() -> void :
    if dragged_node:
        dragged_node.queue_free()
        dragged_node = null
    if draggable_component:
        draggable_component.queue_free()
        draggable_component = null


func _are_siblings(a: Node, b: Node) -> bool:
    return a.host.get_parent() == b.host.get_parent()


func _reset_z_index(node: CanvasItem) -> void :
    node.z_as_relative = true
    node.z_index = 0


func _handle_mouse_input(event: InputEvent) -> void :
    if event is InputEventMouseMotion and not gamepad_mode:
        var new_position: Vector2 = event.position + offset
        set_dragged_position(new_position)

        return

    if event is InputEventMouseButton and not event.pressed:
        get_viewport().set_input_as_handled()
        if event.button_index == MOUSE_BUTTON_LEFT:
            drop_dragged_node()
            get_viewport().set_input_as_handled()
        if gamepad_mode and event.button_index == MOUSE_BUTTON_RIGHT:


            drop_dragged_node(DropBehavior.CANCEL)
            get_viewport().set_input_as_handled()


func _handle_gamepad_input(event: InputEvent) -> void :
    if dragged_node and gamepad_mode and event is InputEventJoypadButton:
        if GamepadUtils.back_pressed():
            drop_dragged_node(DropBehavior.CANCEL)
            _set_input_handled()
        if GamepadUtils.accept_pressed():
            drop_dragged_node()
            _set_input_handled()


func _get_drop_receiver_from_focus_owner() -> DropReceiver:
    var focus_owner: Control = get_viewport().gui_get_focus_owner()

    if not focus_owner:
        return null

    if focus_owner is Phrase:
        var phrase_draggable: Draggable = (focus_owner as Phrase).draggable
        if phrase_draggable.owner_drop_receiver:
            return phrase_draggable.owner_drop_receiver
    if focus_owner is PhraseGridSlot:
        return focus_owner.drop_receiver

    var phrase_slot: Variant = focus_owner.get_parent()
    if phrase_slot is PhraseSlot:


        return phrase_slot.drop_receiver

    var drop_receiver_ref: Node = focus_owner.get_meta(constants.DROP_RECEIVER_REF, Node.new())
    if drop_receiver_ref is DropReceiver:

        return drop_receiver_ref

    return null


func _validate_sibling(target: Node) -> bool:
    var owner_drop_receiver: DropReceiver = draggable_component.owner_drop_receiver
    if owner_drop_receiver and not _are_siblings(owner_drop_receiver, target):
        return false
    if not owner_drop_receiver:
        return false

    return true


func _configure_focus(new_draggable_component: Draggable, new_dragged_node: Control) -> void :
    if not gamepad_mode:
        return
    var owner_drop_receiver: DropReceiver = new_draggable_component.owner_drop_receiver
    if not owner_drop_receiver:
        return

    var underlying_host: CanvasItem = owner_drop_receiver.host

    if not underlying_host is Control:
        return
    var underlying_control: Control = underlying_host as Control

    (underlying_host as Control).grab_focus()

    if not new_dragged_node:
        breakpoint
    GamepadUtils.reroute_neigbor_focus(new_dragged_node, underlying_control)


func _position_dragged_node() -> void :
    if not gamepad_mode or not dragged_node:
        return

    var focus_node: Control = get_viewport().gui_get_focus_owner()

    if focus_node != dummy_focus_receiver and not dragged_node.visible:
        dragged_node.show()

    if not focus_node:
        return

    if dragged_node == focus_node:

        return

    dragged_node.global_position = focus_node.global_position + GAMEPAD_DRAGGABLE_OFFSET


func _set_input_handled() -> void :
    get_viewport().set_input_as_handled()


func _on_gui_focus_changed(new_focus_owner: Control) -> void :
    var transform_sig_name: StringName = "global_transform_changed"
    if _prev_focus_owner and is_instance_valid(_prev_focus_owner) and _prev_focus_owner.has_signal(transform_sig_name) and _prev_focus_owner.global_transform_changed.is_connected(_position_dragged_node):
        _prev_focus_owner.global_transform_changed.disconnect(_position_dragged_node)
        _prev_focus_owner.set_notify_transform(false)

    if new_focus_owner.has_signal(transform_sig_name):
        new_focus_owner.global_transform_changed.connect(_position_dragged_node)
        new_focus_owner.set_notify_transform(true)

    _position_dragged_node()
    _prev_focus_owner = new_focus_owner


func _refocus_post_drop(previous_node: Node, drop_target: CanvasItem) -> void :
    if not previous_node is Control:
        return

    var control_node: Control = previous_node as Control
    NodeUtils.reset_focus_neighbors(control_node)

    if not drop_target is DropReceiver:
        control_node.grab_focus()
        refocused_post_drop.emit(control_node)
        return

    var target_drop_receiver: DropReceiver = drop_target as DropReceiver

    if target_drop_receiver.hide_on_drop:

        var new_target: Control = (target_drop_receiver.host as Control)
        new_target.grab_focus()
        refocused_post_drop.emit(new_target)
        return

    control_node.call_deferred(&"grab_focus")
    refocused_post_drop.emit(control_node)


func _handle_dummy_focusout(event: InputEvent) -> void :
    if event is InputEventMouse:
        return

    var focus_owner: Control = get_viewport().gui_get_focus_owner()
    if not focus_owner == dummy_focus_receiver:
        return

    var vp: Viewport = get_viewport()

    if Input.is_action_just_pressed(GamepadUtils.ACTION_UI_RIGHT):
        side_focus_requested.emit(Constants.FocusSide.LEFT)
        vp.set_input_as_handled()
        return

    if Input.is_action_just_pressed(GamepadUtils.ACTION_UI_LEFT):
        side_focus_requested.emit(Constants.FocusSide.RIGHT)
        vp.set_input_as_handled()
        return



class DropReceiverData:

    var component: DropReceiver

    var accept_tags: Array[String] = []:
        get: return component.accept_tags

    var drop_radius: float


    func accept_draggable(draggable: Draggable) -> bool:
        if not len(accept_tags):
            return false
        return draggable.tag in accept_tags
