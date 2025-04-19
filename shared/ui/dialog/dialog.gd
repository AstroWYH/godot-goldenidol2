class_name Dialog
extends Control

"\nA node for displaing a CanvasItem\n(most likely a Control, like a Panel)\nIn a separate context.\n\nDialogs should be in a separate CanvasLayer,\nso focus is managed automatically.\n"








signal dialog_hide_started
signal dialog_hidden
signal dialog_shown

enum DialogPositioningMode{
    FOLLOW_MOUSE, 
    PRESERVE_POSITION, 
    FLY_TO_CENTER, 
    TRIGGER_POSITION, 
}

const SCREEN_PADDING: int = 4
const INITIAL_SCALE: Vector2 = Vector2.ZERO
const FINAL_SCALE: Vector2 = Vector2(1.0, 1.0)
const TWEEN_DURATION: float = 0.15
const PROP_SCALE: String = "scale"
const TRANS_TYPE: int = Tween.TransitionType.TRANS_ELASTIC
const PROP_GLOBAL_POS: String = "global_position"
const DialogFrameScene: PackedScene = preload("res://shared/ui/dialog/dialog_frame.tscn")


@export var content_node: CanvasItem:
    set = _set_content_node
@export var positioning_mode: DialogPositioningMode
@export var focus_node: Control
@export var closable_via_input: bool = true
@export var starting_position: Vector2
@export var add_frame: bool = false
@export var hide_content_node_on_init: bool = true


var is_dialog_open: bool:
    get:
        return visible
var _mouse_on: bool
var _is_top: bool
var _content_node_size: Vector2


var _available_offset: Rect2


func _ready() -> void :
    DialogManager.top_changed.connect(_on_manager_top_changed)
    DialogManager.available_rect_changed.connect(_on_manager_available_rect_changed)
    hide()


func _unhandled_input(event: InputEvent) -> void :
    if not closable_via_input:
        return

    if event.is_action_pressed("ui_cancel") and _is_top:
        get_viewport().set_input_as_handled()
        hide_dialog()


func _gui_input(event: InputEvent) -> void :
    if not closable_via_input:
        return

    if _mouse_on or not is_dialog_open:
        return

    if not event is InputEventMouseButton:
        return

    if event.is_pressed():
        return

    var button_index: = (event as InputEventMouseButton).button_index
    if button_index != MOUSE_BUTTON_LEFT and button_index != MOUSE_BUTTON_RIGHT:
        return

    if not _is_top:
        return

    if content_node.get_global_rect().has_point(event.position):
        return

    get_viewport().set_input_as_handled()
    hide_dialog()




func show_dialog(trigger: Control, hide_hotspots: bool = true) -> void :
    if is_dialog_open:
        return

    content_node.show()

    if not self == content_node.get_parent():
        content_node.reparent(self)

    _change_component_visibility(true)

    reparent(DialogManager.dialog_layer)

    var show_tween: = _get_tween()
    var viewport: = get_viewport()
    var content_width: float = content_node.size.x
    var content_height: float = content_node.size.y
    var screen_size: = viewport.get_visible_rect().size

    set_anchors_and_offsets_preset(PRESET_FULL_RECT)

    var _final_pos: Vector2
    match positioning_mode:
        DialogPositioningMode.FOLLOW_MOUSE, DialogPositioningMode.TRIGGER_POSITION:
            var target_pos: Vector2
            if positioning_mode == DialogPositioningMode.FOLLOW_MOUSE:
                target_pos = get_global_mouse_position()
            else:
                target_pos = trigger.get_global_rect().get_center()

            var new_pos: = Vector2(
                target_pos.x if target_pos.x + content_width + SCREEN_PADDING < 
                    screen_size.x else target_pos.x - content_width, 
                target_pos.y if target_pos.y + content_height + SCREEN_PADDING < 
                    screen_size.y else target_pos.y - content_height
            )

            content_node.global_position = new_pos
            starting_position = new_pos
            _available_offset = Rect2(DialogManager.available_rect)
            _final_pos = starting_position

        DialogPositioningMode.FLY_TO_CENTER:


            var trigger_pos: = trigger.get_screen_position()
            var available_rect: = DialogManager.available_rect

            var offset: Vector2 = (available_rect.size - content_node.size) / 2
            _final_pos = available_rect.position + offset

            trigger_pos += trigger.size / 2
            content_node.global_position = trigger_pos
            starting_position = trigger_pos






            show_tween.tween_property(
                content_node, 
                PROP_GLOBAL_POS, 
                _final_pos, 
                TWEEN_DURATION
            )

    show_tween.tween_property(
        content_node, 
        PROP_SCALE, 
        FINAL_SCALE, 
        TWEEN_DURATION
    )

    show_tween.play()

    var delayed_tween: = create_tween().set_parallel()


    var focus_target: Control = _get_focus_target()
    if not focus_target and content_node is Control:


        content_node.focus_mode = Control.FOCUS_ALL
        focus_target = content_node
        DialogManager.set_last_exploration_control(content_node as Control)

    if focus_target is Control:
        delayed_tween.tween_callback(
            focus_target.grab_focus
        )

    delayed_tween.tween_callback(
        func() -> void :
            CursorService.set_cursor()
            dialog_shown.emit()
    ).set_delay(TWEEN_DURATION)

    var content_rect: Rect2 = Rect2(_final_pos, _content_node_size)
    DialogManager.add_dialog_instance(
        get_instance_id(), trigger, content_rect, hide_hotspots, 
    )


func hide_dialog() -> void :
    var downscale_tween: = _get_tween()
    downscale_tween.finished.connect(_on_hide_tween_finished)
    if positioning_mode == DialogPositioningMode.FLY_TO_CENTER:
        downscale_tween.tween_property(
            content_node, 
            PROP_GLOBAL_POS, 
            starting_position, 
            TWEEN_DURATION
        )

    downscale_tween.tween_property(
        content_node, 
        PROP_SCALE, 
        INITIAL_SCALE, 
        TWEEN_DURATION
    )
    downscale_tween.play()

    var hide_tween: = create_tween()
    hide_tween.tween_callback(
        self._finish_hide
    ).set_delay(TWEEN_DURATION)
    hide_tween.play()

    DialogManager.remove_dialog_instance(get_instance_id())
    content_node.focus_mode = Control.FOCUS_NONE
    dialog_hide_started.emit()


func _on_hide_tween_finished() -> void :
    content_node.hide()


func _get_tween() -> Tween:
    return create_tween(
        ).set_parallel(true).set_ease(Tween.EASE_OUT)


func _change_component_visibility(make_visible: bool) -> void :
    if make_visible:
        show()
        return
    hide()


func _on_mouse_exited() -> void :
    _mouse_on = false


func _on_mouse_entered() -> void :
    _mouse_on = true


func _finish_hide() -> void :
    _change_component_visibility(false)
    DialogManager.finish_remove()
    dialog_hidden.emit()


func _on_manager_top_changed(new_top_instance: int) -> void :
    _is_top = new_top_instance == get_instance_id()

func _set_content_node(value: CanvasItem) -> void :
    content_node = value

    if not content_node:
        return

    _change_component_visibility(false)
    starting_position = content_node.global_position

    _content_node_size = content_node.size
    content_node.scale = INITIAL_SCALE
    content_node.mouse_entered.connect(_on_mouse_entered)
    content_node.mouse_exited.connect(_on_mouse_exited)

    if hide_content_node_on_init:
        content_node.hide()

    if add_frame:
        var frame: NinePatchRect = DialogFrameScene.instantiate()
        content_node.add_child(frame)
        frame.size = content_node.size


func _on_manager_available_rect_changed(new_available_rect: Rect2) -> void :
    var available_rect: = new_available_rect

    if visible:
        if available_rect.size == Vector2.ZERO:

            content_node.global_position.x = content_node.size.x
            return

        if positioning_mode == DialogPositioningMode.FOLLOW_MOUSE:
            var prev_offset: = (get_viewport_rect().size - _available_offset.size) / 2
            var offset: = (get_viewport_rect().size - available_rect.size) / 2
            var offset_difference: = offset - prev_offset
            var difference: Vector2 = available_rect.position - _available_offset.position
            content_node.global_position = starting_position - offset_difference + difference

        elif positioning_mode == DialogPositioningMode.FLY_TO_CENTER:
            content_node.global_position = available_rect.position + ((available_rect.size - content_node.size) / 2)


func _get_focus_target(root: Node = self) -> Variant:
    if focus_node is Control:
        return focus_node


    var queue: Array = root.get_children()
    while len(queue):
        var child: Node = queue.pop_front()
        if child is Control and (child as Control).focus_mode == Control.FOCUS_ALL:
            return child
        else:
            queue.append_array(child.get_children())

    return null
