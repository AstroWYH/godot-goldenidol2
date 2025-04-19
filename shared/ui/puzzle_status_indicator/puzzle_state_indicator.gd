extends Control

const PROP_FONT_COLOR = "theme_override_colors/font_color"

const ICON_WRONG: Resource = preload("res://shared/assets/placeholder_ui/buttons/wrong.png")
const ICON_CLOSE: Resource = preload("res://shared/assets/placeholder_ui/buttons/two_wrong.png")
const ICON_CORRECT: Resource = preload("res://shared/assets/placeholder_ui/buttons/solved.png")
const ICON_INCOMPLETE: Resource = preload("res://shared/assets/placeholder_ui/buttons/empty.png")

var TEXT_NOT_FILLED: String = tr("PUZZLE_STATE_NOT_FILLED_IN")
var TEXT_WRONG: String = tr("PUZZLE_STATE_INCORRECT")
var TEXT_CLOSE: String = tr("PUZZLE_STATE_TWO_OR_LESS")
var TEXT_CORRECT: String = tr("PUZZLE_STATE_SOLVED")

const COLOR_DEFAULT: = Color(1, 1, 1, 1)
const COLOR_WRONG: = Color("d95763")
const COLOR_CLOSE: = Color("fbf236")
const COLOR_CORRECT: = Color("99e550")

var puzzle_group: PuzzleGroup:
    set = set_puzzle_group
var previous_completeness: int = Puzzle.PuzzleCompletenessState.UNSET

@onready var indicator: TextureRect = % Indicator
@onready var background: ColorRect = % Background
@onready var label: Label = % Status


func _ready() -> void :
    if puzzle_group:
        update_state(puzzle_group.validation_result.completeness, 0, 0, 0)


func set_puzzle_group(v: PuzzleGroup) -> void :
    puzzle_group = v

    if not v:
        return

    var sig: Signal = puzzle_group.validated
    if sig.is_connected(update_state):
        sig.disconnect(update_state)
    sig.connect(update_state)
    update_state(v.validation_result.completeness, 0, 0, 0)


func disconnect_state_tracking() -> void :
    if puzzle_group.validated.is_connected(update_state):
        puzzle_group.validated.disconnect(update_state)


func update_state(completeness: Puzzle.PuzzleCompletenessState, _total: int, _valid: int, _filled: int) -> void :

    if not indicator and not label:
        return


    if not get_parent().is_win_condition:
        change_indicator(completeness)
        return


    if completeness == Puzzle.PuzzleCompletenessState.COMPLETE_CORRECT:
        var puzzles_in_this_container: int = puzzle_group.get_child_count()
        if ProgressManager.enough_puzzles_solved(puzzles_in_this_container):
            return

    change_indicator(completeness)


func change_indicator(completeness: Puzzle.PuzzleCompletenessState) -> void :
    var color: Color = COLOR_DEFAULT
    match completeness:
        Puzzle.PuzzleCompletenessState.INCOMPLETE:
            indicator.texture = null
            label.text = TEXT_NOT_FILLED
            indicator.texture = ICON_INCOMPLETE

        Puzzle.PuzzleCompletenessState.COMPLETE_INCORRECT:
            indicator.texture = ICON_WRONG
            label.text = TEXT_WRONG
            color = COLOR_WRONG

        Puzzle.PuzzleCompletenessState.COMPLETE_ALMOST_CORRECT:
            indicator.texture = ICON_CLOSE
            label.text = TEXT_CLOSE
            color = COLOR_CLOSE

        Puzzle.PuzzleCompletenessState.COMPLETE_CORRECT:
            indicator.texture = ICON_CORRECT
            label.text = TEXT_CORRECT
            color = COLOR_CORRECT

        Puzzle.PuzzleCompletenessState.UNSET:
            indicator.texture = ICON_INCOMPLETE
            label.text = " "
            color = COLOR_DEFAULT

    label.set(PROP_FONT_COLOR, color)

    _play_state_changed_sound(completeness)
    previous_completeness = completeness

    if len(label.text) >= 25 and len(label.text) < 40:
        label.add_theme_font_size_override("font_size", 20)
    elif len(label.text) >= 40:
        label.add_theme_font_size_override("font_size", 16)
        label.autowrap_mode = TextServer.AUTOWRAP_WORD
        label.custom_minimum_size.x = 250


func _play_state_changed_sound(current_completeness: int) -> void :
    var sound: = AudioManager.Sound.NONE

    if previous_completeness == Puzzle.PuzzleCompletenessState.UNSET or previous_completeness == current_completeness:
        return
    elif previous_completeness == Puzzle.PuzzleCompletenessState.COMPLETE_INCORRECT and current_completeness == Puzzle.PuzzleCompletenessState.COMPLETE_ALMOST_CORRECT:
        sound = AudioManager.Sound.PUZZLE_SOLVED_PARTIALLY_IMPROVING
    elif current_completeness == Puzzle.PuzzleCompletenessState.COMPLETE_INCORRECT:
        sound = AudioManager.Sound.PUZZLE_SOLVED_INCORRECTLY
    elif current_completeness == Puzzle.PuzzleCompletenessState.COMPLETE_ALMOST_CORRECT:
        sound = AudioManager.Sound.PUZZLE_SOLVED_PARTIALLY
    elif current_completeness == Puzzle.PuzzleCompletenessState.COMPLETE_CORRECT:
        sound = AudioManager.Sound.PUZZLE_SOLVED_CORRECTLY

    if not AudioManager.is_playing_sound(sound) and not ProgressManager.victory_sequence_playing:
        AudioManager.play(sound)
