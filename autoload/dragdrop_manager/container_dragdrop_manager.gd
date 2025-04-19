extends Node

signal button_lifted(button: Control)
signal container_dropped(container: Control)

var container_zone: Control = null
var icon_zone: Control = null

var dragged_node: Control = null
var dragged_node_component: Node = null
var offset: Vector2
var transform_area: Control
var alternative_form: Control = null
var transformed: bool = false


func _input(event: InputEvent) -> void :
    if not dragged_node:
        return


    if event is InputEventMouseMotion:
        position_dragged_node(dragged_node, offset)

        var focus_owner: Control = get_viewport().gui_get_focus_owner()
        if (focus_owner is Phrase or focus_owner is PhraseSlot or focus_owner is PhraseSlotButton) and focus_owner.z_index > 0 and not ThinkingWindow.can_raise(focus_owner):

            focus_owner.lower()

        var in_transform_area: bool = transform_area.get_rect().has_point(dragged_node.global_position)

        if alternative_form:


            if in_transform_area:
                var new_node_to_drag: = alternative_form
                drop_dragged_node(true)
                var new_drag_component: Node
                for child in new_node_to_drag.get_children():
                    if child is ContainerDragger:
                        new_drag_component = child
                        break
                if not new_drag_component:
                    return
                new_node_to_drag.global_position = new_node_to_drag.get_global_mouse_position() - Vector2(new_node_to_drag.size.x / 2, 50)
                var new_offset: Vector2 = new_node_to_drag.global_position - new_node_to_drag.get_global_mouse_position()
                set_dragged_node(new_node_to_drag, new_drag_component, new_offset, null)
            return


        if not alternative_form:


            if not in_transform_area:
                drop_dragged_node(true)
            return


    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
            drop_dragged_node(false)


func position_dragged_node(_dragged_node: CanvasItem, _offset: Vector2) -> void :
    var new_position: = dragged_node.get_global_mouse_position() + offset
    restrict_to_position_within_frame(_dragged_node, new_position)


func restrict_to_position_within_frame(_dragged_node: CanvasItem, new_position: Vector2) -> void :
    var object_size: Vector2 = _dragged_node.size * SettingsManager.get_ui_scale()

    var margin_offset: int = 5


    if new_position.x < 0 + margin_offset:
        new_position.x = 0 + margin_offset



    if new_position.x + object_size.x > 1920 - margin_offset:
        new_position.x = 1920 - object_size.x - margin_offset


    if new_position.y < 0 + margin_offset:
        new_position.y = 0 + margin_offset


    if new_position.y > 1080 - 200:
        new_position.y = 1080 - 200

    _dragged_node.global_position = new_position



func set_dragged_node(new_dragged_node: Control, component: Node, new_offset: Vector2, new_alternative_form: Control) -> void :
    dragged_node = new_dragged_node
    dragged_node_component = component
    offset = new_offset
    alternative_form = new_alternative_form


    dragged_node.move_to_front()

    if transformed and alternative_form:
        alternative_form.move_to_front()

    if dragged_node is Button:
        button_lifted.emit(dragged_node)


func drop_dragged_node(to_original_pos: bool) -> void :
    if to_original_pos:
        dragged_node.position = dragged_node_component.original_position

    else:
        if alternative_form:
            dragged_node.position = dragged_node_component.original_position
        else:




            restrict_to_position_within_frame(dragged_node, dragged_node.position)


    container_dropped.emit(dragged_node)
    cleanup()


func cleanup() -> void :
    dragged_node = null
    dragged_node_component.dragging = false
    dragged_node_component = null
    offset = Vector2.ZERO
    alternative_form = null
    transformed = false
