extends Control

const ICON_WRONG: Resource = preload("res://shared/assets/placeholder_ui/buttons/wrong.png")
const ICON_CLOSE: Resource = preload("res://shared/assets/placeholder_ui/buttons/two_wrong.png")
const ICON_CORRECT: Resource = preload("res://shared/assets/placeholder_ui/buttons/solved.png")

@export var puzzle_group: PuzzleGroup:
    set = set_puzzle_group

@onready var sprite: = % Sprite


func _ready() -> void :
    if puzzle_group:

        _set_icon(puzzle_group.validation_result.completeness)


func set_puzzle_group(v: PuzzleGroup) -> void :
    puzzle_group = v

    if not puzzle_group:
        return

    var sig: Signal = puzzle_group.validated
    if sig.is_connected(_on_puzzle_validated):
        sig.disconnect(_on_puzzle_validated)
    sig.connect(_on_puzzle_validated)

    if sprite:
        _set_icon(puzzle_group.validation_result.completeness)


func _on_puzzle_validated(completeness: Puzzle.PuzzleCompletenessState, _total: int, _valid: int, _filled: int) -> void :
    _set_icon(completeness)


func _set_icon(completeness: Puzzle.PuzzleCompletenessState) -> void :

    match completeness:
        Puzzle.PuzzleCompletenessState.INCOMPLETE:
            sprite.texture = null
        Puzzle.PuzzleCompletenessState.COMPLETE_INCORRECT:
            sprite.texture = ICON_WRONG
        Puzzle.PuzzleCompletenessState.COMPLETE_ALMOST_CORRECT:
            sprite.texture = ICON_CLOSE
        Puzzle.PuzzleCompletenessState.COMPLETE_CORRECT:
            sprite.texture = ICON_CORRECT
