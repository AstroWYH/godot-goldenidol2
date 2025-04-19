class_name PuzzleGroup
extends Control










signal validated(completeness: Puzzle.PuzzleCompletenessState, total: int, valid: int, filled: int)
signal solved

var group_name: String:
    get = get_group_name

var group_icon: Texture2D:
    get = get_group_icon

var validation_result: Puzzle.ValidationResult = Puzzle.ValidationResult.new()


func _enter_tree() -> void :
    for c in get_children():



        c.auto_mark_solved = false
        if not c.validated.is_connected(_on_puzzle_validated):
            c.validated.connect(_on_puzzle_validated)


func get_group_name() -> String:
    return get_child(0).puzzle_meta.puzzle_name


func get_group_icon() -> Texture2D:
    return get_child(0).puzzle_meta.puzzle_icon


func mark_solved() -> void :
    for puzzle in get_children():
        puzzle.mark_solved()
    solved.emit()


func segments_will_animate() -> bool:
    var result: bool = false
    for c in get_children():
        if not "puzzle_meta" in c:
            continue
        result = result or not DiscoveryManager.get_segment_discovery_state((c.puzzle_meta as PuzzleMeta).puzzle_id).is_equal()

    return result


func request_focus(side: Constants.FocusSide, test: bool = false) -> bool:




    var focus_candidates: Array[Control] = []
    for child in get_children():
        if not child.has_method("request_focus"):
            continue

        var child_focus_candidate: Variant = child.request_focus(side)
        if child_focus_candidate is Control:
            focus_candidates.append(child_focus_candidate as Control)

    if not len(focus_candidates):

        if not test:
            DragAndDropManager.dummy_focus(true)
        return false

    var focus_node: Variant = NodeUtils.get_node_for_side(side, focus_candidates)
    if focus_node is Control:
        focus_node.grab_focus()
        return true

    return false


func _on_puzzle_validated(completeness: Puzzle.PuzzleCompletenessState, total: int, valid: int, filled: int) -> void :

    var all_total: int = 0
    var all_valid: int = 0
    var all_filled: int = 0

    for puzzle in get_children():
        var puzzle_result: Puzzle.ValidationResult = puzzle.validation_result
        if not puzzle_result:

            return
        all_total += puzzle_result.total
        all_valid += puzzle_result.valid
        all_filled += puzzle_result.filled

    var all_completeness: = Puzzle.get_completeness(all_valid, all_filled, all_total)

    validation_result.completeness = all_completeness
    validation_result.total = all_total
    validation_result.valid = all_valid
    validation_result.filled = all_filled

    validated.emit(
        all_completeness, 
        all_total, 
        all_valid, 
        all_filled, 
    )

    if all_completeness == Puzzle.PuzzleCompletenessState.COMPLETE_CORRECT:
        mark_solved()
