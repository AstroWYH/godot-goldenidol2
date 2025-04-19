extends Node

const FPS: int = 10
const MOUSE_WARP_RATE: int = 1000
const CursorData: = preload("res://autoload/cursor_service/cursors.gd")
const CursorType: = CursorData.CursorType

static  var _cursor_data: = CursorData.new()
static  var _time_sec: = 0.0
static  var _frame_idx: = 0
static  var _active_cursor: CursorData.Cursor
static  var _temp_cursor: = false
static  var _queued_cursor_type: CursorData.CursorType

var _should_process_cursor: bool = true
var _win_focused: bool


func _ready() -> void :
    set_cursor(CursorType.DEFAULT, true)
    Input.set_custom_mouse_cursor(
        _cursor_data.RES_CURSOR_ACTIVE[0], 
        Input.CURSOR_POINTING_HAND, 
    )

    DragAndDropManager.dragged_node_set.connect(func() -> void : set_cursor(CursorType.ACTIVE))
    DragAndDropManager.dragged_node_released.connect(func() -> void : set_cursor(CursorType.DEFAULT))


func _process(delta: float) -> void :
    if not _active_cursor:
        return

    if not _should_process_cursor:
        return

    var frames: = _active_cursor.resources
    var frames_count: = frames.size()
    _time_sec += delta

    if _time_sec >= 1.0 / _active_cursor.fps:
        _frame_idx = _frame_idx + 1 if _frame_idx < frames_count - 1 else 0

        Input.set_custom_mouse_cursor(
            frames[_frame_idx], Input.CURSOR_ARROW, _active_cursor.hotspot, 
        )

        if _frame_idx == frames_count - 1 and _temp_cursor:
            _temp_cursor = false
            set_cursor(_queued_cursor_type if _queued_cursor_type else CursorType.DEFAULT)
        _time_sec = 0




func _notification(what: int) -> void :
    if what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
        _win_focused = true
    elif what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
        _win_focused = false


func set_cursor(cursor_type: CursorType = CursorType.DEFAULT, force: bool = false) -> void :
    var active_cursor_type: CursorType

    if _active_cursor:
        active_cursor_type = _active_cursor.type

    if active_cursor_type == cursor_type and not force:
        return

    if _temp_cursor and _frame_idx < _active_cursor.resources.size() - 1:

        _queued_cursor_type = cursor_type
        return

    if DragAndDropManager.is_dragging and not DragAndDropManager.gamepad_mode:
        cursor_type = CursorType.ACTIVE

    if not _cursor_data.cursor_map.has(cursor_type):
        push_error("Invalid cursor type %d" % cursor_type)
        return

    _frame_idx = 0
    _time_sec = 0
    _active_cursor = _cursor_data.cursor_map[cursor_type]

    _should_process_cursor = _active_cursor.resources.size() != 1

    Input.set_custom_mouse_cursor(
        _active_cursor.resources[_frame_idx], 
        Input.CURSOR_ARROW, 
        _active_cursor.hotspot, 
    )



func set_temp_cursor(cursor_type: CursorType) -> void :
    _temp_cursor = true
    set_cursor(cursor_type)



func set_cursor_for_shape(cursor_type: CursorType, cursor_shape: Input.CursorShape) -> void :
    var cursor: CursorData.Cursor = _cursor_data.cursor_map[cursor_type]
    Input.set_custom_mouse_cursor(
        cursor.resources[0], 
        cursor_shape, 
        cursor.hotspot, 
    )


func set_hover_cursor() -> void :
    set_cursor(CursorType.ACTIVE)
