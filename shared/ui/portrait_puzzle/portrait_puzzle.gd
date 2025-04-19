@tool
class_name PortraitPuzzle
extends Control

signal validated(completeness: Puzzle.PuzzleCompletenessState, total: int, valid: int, filled: int)
signal solved

@export var puzzle_meta: PuzzleMeta:
    set = set_puzzle_meta
var auto_mark_solved: bool = false:
    set = set_auto_mark_solved


var cards: = {}

var validation_result: Puzzle.ValidationResult:
    get: return puzzle.validation_result if puzzle else null
var _init_done: bool

@onready var puzzle: Puzzle = $Puzzle
@onready var card_container: Container = get_child(get_child_count() - 1)


func _ready() -> void :
    set_puzzle_meta(puzzle_meta)
    set_auto_mark_solved(auto_mark_solved)
    _setup_focus_neighbors()
    if not Engine.is_editor_hint():
        ProgressManager.scenario_reset.connect(_on_scenario_reset)


func mark_solved() -> void :
    puzzle.mark_solved()


func request_focus(side: Constants.FocusSide) -> Variant:
    var card_focus_candidates: Array[Node] = []
    for card: PortraitPuzzleCard in cards.values():
        card_focus_candidates.append(card.request_focus(side))
    return NodeUtils.get_node_for_side(side, card_focus_candidates)


func _setup_puzzle_event_proxies() -> void :
    puzzle.validated.connect(_on_puzzle_validated)
    puzzle.solved.connect(func() -> void : solved.emit())


func _load() -> void :
    var editor_running: bool = Engine.is_editor_hint()
    var discovered_characters: = [] if editor_running else ProgressManager.get_discovered_character_ids()
    var puzzle_component_id: = 1
    var all_cards: = _get_cards()
    var all_cards_count: = len(all_cards)
    var state: Array

    var stored_state: Variant
    if editor_running:
        stored_state = null
    else:
        stored_state = ProgressManager.get_puzzle_state(puzzle_meta.puzzle_id)

    if typeof(stored_state) == TYPE_ARRAY:
        state = stored_state
    else:
        state = range(all_cards_count * 2).map(func(_i: int) -> int: return 0)

    for i in all_cards_count:
        var c: = all_cards[i]
        var char_id: int = c.link_character_ref_id
        cards[char_id] = c

        var custom_portrait: Variant = c.custom_portrait
        if custom_portrait is Texture2D and not Engine.is_editor_hint():
            ProgressManager.register_character_portrait_override(char_id, custom_portrait as Texture2D)

        c.discovered = char_id in discovered_characters

        c.first_name_puzzle_component_id = puzzle_component_id
        var first_name_state: int = state[i * 2]
        if first_name_state > 0:
            c.add_first_name_item(first_name_state)
        puzzle_component_id += 1

        c.last_name_puzzle_component_id = puzzle_component_id
        var last_name_state: int = state[i * 2 + 1]
        if last_name_state > 0:
            c.add_last_name_item(last_name_state)
        puzzle_component_id += 1


func set_puzzle_meta(v: PuzzleMeta) -> void :
    puzzle_meta = v

    if puzzle:
        puzzle.puzzle_meta = v

        if not puzzle_meta is PuzzleMeta:
            return

        _load()

        if Engine.is_editor_hint():
            return

        _setup_puzzle_event_proxies()

        ProgressManager.character_discovered.connect(_on_character_discovered)

        puzzle.custom_puzzle_component_container = self
        call_deferred("_puzzle_ready")


func set_auto_mark_solved(v: bool) -> void :
    auto_mark_solved = v
    if puzzle:
        puzzle.auto_mark_solved = v


func _get_cards() -> Array[Node]:
    return card_container.get_children()


func _on_character_discovered(character_id: int) -> void :
    if cards.has(character_id):
        cards[character_id].discovered = true


func _on_puzzle_validated(completeness: Puzzle.PuzzleCompletenessState, total: int, valid: int, filled: int) -> void :
    _store_state()
    validated.emit(completeness, total, valid, filled)


func _puzzle_ready() -> void :
    puzzle.puzzle_ready()
    _init_done = true


func _store_state() -> void :
    if not _init_done:
        return

    var new_state: Array[int] = []
    for card in _get_cards():

        new_state.append(card.first_name_slot.slotted_id)
        new_state.append(card.last_name_slot.slotted_id)

    ProgressManager.set_puzzle_state(puzzle_meta.puzzle_id, new_state)


func _on_scenario_reset(_scenario_id: int) -> void :
    if puzzle_meta.arc_puzzle:
        return

    for card in _get_cards():
        card.clear()

    _store_state()
    puzzle.reset()


func _setup_focus_neighbors() -> void :
    var i: int = 0
    var all_cards: Array[PortraitPuzzleCard] = []
    all_cards.assign(_get_cards())
    var last_idx: int = len(all_cards) - 1
    for card: PortraitPuzzleCard in all_cards:
        if i > 0:
            var s: Side = SIDE_LEFT
            var target: PortraitPuzzleCard = all_cards[i - 1]
            card.set_first_name_slot_focus_neighbor(s, target.get_first_name_slot_path())
            card.set_last_name_slot_focus_neighbor(s, target.get_last_name_slot_path())
        if i != last_idx:
            var s: Side = SIDE_RIGHT
            var target: PortraitPuzzleCard = all_cards[i + 1]
            card.set_first_name_slot_focus_neighbor(s, target.get_first_name_slot_path())
            card.set_last_name_slot_focus_neighbor(s, target.get_last_name_slot_path())
        i += 1
