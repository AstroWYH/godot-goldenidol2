extends Control

signal validated(completeness: Puzzle.PuzzleCompletenessState, total: int, valid: int, filled: int)
signal solved

const FN_ADD_PUZZLE_COMPONENT: = "add_puzzle_component"
const FN_FREE_DRAGGABLE: = "free_draggable"
const SegmentedPuzzleKey: Dictionary = PersistenceManager.SegmentedPuzzleKey

@export var puzzle_meta: PuzzleMeta:
    set = set_puzzle_meta
@export var phrase_grids: Array[Control] = []
var auto_mark_solved: bool = false:
    set = set_auto_mark_solved

@export_group("Segments")
@export var override_segment_obscure_9patch: PackedScene
@export var segment_obscure_extent: Vector2 = Vector2(10, 10)
@export var custom_segments: Array[CustomSegment] = []
@export var puzzle_part_hiders: Array[PuzzlePartHider] = []

var validation_result: Puzzle.ValidationResult:
    get: return puzzle.validation_result if puzzle else null
var _init_done: bool


var _puzzle_slots: Array[Control] = []
var _container_open: bool = false
var _infinite: bool = false


var _segments: Dictionary = {}
var _segment_discovery_state: DiscoveryManager.SegmentDiscovery
var _debug_segment_hints: Array[Label] = []
var _obscurer_scene: PackedScene
var _current_segment_index: int = 0

@onready var puzzle: Puzzle = $Puzzle
@onready var default_obscure_9patch: = preload("res://shared/puzzle/puzzle_segment/assets/segment_block.tscn")
@onready var debug_label_scene: = preload("res://autoload/dev_tools/debug_label.tscn")


func _ready() -> void :
    if override_segment_obscure_9patch is PackedScene:
        _obscurer_scene = override_segment_obscure_9patch
    else:
        _obscurer_scene = default_obscure_9patch

    ProgressManager.puzzle_segments_unlocked.connect(_on_puzzle_segments_unlocked)
    ProgressManager.scenario_reset.connect(_on_scenario_reset)
    set_puzzle_meta(puzzle_meta)

    set_auto_mark_solved(auto_mark_solved)

    if DevTools.active:
        DevTools.devtools_toggled.connect(_on_devtools_toggled)


func set_puzzle_meta(v: PuzzleMeta) -> void :
    puzzle_meta = v

    if puzzle:
        puzzle.puzzle_meta = v

        if puzzle_meta is PuzzleMeta:
            init_puzzle()


func set_auto_mark_solved(v: bool) -> void :
    auto_mark_solved = v
    if puzzle:
        puzzle.auto_mark_solved = v


func init_puzzle() -> void :
    if Engine.is_editor_hint():
        return

    var puzzle_component_id: int = 1
    var state: Array

    var puzzle_data: Variant = ProgressManager.get_puzzle_state(puzzle_meta.puzzle_id)
    if typeof(puzzle_data) != TYPE_DICTIONARY:
        puzzle_data = {}

    var initial_state: Variant = puzzle_data.get(SegmentedPuzzleKey.DATA)
    _infinite = true if not phrase_grids.size() else phrase_grids.all(func(pg: Control) -> bool: return pg.infinite)
    var child_range: = range(get_child_count())

    _segment_discovery_state = DiscoveryManager.get_segment_discovery_state(puzzle_meta.puzzle_id)

    puzzle.validated.connect(_on_puzzle_validated)
    puzzle.solved.connect(_on_puzzle_solved)
    puzzle.custom_puzzle_component_container = self

    if typeof(initial_state) == TYPE_ARRAY:
        state = initial_state
    else:
        state = child_range.map(func(_i: int) -> int: return 0)

    _segment_discovery_state.prev_segment_state = _apply_default_segment_state(_segment_discovery_state.prev_segment_state)
    _segment_discovery_state.current_segment_state = _apply_default_segment_state(_segment_discovery_state.current_segment_state)

    for i: int in child_range:
        var c: = get_child(i)

        if not c.has_method(FN_ADD_PUZZLE_COMPONENT):
            continue

        _puzzle_slots.append(c)

        c.call(
            FN_ADD_PUZZLE_COMPONENT, 
            puzzle_component_id, 
            state[puzzle_component_id - 1], 
            _infinite, 
        )

        _add_obscurer(c, true)

        puzzle_component_id += 1

        _current_segment_index = i


    for phrase_grid in phrase_grids:
        if not _infinite:
            phrase_grid.queue_remove_items(state.filter(func(i: int) -> bool: return i > 0))

        if not phrase_grid.is_node_ready():
            phrase_grid.ready.connect(_init_phrase_grid_obscurers.bind(phrase_grid))
        else:
            _init_phrase_grid_obscurers(phrase_grid)

    for node in custom_segments:
        _add_custom_segment(node, _current_segment_index)
        _current_segment_index += 1

    call_deferred("_puzzle_ready")


func mark_solved() -> void :
    puzzle.mark_solved()


func container_state_change(window_open: bool) -> void :
    if puzzle_meta.segmentation_mode == PuzzleMeta.SegmentationMode.NONE:
        return

    _container_open = window_open
    _mark_segments_discovered()


func request_focus(side: Constants.FocusSide) -> Variant:
    var all_focusables: Array = _puzzle_slots.map(func(phrase_puzzle_slot: Control) -> Control: return phrase_puzzle_slot.get_phrase_slot_button())

    for grid in phrase_grids:
        all_focusables.append_array(grid.grid_nodes as Array)

    _use_puzzle_part_hiders()

    return NodeUtils.get_node_for_side(side, all_focusables)


func _mark_segments_discovered() -> void :
    DiscoveryManager.mark_segments_discovered(puzzle_meta.puzzle_id, _segment_discovery_state, _segments.values())


func _init_phrase_grid_obscurers(phrase_grid: Control) -> void :
    _add_obscurer(phrase_grid, false)


func _add_obscurer(node: Node, answer_slot: bool) -> void :
    var obs: NinePatchRect = _obscurer_scene.instantiate()
    var target_node: Control = node.phrase_slot if answer_slot else node

    call_deferred("_resize_obscurer", obs, target_node)

    var seg_idx: int = _current_segment_index
    var is_obscured: bool = not FlagsUtils.flag_state_pos(_segment_discovery_state.prev_segment_state, seg_idx)

    if puzzle_meta.segmentation_mode == PuzzleMeta.SegmentationMode.NONE:
        is_obscured = false

    if answer_slot:
        target_node.add_obscurer(obs)
    else:

        node.id = seg_idx

        node.obscured = is_obscured

        _current_segment_index += 1
        _segments[seg_idx] = node

        return

    var instance: PuzzleSegment = PuzzleSegment.new()
    instance.node = node
    instance.obscurer = obs

    instance.obscured = is_obscured

    _current_segment_index += 1
    _segments[seg_idx] = instance


func _resize_obscurer(obscurer: NinePatchRect, target_node: Control) -> void :
    var double_extent: Vector2 = Vector2(
        segment_obscure_extent.x * 2, 
        segment_obscure_extent.y * 2, 
    )

    obscurer.custom_minimum_size = target_node.custom_minimum_size + double_extent
    obscurer.size = target_node.size + double_extent
    obscurer.global_position = target_node.global_position - segment_obscure_extent



func _add_custom_segment(custom_segment: CustomSegment, seg_idx: int) -> void :
    if not Engine.is_editor_hint():
        custom_segment.id = seg_idx

    custom_segment.obscured = not FlagsUtils.flag_state_pos(_segment_discovery_state.prev_segment_state, seg_idx)

    if puzzle_meta.segmentation_mode == PuzzleMeta.SegmentationMode.NONE:
        custom_segment.obscured = false

    _segments[seg_idx] = custom_segment


func _on_puzzle_solved() -> void :
    solved.emit()


func _store_state() -> void :
    if not _init_done:
        return

    var new_data: Array[int] = []
    for slot in _puzzle_slots:
        new_data.append(slot.slotted_id)

    ProgressManager.set_puzzle_state(puzzle_meta.puzzle_id, {
        SegmentedPuzzleKey.DATA: new_data, 
        SegmentedPuzzleKey.SEGMENTS: 0, 
    })


func _puzzle_ready() -> void :
    puzzle.puzzle_ready()
    _init_done = true


func _on_puzzle_validated(completeness: Puzzle.PuzzleCompletenessState, total: int, valid: int, filled: int) -> void :
    _store_state()
    validated.emit(completeness, total, valid, filled)


func _apply_default_segment_state(current_segment_state: int) -> int:
    var new_state: int = current_segment_state
    var segmentation_mode: = puzzle_meta.segmentation_mode

    if segmentation_mode == PuzzleMeta.SegmentationMode.OBSCURE_ALL:

        return current_segment_state
    elif segmentation_mode == PuzzleMeta.SegmentationMode.SPECIFY and puzzle_meta.specified_segments.size():
        for i: int in puzzle_meta.specified_segments:
            new_state = FlagsUtils.flag_on_pos(new_state, i)
    return new_state


func _on_devtools_toggled(made_visible: bool) -> void :
    if not made_visible:
        for label in _debug_segment_hints:
            label.queue_free()
        _debug_segment_hints = []
        return

    for k: int in _segments:
        var seg: Variant = _segments[k]
        var label: Label = debug_label_scene.instantiate()
        label.set_segment_label(k)
        label.add_theme_font_size_override("font_size", 22)
        if seg is PuzzleSegment:
            seg.node.add_child(label)
        else:
            seg.add_child(label)
        _debug_segment_hints.append(label)


func _on_puzzle_segments_unlocked(puzzle_id: int, new_segment_state: int) -> void :
    if puzzle.puzzle_meta and puzzle_id != puzzle.puzzle_meta.puzzle_id:
        return

    _segment_discovery_state.current_segment_state = _apply_default_segment_state(new_segment_state)

    if _container_open:
        _mark_segments_discovered()


func _on_scenario_reset(_scenario_id: int) -> void :
    for phrase_puzzle_slot: Control in get_children():
        if phrase_puzzle_slot.has_method(FN_FREE_DRAGGABLE):
            phrase_puzzle_slot.call(FN_FREE_DRAGGABLE, true, true)

    if not _infinite:
        for grid in phrase_grids:
            grid.reset_phrases()

    puzzle.reset()


func get_all_slots() -> Array:
    return _puzzle_slots



func _use_puzzle_part_hiders() -> void :
    if not len(puzzle_part_hiders):
        return

    var puzzle_slot_buttons: Array = _puzzle_slots.map(func(phrase_puzzle_slot: Control) -> Control: return phrase_puzzle_slot.get_phrase_slot_button())

    var phrase_grid_slots: Array[PhraseGridSlot] = []
    for phrase_grid in phrase_grids:
        phrase_grid_slots.append_array(phrase_grid.get_phrase_grid_slots() as Array[PhraseGridSlot])

    for pph in puzzle_part_hiders:
        if not is_instance_valid(pph):

            continue

        var pph_rect: Rect2 = pph.get_global_rect()



        for focusable: Control in puzzle_slot_buttons:
            if pph_rect.encloses(focusable.get_global_rect()):
                Puzzle.bind_node_to_pph(pph, focusable)

        for phrase_grid_slot in phrase_grid_slots:
            if pph_rect.encloses(phrase_grid_slot.get_global_rect()):
                phrase_grid_slot.obscured = true
                pph.revealed.connect(
                    func() -> void : phrase_grid_slot.obscured = false, 
                    CONNECT_ONE_SHOT
                )

    puzzle_part_hiders = []
