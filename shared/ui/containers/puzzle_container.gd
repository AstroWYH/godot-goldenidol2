extends ThinkingWindow
class_name PuzzleContainer

signal is_open_changed

const FN_CHECK_UNLOCKING_PUZZLE_PART_HIDER: = &"check_unlocking"
const FN_CHECK_WILL_ANIMATE_PUZZLE_PART_HIDER: = &"will_animate"
const FN_PUZZLE_WINSTATE_CHANGE: = &"container_state_change"

@export var is_win_condition: bool = false
@export var is_arc_win_condition: bool = false
@export var unlocks_items: Array[PhraseGridItem] = []
@export var puzzle_group: PuzzleGroup
@export var sequence_element_id: String

@onready var close_button: Button = % CloseButton
@onready var indicator: Control = % PuzzleStateIndicator

var validation_result: Puzzle.ValidationResult:
    get: return puzzle_group.validation_result if puzzle_group else null

var _is_open: bool
var _request_focus_tween: Tween


var _solve_button: Button
var _result_info: Label


func _ready() -> void :
    super ()
    close_button.pressed.connect(_on_close_pressed)

    if puzzle_group:
        indicator.puzzle_group = puzzle_group

    if DevTools.active:
        _add_devtools()





func should_delay() -> bool:
    var segments_will_animate: bool = puzzle_group.segments_will_animate()
    return _call_puzzle_part_hider_if_will_animate(self) or segments_will_animate


func request_state_change(open: bool, new_y_pos: float) -> void :

    if _is_open == open:
        return
    _is_open = open

    position.y = new_y_pos

    if open:
        _call_puzzle_part_hider_unlocking(self)

    if not open and _request_focus_tween and _request_focus_tween.is_running():

        _request_focus_tween.kill()
        _request_focus_tween = null

    _call_discoveries(open)
    is_open_changed.emit(open)


func request_focus(side: Constants.FocusSide) -> void :

    var test_result: bool = puzzle_group.request_focus(side, true)

    if test_result:

        return

    if not test_result and should_delay():


        _request_focus_tween = create_tween()
        _request_focus_tween.tween_callback(
            func() -> void :
                puzzle_group.request_focus(side)
                move_to_front()



        ).set_delay(0.66)
        return


    puzzle_group.request_focus(side)


func _call_discoveries(open: bool) -> void :
    for puzzle in puzzle_group.get_children():
        if puzzle.has_method(FN_PUZZLE_WINSTATE_CHANGE):
            puzzle.call(FN_PUZZLE_WINSTATE_CHANGE, open)


func _call_puzzle_part_hider_if_will_animate(root: Node, last_result: bool = false) -> bool:
    var r: bool = last_result
    for child: Node in root.get_children():
        if child.has_method(FN_CHECK_WILL_ANIMATE_PUZZLE_PART_HIDER):
            r = r or child.call(FN_CHECK_WILL_ANIMATE_PUZZLE_PART_HIDER)
        else:
            _call_puzzle_part_hider_if_will_animate(child, r)

    return r


func _call_puzzle_part_hider_unlocking(root: Node) -> void :

    for child: Node in root.get_children():
        if child.has_method(FN_CHECK_UNLOCKING_PUZZLE_PART_HIDER):
            child.call(FN_CHECK_UNLOCKING_PUZZLE_PART_HIDER)

        else:
            _call_puzzle_part_hider_unlocking(child)


func _on_close_pressed() -> void :
    close_pressed.emit()

    var close_sound: = AudioManager.Sound.THINKING_CARD_CLICK
    if not AudioManager.is_playing_sound(close_sound):
        AudioManager.play(AudioManager.Sound.THINKING_CARD_CLICK)


func _add_devtools() -> void :
    if not puzzle_group:
        return

    _solve_button = Button.new()
    add_child(_solve_button)
    _solve_button.focus_mode = Control.FOCUS_NONE
    _solve_button.text = "trigger solve"
    _solve_button.position.y = -30
    _solve_button.pressed.connect(func() -> void : puzzle_group.mark_solved())

    _result_info = Label.new()
    add_child(_result_info)
    _result_info.position.y = -60
    _set_result_text()

    if not DevTools.overlay_visible:
        _solve_button.hide()
        _result_info.hide()

    DevTools.devtools_toggled.connect(_on_devtools_toggled)
    puzzle_group.validated.connect(_on_puzzle_group_validated)


func _on_devtools_toggled(vis: bool) -> void :
    if not _solve_button:
        return
    _solve_button.visible = vis

    _set_result_text()
    _result_info.visible = vis


func _set_result_text() -> void :
    if not _result_info or not validation_result:
        return

    _result_info.text = "filled %d/%d, valid %d" % [
        validation_result.filled, 
        validation_result.total, 
        validation_result.valid, 
    ]


func _on_puzzle_group_validated(_completeness: Puzzle.PuzzleCompletenessState, _total: int, _valid: int, _filled: int) -> void :
    _set_result_text()


func _exit_tree() -> void :
    var sig: Signal = DevTools.devtools_toggled
    if sig.is_connected(_on_devtools_toggled):
        sig.disconnect(_on_devtools_toggled)


func on_ui_scale_changed(ui_scale: Vector2) -> void :
    if visible:
        scale = ui_scale
