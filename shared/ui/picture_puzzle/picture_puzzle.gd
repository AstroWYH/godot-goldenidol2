extends Control

signal validated(completeness: Puzzle.PuzzleCompletenessState, total: int, valid: int, filled: int)
signal solved

const SegmentedPuzzleKey: Dictionary = PersistenceManager.SegmentedPuzzleKey

@export var puzzle_meta: PuzzleMeta:
    set = _set_puzzle_meta
@export var puzzle_inventory: Control
@export var puzzle_answers: Control
var auto_mark_solved: bool = false:
    set = _set_auto_mark_solved

@export_group("Segments")
@export var override_segment_obscure_9patch: PackedScene
@export var segment_obscure_extent: Vector2 = Constants.DEFAULT_SEGMENT_OBSCURE_EXTENT
@export var puzzle_part_hiders: Array[PuzzlePartHider] = []

var validation_result: Puzzle.ValidationResult:
    get: return puzzle.validation_result if puzzle else null
var _init_done: bool
var _data: Dictionary:
    get: return puzzle_inventory.inventory_data
var _data_by_id: Dictionary:
    get: return puzzle_inventory.inventory_data_by_id
var _infinite_inventory: bool:
    get: return puzzle_inventory.infinite
var _container_open: bool = false
var _answer_nodes: Array[Control] = []
var _inventory_nodes: Array[Control] = []


var _segments: Dictionary = {}
var _segment_discovery_state: DiscoveryManager.SegmentDiscovery
var _segments_total: int = 0
var _debug_segment_hints: Array[Label] = []
var _obscurer_scene: PackedScene

@onready var puzzle: Puzzle = $Puzzle
@onready var dragdrop_constants: = preload("res://autoload/dragdrop_manager/constants.gd")
@onready var puzzle_constants: = preload("res://shared/puzzle/constants.gd")
@onready var debug_label_scene: = preload("res://autoload/dev_tools/debug_label.tscn")
@onready var default_obscure_9patch: = preload("res://shared/puzzle/puzzle_segment/assets/segment_block.tscn")
@onready var parent_container: Control = get_parent()


func _ready() -> void :
    if not puzzle_inventory:
        push_error("no puzzle inventory")
        return

    if not puzzle_answers:
        push_error("no puzzle answer")
        return

    _set_puzzle_meta(puzzle_meta)
    _set_auto_mark_solved(auto_mark_solved)

    var segment_index: int = 0

    var state: Variant = ProgressManager.get_puzzle_state(puzzle_meta.puzzle_id)
    _segment_discovery_state = DiscoveryManager.get_segment_discovery_state(puzzle_meta.puzzle_id)
    if typeof(state) != TYPE_DICTIONARY:
        state = {}

    _answer_nodes = puzzle_answers.build_answer_nodes(
        _data, 
        _data_by_id, 
        puzzle_inventory.tag, 
        _infinite_inventory, 
        state.get(SegmentedPuzzleKey.DATA), 
    )

    var inv_nodes: Array[Control] = []
    inv_nodes.assign(puzzle_inventory.puzzle_piece_container.get_children() as Array)
    _inventory_nodes = inv_nodes

    _segments_total = _answer_nodes.size() + _inventory_nodes.size()
    _segment_discovery_state.prev_segment_state = _apply_default_segment_state(_segment_discovery_state.prev_segment_state)
    _segment_discovery_state.current_segment_state = _apply_default_segment_state(_segment_discovery_state.current_segment_state)
    var current_seg_state: int = _segment_discovery_state.current_segment_state

    if override_segment_obscure_9patch is PackedScene:
        _obscurer_scene = override_segment_obscure_9patch
    else:
        _obscurer_scene = default_obscure_9patch

    for node in _answer_nodes:
        _add_obscurer(node, segment_index, FlagsUtils.flag_state_pos(current_seg_state, segment_index))
        segment_index += 1

    for node in _inventory_nodes:
        _add_obscurer(node, segment_index, FlagsUtils.flag_state_pos(current_seg_state, segment_index))
        segment_index += 1

    puzzle.custom_puzzle_component_container = puzzle_answers.puzzle_answer_container
    puzzle.puzzle_ready()

    _init_done = true

    if DevTools.active:
        DevTools.devtools_toggled.connect(_on_devtools_toggled)

    ProgressManager.puzzle_segments_unlocked.connect(_on_puzzle_segments_unlocked)
    ProgressManager.scenario_reset.connect(_on_scenario_reset)


func mark_solved() -> void :
    _set_inv_node_readonly(true)
    puzzle.mark_solved()


func container_state_change(window_open: bool) -> void :
    if puzzle_meta.segmentation_mode == PuzzleMeta.SegmentationMode.NONE:
        return

    _container_open = window_open
    _mark_segments_discovered()


func request_focus(side: Constants.FocusSide) -> Variant:
    _use_puzzle_part_hiders()

    var all_nodes: Array = _inventory_nodes
    all_nodes.append_array(_answer_nodes)
    return NodeUtils.get_node_for_side(side, all_nodes)


func get_all_slots() -> Array:
    return _answer_nodes


func _set_inv_node_readonly(read_only: bool) -> void :
    for node in _inventory_nodes:
        (node.get_meta(DragAndDropManager.constants.DROP_RECEIVER_REF) as DropReceiver).read_only = true


func _mark_segments_discovered() -> void :
    DiscoveryManager.mark_segments_discovered(puzzle_meta.puzzle_id, _segment_discovery_state, _segments.values())


func _set_auto_mark_solved(v: bool) -> void :
    auto_mark_solved = v
    if puzzle:
        puzzle.auto_mark_solved = v


func _set_puzzle_meta(v: PuzzleMeta) -> void :
    puzzle_meta = v

    if puzzle:
        puzzle.puzzle_meta = v


func _on_puzzle_solved() -> void :
    solved.emit()


func _on_puzzle_validated(completeness: Puzzle.PuzzleCompletenessState, total: int, valid: int, filled: int) -> void :
    validated.emit(completeness, total, valid, filled)
    _store_puzzle_state()


func _store_puzzle_state() -> void :
    if not _init_done:
        return

    var state: Array[int] = []
    for c: Node in puzzle_answers.puzzle_answer_container.get_children():
        var drop_receiver: DropReceiver = c.get_meta(dragdrop_constants.DROP_RECEIVER_REF)
        if not drop_receiver:
            continue
        state.append(drop_receiver.slotted_id)

    ProgressManager.set_puzzle_state(puzzle_meta.puzzle_id, {
        SegmentedPuzzleKey.DATA: state, 
        SegmentedPuzzleKey.SEGMENTS: _segment_discovery_state.current_segment_state, 
    })


func _add_obscurer(node: Node, segment_idx: int, node_visible: bool) -> void :
    var obs: NinePatchRect = _obscurer_scene.instantiate()
    var double_extent: Vector2 = Vector2(
        segment_obscure_extent.x * 2, 
        segment_obscure_extent.y * 2, 
    )

    obs.custom_minimum_size = node.custom_minimum_size + double_extent
    obs.size = node.size + double_extent
    obs.position = obs.position - segment_obscure_extent

    node.add_child(obs)

    var instance: PuzzleSegment = PuzzleSegment.new()
    instance.node = node
    instance.obscurer = obs
    instance.id = segment_idx

    if node_visible or puzzle_meta.segmentation_mode == PuzzleMeta.SegmentationMode.NONE:
        instance.obscured = false

    _segments[segment_idx] = instance


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

        label.position.y = -30

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
    if puzzle_meta.arc_puzzle:
        return

    _set_inv_node_readonly(false)

    for host: Control in _answer_nodes:
        var answer_drop_receiver: DropReceiver = host.get_meta(dragdrop_constants.DROP_RECEIVER_REF) as DropReceiver

        if puzzle_inventory.infinite:

            answer_drop_receiver.free_draggable(true, true)
        else:
            if answer_drop_receiver.slotted_id > 0:

                puzzle_inventory.drop_receiver_by_id[
                    answer_drop_receiver.slotted_node.get_meta(puzzle_constants.PUZZLE_PIECE_REF).id
                ].claim_draggable(answer_drop_receiver.slotted_draggable)
                answer_drop_receiver.slotted_node = null
                answer_drop_receiver.slotted_draggable = null
                answer_drop_receiver.read_only = false

    puzzle.reset()



func _use_puzzle_part_hiders() -> void :
    if not len(puzzle_part_hiders):
        return

    for pph in puzzle_part_hiders:
        if not is_instance_valid(pph):

            continue

        var pph_rect: Rect2 = pph.get_global_rect()


        for inventory_node in _inventory_nodes:
            if pph_rect.encloses(inventory_node.get_global_rect()):
                Puzzle.bind_node_to_pph(pph, inventory_node)

        for answer_node in _answer_nodes:
            if pph_rect.encloses(answer_node.get_global_rect()):
                Puzzle.bind_node_to_pph(pph, answer_node)

    puzzle_part_hiders = []
