extends TextureButton
class_name LocationButton

signal clicked(button: LocationButton)
signal location_change_request(
    new_location_id: int, 
    transition: Location.LocationTransition, 
    sound: AudioManager.TransitionSound
)

@export var target_location_meta: LocationMeta
@export var transition: Location.LocationTransition
@export var transition_sound: AudioManager.TransitionSound = AudioManager.TransitionSound.NONE

@export var locked: bool = false
@export var required_puzzles: Array[PuzzleMeta] = []
var sparkles: Control

var scenario: Scenario


func _ready() -> void :
    scenario = ProgressManager.current_scenario
    if scenario:
        scenario.connect_location_button(self)

    pressed.connect(_on_pressed)
    mouse_entered.connect(_on_mouse_entered)

    if locked and required_puzzles.size() > 0:
        if _check_if_unlocked():
            unlock()
        else:
            ProgressManager.puzzle_solved.connect(_on_puzzle_solved)
            visible = false


func _on_pressed() -> void :
    if sparkles:
        sparkles.queue_free()
        sparkles = null
    clicked.emit(self)
    location_change_request.emit(target_location_meta.location_id, transition, transition_sound)


func unlock() -> void :
    locked = false
    visible = true
    if not _check_if_visited():
        show_sparkles()


func _check_if_visited() -> bool:
    return ProgressManager.is_location_visited(target_location_meta.location_id)


func show_sparkles() -> void :
    sparkles = load("res://shared/ui/special_effects/location_sparkles.tscn").instantiate()
    add_child(sparkles)
    sparkles.position = size / 2


func _on_puzzle_solved(_meta: PuzzleMeta) -> void :
    if not locked:
        return
    if _check_if_unlocked():
        unlock()


func _check_if_unlocked() -> bool:
    if required_puzzles.size() == 0:
        return true
    for puzzle in required_puzzles:
        if not ProgressManager.is_puzzle_solved(puzzle.puzzle_id):
            return false
    return true


func _on_mouse_entered() -> void :
    if focus_mode != FOCUS_ALL:
        return
    grab_focus()
