extends Node

"\nService which manages\ndialogs and their z-indexes.\n"




signal top_changed(new_top_instance: int)
signal available_rect_changed(new_rect: Rect2)
signal dialog_closed
signal last_exploration_control_changed(new_control: Control)

const DialogText: PackedScene = preload("res://shared/ui/dialog_text/dialog_text.tscn")

var available_rect: Rect2
var has_dialogs_open: bool:
    get:
        return len(_dialog_stack) > 0
var dialog_layer: CanvasLayer
var _dialog_stack: Array[DialogStackEntry] = []
var _remove_in_progress: = false
var _prev_trigger: Control
var _last_focused_exploration_control: Control
var _hotspots: Array[Hotspot] = []



var _time_travel_bar: Control


func _ready() -> void :
    available_rect = get_viewport().get_visible_rect()





func add_dialog_instance(instance_id: int, trigger: Control, content_rect: Rect2, hide_hotspots: bool) -> void :
    var entry: DialogStackEntry = DialogStackEntry.new()
    entry.instance_id = instance_id
    entry.trigger = trigger
    entry.content_rect = content_rect

    _dialog_stack.append(entry)
    _prev_trigger = trigger

    if hide_hotspots:
        _handle_hotspot_visibility(trigger)

    top_changed.emit(instance_id)


func add_hotspot(hotspot: Hotspot) -> void :
    _hotspots.append(hotspot)


func remove_dialog_instance(id: int) -> void :
    if _remove_in_progress:
        return

    _remove_in_progress = true

    var top: = get_top()

    if top:

        _prev_trigger = top.trigger
        _handle_hotspot_visibility(_prev_trigger)

    _dialog_stack = _dialog_stack.filter(
        func(item: DialogStackEntry) -> bool: return item.instance_id != id
    )

    var new_top: = get_top()
    if new_top:
        _handle_hotspot_visibility(new_top.trigger)
    else:
        _handle_hotspot_visibility()


func finish_remove() -> void :
    _remove_in_progress = false
    var current_top: = get_top()

    top_changed.emit(
        current_top.instance_id if current_top is DialogStackEntry else 0
    )

    dialog_closed.emit()

    focus_prev_trigger()


func spawn_text_dialog(text: String, glob_position: Vector2, trigger: Control, delay: float = 0) -> void :
    if len(get_children().filter(func(child: Node) -> bool: return child.global_position == glob_position)) > 0:

        return

    if delay > 0:
        await get_tree().create_timer(delay).timeout

    var dialog_text_instance: = DialogText.instantiate()
    dialog_text_instance.ready.connect(
        func() -> void : dialog_text_instance.show_dialog(trigger), 
        CONNECT_ONE_SHOT, 
    )
    dialog_text_instance.text = text
    dialog_text_instance.global_position = glob_position

    dialog_layer.add_child(dialog_text_instance)


func close_all() -> void :
    _last_focused_exploration_control = null
    _dialog_stack = []
    _hotspots = []


func set_available_rect(new_available_rect: Rect2) -> void :
    available_rect = new_available_rect
    available_rect_changed.emit(new_available_rect)


func focus_prev_trigger() -> void :
    if not _prev_trigger is Control:
        return

    if not _prev_trigger.focus_mode == Control.FOCUS_ALL:
        return

    _prev_trigger.grab_focus()




func focus_last_exploration_control() -> void :
    if not _last_focused_exploration_control is Control:
        return
    _last_focused_exploration_control.grab_focus()


func has_last_exploration_control() -> bool:
    return is_instance_valid(_last_focused_exploration_control) and _last_focused_exploration_control is Control


func set_last_exploration_control(control: Control) -> void :
    _last_focused_exploration_control = control
    last_exploration_control_changed.emit(control)


func get_last_exploration_control() -> Variant:
    return _last_focused_exploration_control


func get_time_travel_bar() -> Control:
    return _time_travel_bar


func set_time_travel_bar(time_travel_bar_ref: Control) -> void :
    _time_travel_bar = time_travel_bar_ref


func _handle_hotspot_visibility(trigger: Control = null) -> void :
    if not trigger:
        for hs in _hotspots:
            hs.show_indicator()
        return

    if not trigger is Hotspot:
        return

    for hs in _hotspots:
        hs.hide_indicator()

    trigger.show_dependencies()


func get_top() -> DialogStackEntry:
    if not len(_dialog_stack):
        return

    return _dialog_stack[-1]


class DialogStackEntry:
    var instance_id: int
    var trigger: Control
    var content_rect: Rect2
