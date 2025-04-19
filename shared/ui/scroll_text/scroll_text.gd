@tool
extends Control

signal validated(completeness: Puzzle.PuzzleCompletenessState, total: int, valid: int, filled: int)
signal solved
signal solved_and_updated

const ScrollTextParser: = preload("res://shared/ui/scroll_text/scroll_text_parser.gd")
const PhraseSlotScene: = preload("res://shared/ui/phrase_slot/phrase_slot.tscn")
const NounMarkerScene: = preload("res://shared/ui/phrase_slot/noun_marker/noun_marker.tscn")
const SegmentScene: = preload("res://shared/ui/scroll_text/scroll_text_segment/scroll_text_segment.tscn")
const DebugLabelScene: = preload("res://autoload/dev_tools/debug_label.tscn")


const DEFAULT_VISIBLE_SEGMENTS: int = 1

const TOKEN_DATA_WIDTH: String = "width"
const TOKEN_DATA_ID: String = "id"
const TOKEN_DATA_DEFAULT: String = "default"
const TOKEN_DATA_ARTICLE: String = "article"
const TOKEN_DATA_FOR_ID: String = "for"
const TOKEN_DATA_PRONOUN_KEY: String = "pn"
const SegmentedPuzzleKey: Dictionary = PersistenceManager.SegmentedPuzzleKey
const DiscoveryState: Dictionary = DiscoveryManager.DiscoveryState

@export var puzzle_meta: PuzzleMeta:
    set = _set_puzzle_meta
@export_multiline var text: String:
    set = _set_text
@export_multiline var extra_segments: Array[String] = []:
    set = _set_extra_segments
var auto_mark_solved: bool = false:
    set = _set_auto_mark_solved
@export var phrase_grids: Array[Control] = []
@export var custom_segments: Array[CustomSegment] = []
@export var puzzle_part_hiders: Array[PuzzlePartHider] = []

@export_group("Dev")
@export var preview_ids: bool = false:
    set = _set_preview_ids
@export var preview_answers: bool = false:
    set = _set_preview_answers

var parser: ScrollTextParser = ScrollTextParser.new()

var validation_result: Puzzle.ValidationResult:
    get: return puzzle.validation_result if puzzle else null


var _phrase_slot_map: = {}
var _init_done: bool
var _container_open: bool = false

var _infinite: bool = true


var _puzzle_component_id_hints: Array[Label] = []
var _answer_hints: = {}
var _phrase_grid_segment_idx_hints: Array[Label] = []


var _segments: Array[Control] = []
var _segment_discovery_state: DiscoveryManager.SegmentDiscovery
var _tmp_id: int = 0

@onready var container: = % Container
@onready var puzzle: Puzzle = % Puzzle


func _ready() -> void :
    if Engine.is_editor_hint():
        _build_answer_data()

    _set_preview_ids(preview_ids)
    _generate_content()
    _set_puzzle_meta(puzzle_meta)
    _set_auto_mark_solved(auto_mark_solved)

    if not Engine.is_editor_hint():
        ProgressManager.puzzle_segments_unlocked.connect(_on_puzzle_segments_unlocked)
        ProgressManager.scenario_reset.connect(_on_scenario_reset)
        if DevTools.active:
            DevTools.devtools_toggled.connect(_on_devtools_toggled)




func get_phrase_slot(slot_id: int) -> Node:
    return _phrase_slot_map.get(slot_id)


func get_all_slots() -> Array:
    var slots: Array = []

    for segment: Control in _segments:
        if segment.has_method("get_all_slots"):
            slots.append_array(segment.get_all_slots() as Array)
    return slots








func mark_solved() -> void :
    puzzle.mark_solved()


func container_state_change(window_open: bool) -> void :
    if puzzle_meta.segmentation_mode == PuzzleMeta.SegmentationMode.NONE:
        return

    _container_open = window_open
    if _container_open:
        _mark_segments_discovered()


func request_focus(side: Constants.FocusSide) -> Variant:
    _use_puzzle_part_hiders()

    var all_focusables: Array = _phrase_slot_map.values().map(func(ps: PhraseSlot) -> Control: return ps.request_focus())
    for grid in phrase_grids:
        all_focusables.append_array(grid.grid_nodes as Array)

    return NodeUtils.get_node_for_side(side, all_focusables)


func _mark_segments_discovered() -> void :
    DiscoveryManager.mark_segments_discovered(puzzle_meta.puzzle_id, _segment_discovery_state, _segments)


func _set_text(value: String) -> void :
    text = tr(value)
    _generate_content()


func _set_extra_segments(segments: Array[String]) -> void :
    var translated: Array[String] = []
    translated.assign(segments.map(func(seg: String) -> String: return tr(seg)))
    extra_segments = translated
    _generate_content()


func _generate_content() -> void :
    if not text and not len(extra_segments):
        return

    if not container:
        return

    for child in container.get_children():
        child.call_deferred("queue_free")

    _segments = []
    var token_groups: Array[String] = []
    token_groups.append(text)
    token_groups.append_array(extra_segments)

    _handle_tokens(token_groups)


func _set_puzzle_meta(value: PuzzleMeta) -> void :
    puzzle_meta = value

    if not puzzle:
        return

    puzzle.puzzle_meta = value

    if not Engine.is_editor_hint() and value is PuzzleMeta:

        var state: Dictionary = {}
        var restored_state: Variant = ProgressManager.get_puzzle_state(puzzle_meta.puzzle_id)

        _segment_discovery_state = DiscoveryManager.get_segment_discovery_state(puzzle_meta.puzzle_id)

        if typeof(restored_state) == TYPE_DICTIONARY:

            state = restored_state.get(
                SegmentedPuzzleKey.DATA, 
                {}, 
            )

        for component_id: int in state.keys():
            if _phrase_slot_map.has(component_id):
                _phrase_slot_map[component_id].add_slotted_item(state[component_id])

        _segment_discovery_state.prev_segment_state = _apply_default_segment_state(_segment_discovery_state.prev_segment_state)
        _segment_discovery_state.current_segment_state = _apply_default_segment_state(_segment_discovery_state.current_segment_state)

        for segment in _segments:
            if puzzle_meta.segmentation_mode == PuzzleMeta.SegmentationMode.NONE:
                segment.obscured = false
            else:
                segment.obscured = not FlagsUtils.flag_state_pos(

                _segment_discovery_state.prev_segment_state, 
                segment.id as int, 
            )

        puzzle.custom_puzzle_component_container = self
        puzzle.validated.connect(_on_puzzle_validated)
        puzzle.solved.connect(func() -> void : solved.emit())
        puzzle.solved_and_updated.connect(func() -> void : solved_and_updated.emit())

        _infinite = true if not phrase_grids.size() else phrase_grids.all(func(pg: Control) -> bool: return pg.infinite)

        if not _infinite:
            var used_item_ids: Array = state.values()

            for phrase_grid in phrase_grids:
                phrase_grid.queue_remove_items(used_item_ids)

            for phrase_slot: Variant in _phrase_slot_map.values():
                phrase_slot.set_dropreceiver_infinite(false)

        puzzle.puzzle_ready()
        _init_done = true

        container.droppable_nodes_updated.connect(_on_drop)


func _set_auto_mark_solved(v: bool) -> void :
    auto_mark_solved = v
    if puzzle:
        puzzle.auto_mark_solved = v


func _set_preview_ids(value: bool) -> void :
    preview_ids = value

    if Engine.is_editor_hint():
        for label in _puzzle_component_id_hints:
            if preview_ids:
                label.show()
            else:
                label.hide()


func _set_preview_answers(value: bool) -> void :
    preview_answers = value
    if Engine.is_editor_hint() and container:
        for c in container.get_children():
            if not "debug_hint" in c.get_property_list().map(func(prop: Dictionary) -> String: return prop.name):
                continue
            if preview_answers:
                _set_phrase_slot_answer(c as Control)
            else:
                c.debug_hint = ""


func _handle_tokens(token_groups: Array[String]) -> void :
    var group_count: int = len(token_groups)


    _tmp_id = 0
    for label in _phrase_grid_segment_idx_hints:
        label.queue_free()
    _phrase_grid_segment_idx_hints = []

    if Engine.is_editor_hint():
        for label in _puzzle_component_id_hints:
            label.queue_free()
        _puzzle_component_id_hints = []

    var non_line_start_punctuation: Array[String] = [
        ".", "!", "?", ",", ";", ":", 
        "¿", "¡", 
        "…", 
        "・", "。", "、", 
        "？", "！", 
        "，", "；", "：", 
        "」", "』", 
        "》", "〉", 
        "）", "｝", 
    ]

    for i: int in group_count:
        var dividers: Array[Control] = []
        var group: String = token_groups[i]
        var segment: Control = SegmentScene.instantiate()
        segment.id = i
        _tmp_id = i
        _segments.append(segment)
        var tokens: Array[ScrollTextParser.ScrollTextToken] = parser.parse_text(group)
        var _last_token: ScrollTextParser.ScrollTextToken
        var _last_phrase_slot: HBoxContainer

        for token in tokens:
            match token.type:
                ScrollTextParser.ScrollTextTokenType.PLAIN:
                    var label: Label = Label.new()
                    label.text = token.content
                    @warning_ignore("unassigned_variable")
                    if token.content in non_line_start_punctuation and _last_token.type == ScrollTextParser.ScrollTextTokenType.SMART:


                        @warning_ignore("unassigned_variable")
                        _last_phrase_slot.add_child(label)
                    else:
                        segment.add_text(label)
                ScrollTextParser.ScrollTextTokenType.SMART:
                    var for_id: Variant = token.data.get(TOKEN_DATA_FOR_ID)
                    var pronoun: Variant = token.data.get(TOKEN_DATA_PRONOUN_KEY)
                    var article: Variant = token.data.get(TOKEN_DATA_ARTICLE)

                    if for_id and pronoun:
                        var pronoun_instance: = NounMarkerScene.instantiate()
                        pronoun_instance.for_id = int(for_id as String)
                        pronoun_instance.marker_type = pronoun_instance.NounMarkerType.PRONOUN
                        pronoun_instance.pronoun_key = pronoun
                        pronoun_instance.fallback = token.data.get(TOKEN_DATA_DEFAULT, "")
                        pronoun_instance.text = pronoun_instance.fallback
                        segment.add_text(pronoun_instance)
                        continue

                    if for_id and article:
                        var article_instance: = NounMarkerScene.instantiate()
                        article_instance.marker_type = article_instance.NounMarkerType.ARTICLE
                        article_instance.for_id = int(for_id as String)
                        article_instance.fallback = article
                        article_instance.text = article
                        segment.add_text(article_instance)
                        continue

                    var phrase_slot: HBoxContainer = PhraseSlotScene.instantiate()
                    var width: Variant = token.data.get(TOKEN_DATA_WIDTH)
                    var slot_id: Variant = token.data.get(TOKEN_DATA_ID)
                    phrase_slot.id = int(slot_id as String) if slot_id else phrase_slot.get_instance_id()
                    phrase_slot.initial_width = float(width as String) if width else 120.0
                    _last_phrase_slot = phrase_slot
                    _phrase_slot_map[phrase_slot.id] = phrase_slot

                    if Engine.is_editor_hint():
                        var id_hint: = Label.new()
                        id_hint.text = str(phrase_slot.id)
                        phrase_slot.get_child(0).add_child(id_hint)
                        id_hint.set("theme_override_colors/font_color", Color.WHITE)
                        id_hint.set("theme_override_colors/font_shadow_color", Color.BLACK)
                        id_hint.z_index = 100
                        id_hint.z_as_relative = true
                        id_hint.position = Vector2(phrase_slot.size.x / 2, - phrase_slot.size.y + 5)
                        if not preview_ids:
                            id_hint.hide()
                        _puzzle_component_id_hints.append(id_hint)

                        if preview_answers:
                            _set_phrase_slot_answer(phrase_slot)

                    segment.add_text(phrase_slot)
                ScrollTextParser.ScrollTextTokenType.BREAK:
                    var divider: Control = Control.new()
                    divider.mouse_filter = divider.MOUSE_FILTER_IGNORE
                    dividers.append(divider)
                    segment.add_text(divider)

            _last_token = token

        container.add_child(segment)
        call_deferred("_size_dividers", dividers, segment, 0)


    for i in len(phrase_grids):
        _tmp_id += 1
        var grid_segment: Control = phrase_grids[i]
        if not Engine.is_editor_hint():
            grid_segment.id = _tmp_id

        _segments.append(grid_segment)

    for i in len(custom_segments):
        _tmp_id += 1
        var custom_segment: CustomSegment = custom_segments[i]
        if not Engine.is_editor_hint():
            custom_segment.id = _tmp_id
        _segments.append(custom_segment)

    if not Engine.is_editor_hint():
        container.query_drop_receivers()
        if DevTools.active:
            for seg: Control in _segments:
                var idx_label: = DebugLabelScene.instantiate()
                idx_label.set_segment_label(seg.id)
                seg.add_child(idx_label)
                idx_label.visible = DevTools.overlay_visible
                _phrase_grid_segment_idx_hints.append(idx_label)


func _size_dividers(dividers: Array[Control], group_container: Control, idx: int) -> void :



    if idx > dividers.size() - 1:
        return

    var d: = dividers[idx]
    d.custom_minimum_size = Vector2(
        (group_container.size.x - d.position.x) as float, 
        1.0, 
    )

    call_deferred("_size_dividers", dividers, group_container, idx + 1)





func _on_drop(new_drop_state: Array) -> void :
    var phrase_map: = {}
    for state_entry: Dictionary in new_drop_state:
        var draggable_meta: Dictionary = state_entry.get("draggable", {})
        phrase_map[state_entry["slot"]["id"]] = draggable_meta

    for child in container.get_children():
        if not child is NounMarker:
            continue

        var for_id: int = child.get("for_id")
        var phrase_entry: Dictionary = phrase_map.get(for_id)

        if for_id is int:
            if child.marker_type == child.NounMarkerType.PRONOUN:
                var pronoun: String = child.fallback
                if phrase_entry:
                    pronoun = phrase_entry.get("pronouns").get(child.pronoun_key)
                child.text = pronoun

            if child.marker_type == child.NounMarkerType.ARTICLE:
                var article: = (child as NounMarker).fallback
                if phrase_entry:
                    article = phrase_entry.get("article")
                child.text = article


func _on_puzzle_validated(completeness: Puzzle.PuzzleCompletenessState, total: int, valid: int, filled: int) -> void :
    _save_state()
    validated.emit(completeness, total, valid, filled)


func _save_state() -> void :
    if not _init_done:
        return

    var new_state: Dictionary = {}
    for k: int in _phrase_slot_map:
        var slotted_id: int = _phrase_slot_map[k].slotted_id
        if slotted_id > 0:
            new_state[k] = slotted_id

    ProgressManager.set_puzzle_state(puzzle_meta.puzzle_id, {
        SegmentedPuzzleKey.DATA: new_state, 
        SegmentedPuzzleKey.SEGMENTS: _segment_discovery_state.current_segment_state, 
    })


func _set_phrase_slot_answer(phrase_slot: Control) -> void :
    phrase_slot.debug_hint = _answer_hints.get(phrase_slot.id, "")


func _build_answer_data() -> void :
    _answer_hints = {}
    for c in get_children():
        if not c is PuzzleComponent:
            continue

        if not c.get_child_count():
            continue

        var first_child: = c.get_child(0)


        if first_child is PuzzleAnswerContainer:
            first_child = first_child.get_child(0)

        if first_child is PuzzleAnswerItem:
            _answer_hints[(c as PuzzleComponent).id] = Database.get_item_by_id(
                first_child.answer_item_ref_id as int
            ).name


func _on_puzzle_segments_unlocked(puzzle_id: int, new_segment_state: int) -> void :
    if not puzzle_meta or puzzle_meta.puzzle_id != puzzle_id:
        return

    var final_state: int = _apply_default_segment_state(new_segment_state)
    _segment_discovery_state.current_segment_state = final_state

    if _container_open:
        _mark_segments_discovered()


func _apply_default_segment_state(current_segment_state: int) -> int:
    var new_state: int = current_segment_state

    var seg_mode: = puzzle_meta.segmentation_mode

    if seg_mode == PuzzleMeta.SegmentationMode.PUZZLE_DEFAULT:

        new_state = FlagsUtils.flag_on(new_state, DEFAULT_VISIBLE_SEGMENTS)
        return new_state

    if seg_mode == PuzzleMeta.SegmentationMode.OBSCURE_ALL:

        return current_segment_state

    if seg_mode == PuzzleMeta.SegmentationMode.SPECIFY and puzzle.puzzle_meta.specified_segments.size():
        for i: int in puzzle.puzzle_meta.specified_segments:
            new_state = FlagsUtils.flag_on_pos(new_state, i)
    return new_state


func _on_scenario_reset(_scenario_id: int) -> void :
    if puzzle_meta.arc_puzzle:
        return

    for puzzle_component_id: int in _phrase_slot_map:
        _phrase_slot_map[puzzle_component_id].free_draggable(true, true)

    puzzle.reset()


func _use_puzzle_part_hiders() -> void :
    if not len(puzzle_part_hiders):
        return

    var obscurables: Array[Control] = []
    obscurables.assign(_phrase_slot_map.values())

    for phrase_grid in phrase_grids:
        obscurables.append_array(phrase_grid.get_phrase_grid_slots() as Array[Control])

    for pph in puzzle_part_hiders:
        if not is_instance_valid(pph):

            continue

        var pph_rect: Rect2 = pph.get_global_rect()


        for obscurable: Control in obscurables:
            if pph_rect.encloses(obscurable.get_global_rect()):
                obscurable.obscured = true
                pph.revealed.connect(
                    func() -> void : obscurable.obscured = false, 
                    CONNECT_ONE_SHOT
                )

    puzzle_part_hiders = []


func _on_devtools_toggled(made_visible: bool) -> void :
    for label in _phrase_grid_segment_idx_hints:
        label.visible = made_visible
