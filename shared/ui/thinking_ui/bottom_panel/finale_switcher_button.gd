extends TextureButton

@export var scenario_meta: ScenarioMeta
@export var required_puzzles: Array[PuzzleMeta]

enum {LOCKED, CURRENT, AVAILABLE}


var new_scene_path: String
var button_state: int = AVAILABLE:
    set(value):
        button_state = value
        update_button_visual(value)
    get:
        return button_state



func _ready() -> void :
    if scenario_meta:
        new_scene_path = scenario_meta.path
    self.pressed.connect(_on_button_pressed)
    self.mouse_entered.connect(_on_mouse_entered)
    self.mouse_exited.connect(_on_mouse_exited)

    check_if_requirements_fulfilled()

    ProgressManager.puzzle_solved.connect(_on_puzzle_solved)


func _on_puzzle_solved(_puzzle: PuzzleMeta) -> void :
    check_if_requirements_fulfilled()


func check_if_requirements_fulfilled() -> void :
    for puzzle in required_puzzles:
        if not ProgressManager.is_puzzle_solved(puzzle.puzzle_id):
            button_state = LOCKED
            return

    if ProgressManager.current_scenario_id == scenario_meta.id:
        button_state = CURRENT
        return

    button_state = AVAILABLE


func update_button_visual(_button_state: int) -> void :
    match _button_state:
        AVAILABLE:
            modulate = Color(1, 1, 1, 1)
        CURRENT:
            modulate = Color(0.5, 1, 0.5, 1)
        LOCKED:
            modulate = Color(1, 1, 1, 0.5)


func _on_button_pressed() -> void :
    if not button_state == AVAILABLE:
        return

    if not scenario_meta:
        push_warning("No scenario meta defined")
        return

    var current_root: Node = DevTools._scene_root
    if ProgressManager.current_scenario and is_instance_valid(ProgressManager.current_scenario):
        ProgressManager.current_scenario.call("clear_scenario_data")
    current_root.queue_free()
    var new_scene: Node = (load(new_scene_path) as PackedScene).instantiate()
    get_tree().root.add_child(new_scene)


func _on_mouse_entered() -> void :
    if not button_state == AVAILABLE:
        return
    modulate = Color(1.2, 1.2, 1.2)



func _on_mouse_exited() -> void :
    if not button_state == AVAILABLE:
        return
    modulate = Color(1, 1, 1)
