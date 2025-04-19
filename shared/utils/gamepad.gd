class_name GamepadUtils
extends RefCounted


const ACTION_CONFIRM: StringName = &"ui_accept"
const ACTION_BACK: StringName = &"ui_cancel"
const ACTION_PANEL_TOGGLE: StringName = &"ui_toggle_puzzle_panel"
const ACTION_REMOVE_PHRASE: StringName = &"gamepad_remove_phrase"
const ACTION_UI_RIGHT: StringName = &"ui_right"
const ACTION_UI_LEFT: StringName = &"ui_left"
const ACTION_UI_UP: StringName = &"ui_up"
const ACTION_UI_DOWN: StringName = &"ui_down"
const ACTION_CYCLE_LEFT_NEXT: StringName = &"gamepad_left_puzzle_block_next"
const ACTION_CYCLE_RIGHT_NEXT: StringName = &"gamepad_right_puzzle_block_next"
const ACTION_MAIN_MENU: StringName = &"main_menu"
const ACTION_SHOW_QUICK_NAVIGATOR: StringName = &"show_quick_navigator"


static func handle_action(control: Control, handler: Callable, action: StringName) -> bool:
    if not Input.is_action_just_pressed(action) or not control.has_focus():
        return false
    control.get_viewport().set_input_as_handled()
    handler.call()

    return true


static func back_pressed() -> bool:
    return Input.is_action_just_pressed(ACTION_BACK)


static func accept_pressed() -> bool:
    return Input.is_action_just_pressed(ACTION_CONFIRM)


static func handle_confirm(control: Control, handler: Callable) -> bool:
    return handle_action(control, handler, ACTION_CONFIRM)


static func handle_back(control: Control, handler: Callable) -> bool:
    return handle_action(control, handler, ACTION_BACK)



static func reroute_neigbor_focus(old_node: Control, new_node: Control) -> void :
    var new_path: NodePath = new_node.get_path()
    var opposite_props: Array[Array] = [
        ["focus_neighbor_top", "focus_neighbor_bottom"], 
        ["focus_neighbor_bottom", "focus_neighbor_top"], 
        ["focus_neighbor_left", "focus_neighbor_right"], 
        ["focus_neighbor_right", "focus_neighbor_left"], 
    ]

    for prop_pair: Array in opposite_props:


        var prop: StringName = StringName(prop_pair[0] as String)
        var opposite_prop: StringName = StringName(prop_pair[1] as String)
        var path: NodePath = old_node.get(prop) as NodePath

        if path.is_empty():
            continue

        if not old_node.has_node(path):








            continue
        (old_node.get_node(path) as Control).set(opposite_prop, new_path)
