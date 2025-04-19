class_name ThinkingWindow
extends Control

@warning_ignore("unused_signal")
signal close_pressed
signal dragging_started
signal side_focus_requested(side: Constants.FocusSide)

const NOFOCUS_GROUP: StringName = &"no_side_focus"



@onready var container_dragger: Control = % ContainerDragger



static func can_raise(control_node: Control) -> bool:
    var window_candidate: Variant = NodeUtils.get_parent_of_class_name(control_node, [InventoryDialog, PuzzleContainer])

    if not window_candidate:
        return true

    var window: ThinkingWindow = window_candidate as ThinkingWindow
    var thinking_layer: Variant = window.get_parent()




    var window_index: int = window.get_index()
    var window_count: int = thinking_layer.get_child_count()
    if window_index == window_count - 1:

        return true

    var rect: Rect2 = control_node.get_global_rect()
    for i in range(1, window_count - window_index):
        var other_window: Control = thinking_layer.get_child(window_index + i)
        if other_window.get_global_rect().intersects(rect):
            return false

    return true


func _ready() -> void :
    container_dragger.dragging_started.connect(
        func() -> void : dragging_started.emit()
    )


func _input(event: InputEvent) -> void :
    if event is InputEventMouse:
        return

    if ProgressManager.initial_tutorial_in_progress:

        return

    var focus_owner: Control = get_viewport().gui_get_focus_owner()
    if not focus_owner:
        return

    if not is_ancestor_of(focus_owner):
        return

    if focus_owner.is_in_group(NOFOCUS_GROUP):
        return

    var vp: Viewport = get_viewport()

    if Input.is_action_just_pressed(GamepadUtils.ACTION_UI_RIGHT):
        var neighbor: Control = focus_owner.find_valid_focus_neighbor(SIDE_RIGHT)
        if not neighbor is Control:
            side_focus_requested.emit(Constants.FocusSide.LEFT)
            vp.set_input_as_handled()
            return

    if Input.is_action_just_pressed(GamepadUtils.ACTION_UI_LEFT):
        var neighbor: Control = focus_owner.find_valid_focus_neighbor(SIDE_LEFT)
        if not neighbor is Control:
            side_focus_requested.emit(Constants.FocusSide.RIGHT)
            vp.set_input_as_handled()
            return
