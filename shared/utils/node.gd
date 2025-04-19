extends Node






func collect_nodes(root: Node, predicate: Callable) -> Array[Node]:
    var node_collection: Array[Node] = []
    _collect_nodes(root, predicate, node_collection)
    return node_collection


func _collect_nodes(root: Node, predicate: Callable, collected: Array[Node]) -> void :
    if predicate.call(root):
        collected.append(root)
    for child in root.get_children():
        _collect_nodes(child, predicate, collected)



func get_node_group(root: Node, group: String) -> Array[Node]:
    return collect_nodes(root, func(n: Node) -> bool: return n.is_in_group(group))



func get_nodes_by_class_name(root: Node, class_name_value: GDScript) -> Array[Node]:
    return collect_nodes(
        root, 
        func(n: Node) -> bool: return class_name_value.instance_has(n)
    )




func get_first_of_type(root_node: Node, node_type: String) -> Variant:
    if root_node.is_class(node_type):
        return root_node

    for child in root_node.get_children():
        @warning_ignore("inference_on_variant")
        var result: = get_first_of_type(child, node_type)
        if result != null:
            return result

    return null





func get_first_of_class_name(root_node: Node, node_class_name: GDScript) -> Variant:
    if node_class_name.instance_has(root_node):
        return root_node

    for child in root_node.get_children():
        var result: Variant = get_first_of_class_name(child, node_class_name)
        if result != null:
            return result

    return null





func get_parent_of_class_name(child_node: Node, node_class_names: Array[GDScript]) -> Variant:
    if not child_node:
        return null

    var parent: Node = child_node.get_parent()

    if not parent:
        return null

    var match : bool = node_class_names.reduce(
        func(current: bool, i: GDScript) -> bool:
            return i.instance_has(parent) or current
            , 
        false

    )

    if match :
        return parent

    return get_parent_of_class_name(parent, node_class_names)



func get_last_child(root_node: Node) -> Node:
    return root_node.get_child(root_node.get_child_count() - 1)



func reset_focus_neighbors(control: Control) -> void :
    control.focus_neighbor_top = NodePath("")
    control.focus_neighbor_bottom = NodePath("")
    control.focus_neighbor_left = NodePath("")
    control.focus_neighbor_right = NodePath("")



func is_more_top_left(a: CanvasItem, b: CanvasItem) -> bool:
    var a_pos: Vector2 = a.global_position
    var b_pos: Vector2 = b.global_position
    return b_pos.x < a_pos.x and b_pos.y <= a_pos.y



func is_more_top_right(a: CanvasItem, b: CanvasItem) -> bool:
    var a_pos: Vector2 = a.global_position
    var b_pos: Vector2 = b.global_position

    return a_pos.x < b_pos.x and a_pos.y >= b_pos.y


func get_side_comparator(side: Constants.FocusSide) -> Callable:
    var fn: Callable
    match side:
        Constants.FocusSide.LEFT:
            fn = NodeUtils.is_more_top_left
        Constants.FocusSide.ANY:
            fn = NodeUtils.is_more_top_left
        Constants.FocusSide.RIGHT:
            fn = NodeUtils.is_more_top_right

    return fn


func get_node_for_side(side: Constants.FocusSide, nodes: Array) -> Variant:
    var fn: Callable = NodeUtils.get_side_comparator(side)
    var focusable_node: Control
    for node: Node in nodes:
        if not node is Control:
            continue

        if not is_instance_valid(node):
            continue

        if not node.is_visible_in_tree():
            continue

        var control_node: Control = node as Control
        if not control_node.focus_mode == Control.FOCUS_ALL:
            continue

        if node == DragAndDropManager.dragged_node:


            continue

        @warning_ignore("unassigned_variable")
        if not focusable_node:
            focusable_node = node
            continue

        if focusable_node and fn.call(focusable_node, node):
            focusable_node = node

    return focusable_node



func greedy_focus(node: Control) -> void :
    if node.focus_mode == Control.FOCUS_NONE:
        return

    if not node.visible:
        return

    if not get_tree().get_root().gui_get_focus_owner():
        node.grab_focus()


func unfocus() -> void :
    var focus_owner: Control = get_viewport().gui_get_focus_owner()
    if focus_owner is Control:
        focus_owner.release_focus()
