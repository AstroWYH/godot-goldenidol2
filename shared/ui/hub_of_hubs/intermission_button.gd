extends TextureButton

const COLOR_FOCUS: Color = Color(1.2, 1.2, 1.2)
const COLOR_NOFOCUS: Color = Color.WHITE

@export var required_puzzles: Array[PuzzleMeta]
@export var intermission_path: String
@export var dialog_layer: CanvasLayer
@export var id: int

func _ready() -> void :
    pressed.connect(_on_pressed)

    if required_puzzles.size() < 1:
        push_warning("No required puzzles for this intermission button")

    if ProgressManager.all_arcs_unlocked:
        visible = true
    else:
        check_availability()

    PersistenceManager.state_loaded.connect(check_availability.unbind(1))



func focus_changed(focus_gained: bool) -> void :
    _on_control_focus_changed(focus_gained)



func accept_requested() -> void :
    _on_pressed()


func check_availability() -> void :
    visible = true
    for puzzle in required_puzzles:
        if not ProgressManager.is_puzzle_solved(puzzle.puzzle_id):
            visible = false
            return






func _on_pressed() -> void :
    AudioManager.play(AudioManager.Sound.BUTTON_CLICK)
    show_intermission()


func show_intermission() -> void :
    ProgressManager.change_screen(intermission_path)


func _on_mouse_entered() -> void :
    modulate = COLOR_FOCUS
    $FocusTarget.grab_focus()


func _on_mouse_exited() -> void :
    if has_focus():
        return
    modulate = COLOR_NOFOCUS


func _on_control_focus_changed(focus_gained: bool) -> void :
    modulate = COLOR_FOCUS if focus_gained else COLOR_NOFOCUS
