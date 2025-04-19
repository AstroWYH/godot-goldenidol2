class_name Puzzle
extends Control

signal validated(completeness: PuzzleCompletenessState, total: int, valid: int, filled: int)
signal solved
signal solved_and_updated

enum PuzzleCompletenessState{
    COMPLETE_INCORRECT, 
    COMPLETE_ALMOST_CORRECT, 
    COMPLETE_CORRECT, 
    INCOMPLETE, 
    UNSET, 
}

@export var puzzle_meta: PuzzleMeta:
    set = set_puzzle_meta

@export var auto_assign_puzzle_component_ids: bool = true


@export var auto_mark_solved: bool = false


@export var lazy_load: = false

@export var custom_puzzle_component_container: Node



@export var lock_draggables_on_solve: = true


var validation_result: = ValidationResult.new()

var _puzzle_component_count: int
var _used_items: Dictionary = {}


var _puzzle_component_data: Dictionary
var _tracks_items: bool = false


var _tmp_puzzle_component_id: = 1

@onready var constants: = preload("res://shared/puzzle/constants.gd")


static func get_completeness(valid_count: int, filled_count: int, total_count: int) -> PuzzleCompletenessState:
    if valid_count == total_count:
        return PuzzleCompletenessState.COMPLETE_CORRECT

    elif total_count - valid_count <= 2 and filled_count == total_count:
        return PuzzleCompletenessState.COMPLETE_ALMOST_CORRECT

    elif valid_count < total_count and filled_count == total_count:
        return PuzzleCompletenessState.COMPLETE_INCORRECT

    return PuzzleCompletenessState.INCOMPLETE


static func bind_node_to_pph(pph: PuzzlePartHider, control: Control) -> void :
    var prev_mode: FocusMode = control.focus_mode
    control.focus_mode = Control.FOCUS_NONE
    pph.revealed.connect(
        func() -> void : control.focus_mode = prev_mode, 
        CONNECT_ONE_SHOT
    )


func _ready() -> void :
    if not custom_puzzle_component_container:
        custom_puzzle_component_container = self
    if not lazy_load:
        puzzle_ready()



func puzzle_ready() -> void :
    _parse_puzzle_components(custom_puzzle_component_container)
    _parse_answer_data()
    validate()


func validate() -> void :
    var keys: = _puzzle_component_data.keys()


    var valid_cnt: = 0
    var filled_cnt: = 0

    _used_items.clear()

    for k: int in keys:
        (_puzzle_component_data[k] as PuzzleComponentData).reset_validity()

    for k: int in keys:
        _puzzle_component_data[k].validate(_puzzle_component_data)

    for k: int in keys:
        var component: PuzzleComponentData = _puzzle_component_data[k]
        var component_value: int = component.value

        if component.is_valid:
            valid_cnt = valid_cnt + 1

        if component_value:
            if _tracks_items:

                _used_items[component_value] = true
            filled_cnt = filled_cnt + 1

    var is_puzzle_solved: bool = valid_cnt == _puzzle_component_count
    var completeness: = get_completeness(valid_cnt, filled_cnt, _puzzle_component_count)

    validation_result.total = _puzzle_component_count
    validation_result.valid = valid_cnt
    validation_result.filled = filled_cnt
    validation_result.completeness = completeness

    validated.emit(
        validation_result.completeness, 
        _puzzle_component_count, 
        valid_cnt, 
        filled_cnt, 
    )

    if _tracks_items:

        _set_used_items(false)

    if is_puzzle_solved and auto_mark_solved:
        mark_solved()


func mark_solved() -> void :
    solved.emit()
    ProgressManager.mark_puzzle_solved(puzzle_meta)


    if _tracks_items:
        _set_used_items(true)

    if lock_draggables_on_solve:
        for k: int in _puzzle_component_data:
            var data: PuzzleComponentData = _puzzle_component_data[k]
            var drop_receiver: DropReceiver = data.component.drop_receiver
            if drop_receiver:
                drop_receiver.read_only = true
                drop_receiver.duplicate_slotted_draggable_on_drag = true

    solved_and_updated.emit()


func set_puzzle_meta(new_puzzle_meta: PuzzleMeta) -> void :
    puzzle_meta = new_puzzle_meta
    if new_puzzle_meta and not new_puzzle_meta.resource_path.ends_with(".tres"):
        push_error("%s (id %d) puzzle meta resource should be saved to file!" % [
            puzzle_meta.puzzle_name, 
            puzzle_meta.puzzle_id, 
        ])



func reset() -> void :
    ProgressManager.unmark_puzzle_solved(puzzle_meta.puzzle_id)

    for k: int in _puzzle_component_data:
        _puzzle_component_data[k].unset_local_value()



    validate()


func _parse_puzzle_components(root: Node) -> void :
    for child in root.get_children():
        if child is PuzzleComponent:
            _connect_puzzle_component(child as PuzzleComponent)
        else:
            _parse_puzzle_components(child)


func _connect_puzzle_component(puzzle_component: PuzzleComponent) -> void :
    var data: = PuzzleComponentData.new()

    if auto_assign_puzzle_component_ids:
        puzzle_component.id = _tmp_puzzle_component_id
        _tmp_puzzle_component_id += 1

    data.component = puzzle_component
    data.is_valid = puzzle_component.valid_by_default

    _puzzle_component_count += 1
    _puzzle_component_data[puzzle_component.id] = data

    puzzle_component.integrate()

    puzzle_component.value_updated.connect(

        func(_value: Variant) -> void : call_deferred("validate")
    )


func _parse_answer_data() -> void :
    for k: int in _puzzle_component_data.keys():
        var data: PuzzleComponentData = _puzzle_component_data[k]
        var puzzle_component: PuzzleComponent = data.component

        if puzzle_component.valid_by_default:
            continue







        var ungrouped: = []
        for child in puzzle_component.get_children():
            if child is PuzzleAnswerContainer:
                var container: = []
                for container_child in child.get_children():
                    container.append(_parse_answer_node(container_child))
                data.answers.append(container)
            else:
                ungrouped.append(_parse_answer_node(child))
            child.queue_free()

        if ungrouped.size():
            data.answers.append(ungrouped)

    if _tracks_items:
        ProgressManager.register_item_puzzle(puzzle_meta.puzzle_id)


func _parse_answer_node(node: Node) -> Variant:
    var answer_value: = _get_puzzle_component_answer_value(node as PuzzleAnswerBase)

    if not node is PuzzleAnswerBase:
        return

    if node is PuzzleAnswerItem:
        _tracks_items = true

    if not node is PuzzleAnswerDependency:
        var answer_data: = PuzzleAnswerData.new()
        answer_data.answer_value = answer_value
        return answer_data

    else:
        var answer_data: = PuzzleAnswerDependencyData.new()
        answer_data.component_id = node.get_node((node as PuzzleAnswerDependency).puzzle_component).id
        answer_data.answer_value = answer_value
        return answer_data


func _get_puzzle_component_answer_value(node: PuzzleAnswerBase) -> int:
    if node is PuzzleAnswerSimple:
        return node.answer_value

    if node is PuzzleAnswerItem:
        return (node as PuzzleAnswerItem).answer_item_ref_id

    elif node is PuzzleAnswer:

        var piece_host: = (node as PuzzleAnswer).puzzle_piece_host

        if not piece_host:
            Logger.write_err("%s has no puzzle_piece_host!" % node.name)
            return -1

        return node.get_node(piece_host)\
.get_meta(constants.PUZZLE_PIECE_REF)\
.id

    elif node is PuzzleAnswerDependency:
        if node.get_child_count() == 0:
            Logger.write_err("PuzzleAnswerDependency has no PuzzleAnswer children")
        return _get_puzzle_component_answer_value(node.get_child(0) as PuzzleAnswerBase)
    return -1


func _set_used_items(is_puzzle_solved: bool) -> void :
    ProgressManager.set_used_puzzle_items(
        puzzle_meta.puzzle_id, 
        _used_items, 
        is_puzzle_solved, 
    )


class ValidationResult:
    var completeness: PuzzleCompletenessState = PuzzleCompletenessState.UNSET
    var total: int = 0
    var valid: int = 0
    var filled: int = 0
