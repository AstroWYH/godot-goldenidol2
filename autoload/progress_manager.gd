extends Node



signal puzzle_solved(puzzle: PuzzleMeta)
signal puzzles_unlocked(puzzles: Array[PuzzleMeta])
signal puzzle_segments_unlocked(puzzle_id: int, new_segment_state: int)
signal scenario_meta_changed(scenario_meta: ScenarioMeta)
signal scenario_unlocked(scenario_id: int)
signal scenario_beaten(scenario_id: int)
signal scenario_reset(scenario_id: int)
signal items_unlocked(item_ids: Array[int])
signal character_discovered(character_id: int)
signal items_sorted()
signal used_items_updated()
signal entities_unlocked(item_ids: Array[int], character_id: int, puzzles: Array[PuzzleMeta])
signal ghost_summary_requested(item_ids: Array[int], character_id: int, puzzles: Array[PuzzleMeta])
signal escalate_music_request(escalation_level: int)
signal location_visited(location_id: int)
signal screen_change_called


signal phrase_moved

enum PuzzleItemUsage{
	UNUSED, 
	IN_PUZZLE, 
	IN_SOLVED_PUZZLE, 
}

const REQUIREMENTS: ProgressRequirementTable = preload("res://shared/data/progress_requirements.tres")
const SCENARIO_RESET_COVER_PATH: String = "res://shared/ui/in_game_menu/scenario_reset_cover/scenario_reset_cover.tscn"
const Inventory = preload("res://shared/utils/inventory.gd")

const INDEX_SCENARIO_ID = 0
const INDEX_PUZZLE_IDS = 1

const GSK: = PersistenceManager.GameStateKey
const KEY_PUZZLE_STATES: int = GSK.PUZZLE_STATES
const KEY_UNLOCKED_PUZZLES: int = GSK.UNLOCKED_PUZZLES
const KEY_DISCOVERED_CHARACTERS: int = GSK.DISCOVERED_CHARACTERS
const KEY_UNLOCKED_SCENARIOS: int = GSK.UNLOCKED_SCENARIOS
const KEY_BEATEN_SCENARIOS: int = GSK.BEATEN_SCENARIOS
const KEY_INVENTORIES: int = GSK.INVENTORIES
const KEY_ARC_INVENTORIES: int = GSK.ARC_INVENTORIES
const VISITED_SCENARIOS: int = GSK.VISITED_SCENARIOS
const VISITED_ARCS: int = GSK.VISITED_ARCS
const INTERMISSIONS_SHOWN: int = GSK.INTERMISSIONS_SHOWN
const ARCS_FINISHED: int = GSK.ARCS_FINISHED
const LOCATIONS_VISITED: int = GSK.LOCATIONS_VISITED
const HINTS_UNLOCKED: int = GSK.HINTS_UNLOCKED
const ENDING_CREDITS_SHOWN: int = GSK.ENDING_CREDITS_SHOWN
const TUTORIAL_FINISHED: int = GSK.TUTORIAL_FINISHED
const SNIPPETS_VISITED: int = GSK.SNIPPETS_VISITED

var current_arc_id: int
var current_scenario_id: int
var current_scenario: Node2D
var current_chapter_meta: ArcMeta = null
var current_scenario_meta: ScenarioMeta:
	set = _set_current_scenario_meta
var win_condition_puzzle_ids: Array[int] = []
var current_inventory: RefCounted

var inventory_card: Control

var portrait_overrides: Dictionary = {}

var _locked_scenarios: Array = []


var _puzzle_items: Dictionary = {}

var _item_usage: Dictionary = {}


var intro_arc_ending_screen: Control = null


var dialog_layer: CanvasLayer


var visited_scenarios: Array = []


var visited_arcs: Array = []


var arcs_finished: Array = []


var intermissions_shown: Array = []


var visited_locations: Dictionary = {}


var all_arcs_unlocked: bool = false


var victory_sequence_playing: bool = false


var unlocked_hints: Array = []


var ending_credits_shown: bool = false

var tutorial_finished: bool = false



var initial_tutorial_in_progress: bool = false

var snippets_visited: Array = []


func _ready() -> void :
	PersistenceManager.state_reset.connect(_prepare_locked_scenarios)
	PersistenceManager.state_loaded.connect(func(_state: Dictionary) -> void : _on_state_load())


func register_character_portrait_override(character_id: int, override_portrait: Texture2D) -> void :
	portrait_overrides[character_id] = override_portrait







func register_unlockable_scenario(scenario_id: int, required_puzzle_ids: Array) -> void :
	_locked_scenarios.push_front([
		scenario_id, required_puzzle_ids
	])




func mark_puzzle_solved(puzzle: PuzzleMeta) -> void :
	var solved_puzzles: = _get_solved_puzzles()
	var puzzle_id: = puzzle.puzzle_id

	if puzzle.escalate_music_on_solve:
		escalate_music_request.emit(puzzle.escalation_level)

	if puzzle_id in solved_puzzles:
		return

	_set_puzzle_item_collection_as_solved(puzzle_id)

	solved_puzzles.append(puzzle_id)
	solved_puzzles.sort()
	puzzle_solved.emit(puzzle)

	if len(puzzle.unlocks_puzzles_on_solve):
		var new_puzzles: Array[PuzzleMeta] = ProgressManager.unlock_puzzles(puzzle.unlocks_puzzles_on_solve)
		if len(new_puzzles):
			show_unlocked_entities([], 0, new_puzzles, [])

	if len(puzzle.unlocks_segments_on_solve):
		for puzzle_seg_unlock: PuzzleSegmentUnlock in puzzle.unlocks_segments_on_solve:
			unlock_puzzle_segments(
				puzzle_seg_unlock.puzzle_meta.puzzle_id, 
				puzzle_seg_unlock.segment_indices, 
			)


	var req_scenario_count: int = len(win_condition_puzzle_ids)
	if req_scenario_count:
		var hits: int = 0
		for pid: int in solved_puzzles:
			if pid in win_condition_puzzle_ids:
				hits += 1

		if hits == req_scenario_count:
			if not is_scenario_beaten(current_scenario_id):
				scenario_beaten.emit(current_scenario_id, puzzle)
				mark_current_scenario_beat()


	var still_locked_scenarios: = []
	for scenario: Array in _locked_scenarios:
		var unlocked_puzzle_count: = 0
		var scenario_id: int = scenario[INDEX_SCENARIO_ID]
		var required_puzzles: Array = scenario[INDEX_PUZZLE_IDS]

		for required_puzzle_id: int in required_puzzles:
			if required_puzzle_id in solved_puzzles:
				unlocked_puzzle_count += 1
			else:

				break

		if unlocked_puzzle_count == required_puzzles.size():
			PersistenceManager.state.get(KEY_UNLOCKED_SCENARIOS).append(scenario_id)
			scenario_unlocked.emit(scenario_id)
		else:
			still_locked_scenarios.append(scenario)

	_locked_scenarios = still_locked_scenarios

	PersistenceManager.mark_state_changed()


func enough_puzzles_solved(count: int) -> bool:
	var solved_puzzles: = _get_solved_puzzles()
	var req_scenario_count: int = len(win_condition_puzzle_ids)

	var hits: int = 0
	for pid: int in solved_puzzles:
		if pid in win_condition_puzzle_ids:
			hits += 1

	if hits + count == req_scenario_count:
		return true
	else:
		return false


func unmark_scenario_beaten(target_scenario_id: int) -> void :
	PersistenceManager.state[KEY_BEATEN_SCENARIOS] = PersistenceManager.state[KEY_BEATEN_SCENARIOS].filter(
		func(scenario_id: int) -> bool: return scenario_id != target_scenario_id
	)
	PersistenceManager.mark_state_changed()


func unmark_puzzle_solved(puzzle_id: int) -> void :
	var solved_puzzles: = _get_solved_puzzles()
	PersistenceManager.state[PersistenceManager.GameStateKey.SOLVED_PUZZLES] = solved_puzzles.filter(
		func(solved_id: int) -> bool: return solved_id != puzzle_id
	)
	PersistenceManager.mark_state_changed()


func get_current_item_count() -> int:
	return PersistenceManager.state[KEY_INVENTORIES].get(
		current_scenario_id, [], 
	).filter(func(i: int) -> bool: return i > 0).size()


func unlock_items(item_ids: Array[int]) -> Array[int]:
	if not len(item_ids):
		return []

	var scenario_inventory: Array[int] = []
	scenario_inventory.assign(PersistenceManager.state[KEY_INVENTORIES].get(
		current_scenario_id, [], 
	) as Array)


	var inv_size: int = scenario_inventory.size()
	var inv_size_max: int = Inventory.INVENTORY_CAPACITY

	if inv_size == 0:
		var empty_inventory: Array[int] = []
		empty_inventory.resize(inv_size_max)
		empty_inventory.fill(0)
		scenario_inventory = empty_inventory
	elif inv_size < inv_size_max:
		var remaining: Array = range(inv_size_max - inv_size)
		remaining.fill(0)
		scenario_inventory.append_array(remaining)

	var unlocked_items: Array[int] = []

	for item_id in item_ids:
		if item_id in scenario_inventory:
			continue
		unlocked_items.append(item_id)

	if len(unlocked_items) > 0:
		current_inventory.set_inventory_item_layout(scenario_inventory, unlocked_items)
		set_current_scenario_inventory(scenario_inventory)
		items_unlocked.emit(unlocked_items)

	return unlocked_items


func get_scenario_inventory() -> Array[int]:
	var inventory: Array[int] = []

	inventory.assign(PersistenceManager.state[PersistenceManager.GameStateKey.INVENTORIES].get(
		current_scenario_id, 
		[], 
	) as Array)

	return inventory


func set_current_scenario_inventory(inventory: Array) -> void :
	PersistenceManager.state[KEY_INVENTORIES][current_scenario_id] = inventory
	PersistenceManager.mark_state_changed()
	phrase_moved.emit()

func get_discovered_character_ids() -> Array:
	return PersistenceManager.state[KEY_DISCOVERED_CHARACTERS]


func discover_character(character_id: int, check_if_known: bool = true) -> bool:
	var known_characters: Array = PersistenceManager.state[KEY_DISCOVERED_CHARACTERS]

	if check_if_known and character_id in known_characters:
		return false

	known_characters.append(character_id)
	PersistenceManager.mark_state_changed()
	character_discovered.emit(character_id)

	return true


func is_character_discovered(character_id: int) -> bool:
	return character_id in PersistenceManager.state[KEY_DISCOVERED_CHARACTERS]


func forget_character(character_id: int) -> void :
	var known_characters: Array = PersistenceManager.state[KEY_DISCOVERED_CHARACTERS]
	PersistenceManager.state[KEY_DISCOVERED_CHARACTERS] = known_characters.filter(
		func(known_id: int) -> bool: return known_id != character_id
	)
	PersistenceManager.mark_state_changed()


func get_puzzle_state(puzzle_id: int) -> Variant:
	return PersistenceManager.state[KEY_PUZZLE_STATES].get(puzzle_id)


func set_puzzle_state(puzzle_id: int, new_state: Variant) -> void :
	PersistenceManager.state[KEY_PUZZLE_STATES][puzzle_id] = new_state
	PersistenceManager.mark_state_changed()


func save_visited_scenarios() -> void :
	PersistenceManager.state[VISITED_SCENARIOS] = visited_scenarios
	PersistenceManager.mark_state_changed()


func save_visited_arcs() -> void :
	PersistenceManager.state[VISITED_ARCS] = visited_arcs
	PersistenceManager.mark_state_changed()


func save_visited_snippets() -> void :
	PersistenceManager.state[SNIPPETS_VISITED] = snippets_visited
	PersistenceManager.mark_state_changed()


func save_finished_arcs() -> void :
	PersistenceManager.state[ARCS_FINISHED] = arcs_finished
	PersistenceManager.mark_state_changed()


func save_tutorial_finished() -> void :
	PersistenceManager.state[TUTORIAL_FINISHED] = tutorial_finished
	PersistenceManager.mark_state_changed()


func load_tutorial_finished(new_gamestate: Dictionary) -> void :
	tutorial_finished = new_gamestate[TUTORIAL_FINISHED]


func unlock_hint(hint_id: int) -> void :
	if not hint_id in unlocked_hints:
		unlocked_hints.append(hint_id)
		save_unlocked_hints()


func save_unlocked_hints() -> void :
	PersistenceManager.state[HINTS_UNLOCKED] = unlocked_hints
	PersistenceManager.mark_state_changed()


func save_final_credits_scene_shown() -> void :
	ending_credits_shown = true
	PersistenceManager.state[ENDING_CREDITS_SHOWN] = ending_credits_shown
	PersistenceManager.mark_state_changed()


func load_visited_scenarios(new_gamestate: Dictionary) -> void :
	visited_scenarios = new_gamestate[VISITED_SCENARIOS]


func load_visited_snippets(new_gamestate: Dictionary) -> void :
	snippets_visited = new_gamestate[SNIPPETS_VISITED]


func load_unlocked_hints(new_gamestate: Dictionary) -> void :
	unlocked_hints = new_gamestate[HINTS_UNLOCKED]


func load_shown_final_credits_scene(_new_gamestate: Dictionary) -> void :
	ending_credits_shown = PersistenceManager.state[ENDING_CREDITS_SHOWN]


func load_visited_arcs(new_gamestate: Dictionary) -> void :
	visited_arcs = new_gamestate[VISITED_ARCS]


func load_finished_arcs(new_gamestate: Dictionary) -> void :
	arcs_finished = new_gamestate[ARCS_FINISHED]


func save_intermission_shown(id: int) -> void :
	intermissions_shown.append(id)
	PersistenceManager.state[INTERMISSIONS_SHOWN] = intermissions_shown
	PersistenceManager.mark_state_changed()


func load_intermission_shown(new_gamestate: Dictionary) -> void :
	intermissions_shown = new_gamestate[INTERMISSIONS_SHOWN]


func unlock_puzzle_segments(puzzle_id: int, segment_indices: Array[int]) -> void :
	if not len(segment_indices):
		return

	var key: int = PersistenceManager.SegmentedPuzzleKey.SEGMENTS
	var puzzle_state: Dictionary = PersistenceManager.state[KEY_PUZZLE_STATES].get(puzzle_id, {})

	var open_segments: int = puzzle_state.get(key, 0)
	var prev_state: int = open_segments

	for idx in segment_indices:
		open_segments = FlagsUtils.flag_on_pos(open_segments, idx)

	if open_segments == prev_state:
		return

	puzzle_state[key] = open_segments
	set_puzzle_state(puzzle_id, puzzle_state)
	puzzle_segments_unlocked.emit(puzzle_id, open_segments)


func register_item_puzzle(puzzle_id: int) -> void :
	var entry: = PuzzleItemCollection.new()
	entry.puzzle_solved = puzzle_id in _get_solved_puzzles()
	_puzzle_items[puzzle_id] = entry


func sort_pressed() -> void :
	var scenario_inventory: Array[int] = current_inventory.sort_inventory(get_scenario_inventory())
	set_current_scenario_inventory(scenario_inventory)
	PersistenceManager.state[KEY_INVENTORIES][current_scenario_id] = scenario_inventory
	PersistenceManager.mark_state_changed()
	items_sorted.emit()


func set_used_puzzle_items(puzzle_id: int, items: Dictionary, puzzle_is_solved: bool = false) -> void :
	if not OS.has_feature("item_usage"):
		return

	var collection: PuzzleItemCollection = _puzzle_items[puzzle_id]
	collection.used_item_ids = items
	collection.puzzle_solved = puzzle_is_solved

	_item_usage = {}
	for p_id: int in _puzzle_items:
		var c: PuzzleItemCollection = _puzzle_items[p_id]
		for item_id: int in c.used_item_ids:
			var usage: PuzzleItemUsage = _item_usage.get(item_id, PuzzleItemUsage.IN_PUZZLE)

			if usage == PuzzleItemUsage.IN_SOLVED_PUZZLE:
				continue

			if c.puzzle_solved:
				usage = PuzzleItemUsage.IN_SOLVED_PUZZLE

			_item_usage[item_id] = usage

	used_items_updated.emit()


func is_puzzle_unlocked(puzzle_id: int) -> bool:
	return puzzle_id in PersistenceManager.state.get(KEY_UNLOCKED_PUZZLES, [])


func is_puzzle_solved(puzzle_id: int) -> bool:
	if puzzle_id in _get_solved_puzzles():
		return true
	else:
		return false


func unlock_puzzles(puzzles: Array[PuzzleMeta]) -> Array[PuzzleMeta]:
	var new_puzzles: Array[PuzzleMeta] = []
	var unlocked_puzzles: Array = PersistenceManager.state.get(KEY_UNLOCKED_PUZZLES, [])

	for puzzle_meta in puzzles:
		if not is_puzzle_unlocked(puzzle_meta.puzzle_id):
			new_puzzles.append(puzzle_meta)
			unlocked_puzzles.append(puzzle_meta.puzzle_id)

	PersistenceManager.state[KEY_UNLOCKED_PUZZLES] = unlocked_puzzles
	PersistenceManager.mark_state_changed()

	if len(new_puzzles):
		puzzles_unlocked.emit(new_puzzles)

	return new_puzzles


func relock_puzzles(puzzle_ids: Array[int]) -> void :
	var unlocked_puzzles: Array = PersistenceManager.state.get(KEY_UNLOCKED_PUZZLES, [])
	PersistenceManager.state[KEY_UNLOCKED_PUZZLES] = unlocked_puzzles.filter(
		func(value: int) -> bool:
			return value not in puzzle_ids
	)
	PersistenceManager.mark_state_changed()


func is_scenario_unlocked(scenario_id: int) -> bool:
	return scenario_id in PersistenceManager.state[KEY_UNLOCKED_SCENARIOS]


func is_scenario_beaten(scenario_id: int) -> bool:
	return scenario_id in PersistenceManager.state[KEY_BEATEN_SCENARIOS]


func is_current_scenario_beaten() -> bool:
	if not current_scenario_id is int:
		return false
	return current_scenario_id in PersistenceManager.state[KEY_BEATEN_SCENARIOS]


func mark_current_scenario_beat() -> void :
	if current_scenario_meta and current_scenario_meta.achievement_id > 0:
		Platform.award_achievement(current_scenario_meta.achievement_id)

	if is_scenario_beaten(current_scenario_id):
		return

	PersistenceManager.state[KEY_BEATEN_SCENARIOS].append(current_scenario_id)

	var puzzles_to_unlock: Array[PuzzleMeta] = []
	if current_scenario_meta.victory_unlocks_segments.size():
		for segment_unlock: PuzzleSegmentUnlock in current_scenario_meta.victory_unlocks_segments:
			var puzzle_meta: PuzzleMeta = segment_unlock.puzzle_meta
			var puzzle_id: int = puzzle_meta.puzzle_id

			unlock_puzzle_segments(puzzle_id, segment_unlock.segment_indices)
			puzzles_to_unlock.append(puzzle_meta)

	if len(current_scenario_meta.victory_unlocks_arc_phrases):
		var arc_id: int = current_scenario_meta.arc.id
		var inventory: Array = PersistenceManager.state[KEY_ARC_INVENTORIES].get(
			arc_id, 
			[], 
		)

		for item in current_scenario_meta.victory_unlocks_arc_phrases:
			var item_id: int = item.linked_item_ref_id
			if not item_id in inventory:
				inventory.append(item_id)

		PersistenceManager.state[KEY_ARC_INVENTORIES][arc_id] = inventory

	unlock_puzzles(puzzles_to_unlock)
	PersistenceManager.mark_state_changed()


func fast_forward_available() -> bool:
	var required_puzzles: Array[int] = [101, 102]
	for puzzle_id in required_puzzles:
		if not ProgressManager.is_puzzle_solved(puzzle_id):
			return true
	return false


func get_item_usage(item_id: int) -> PuzzleItemUsage:
	return _item_usage.get(item_id, PuzzleItemUsage.UNUSED)


func clear_scenario_data() -> void :
	current_scenario_id = 0
	current_scenario_meta = null
	current_scenario = null
	win_condition_puzzle_ids = []
	portrait_overrides = {}
	_puzzle_items = {}
	_item_usage = {}


func request_current_scenario_reset() -> void :



	set_current_scenario_inventory([])

	for puzzle_id: int in _puzzle_items:
		_puzzle_items[puzzle_id].used_item_ids = {}
		_puzzle_items[puzzle_id].puzzle_solved = false

	_item_usage = {}


	visited_scenarios = visited_scenarios.filter(
		func(id: int) -> bool: return id != current_scenario_id
	)
	reset_visited_locations(current_scenario_id)


	unmark_scenario_beaten(current_scenario_id)

	scenario_reset.emit(current_scenario_id)

	if current_scenario_meta is ScenarioMeta:
		var cl: CanvasLayer = load(SCENARIO_RESET_COVER_PATH).instantiate()
		add_child(cl)
		cl.faded_in.connect(
			func() -> void :


				change_screen(current_scenario_meta)
		)
		cl.fade_in()


func show_ghost_summary(item_ids: Array[int], character_id: int, puzzles: Array[PuzzleMeta], hypothetical_item_ids: Array[int], ) -> void :
	ghost_summary_requested.emit(item_ids, character_id, puzzles, hypothetical_item_ids)


func show_unlocked_entities(item_ids: Array[int], character_id: int, puzzles: Array[PuzzleMeta], hypothetical_item_ids: Array[int]) -> void :
	entities_unlocked.emit(item_ids, character_id, puzzles, hypothetical_item_ids)


func get_current_arc_meta() -> Variant:
	if current_chapter_meta is ArcMeta:
		return current_chapter_meta

	if not current_scenario_meta:
		return null

	return current_scenario_meta.arc


func _get_solved_puzzles() -> Array:
	return PersistenceManager.state[PersistenceManager.GameStateKey.SOLVED_PUZZLES]


func _set_puzzle_item_collection_as_solved(puzzle_id: int) -> void :
	var puzzle_item_collection: PuzzleItemCollection = _puzzle_items.get(puzzle_id)
	if puzzle_item_collection:
		puzzle_item_collection.puzzle_solved = true


func _set_current_scenario_meta(new_scenario_meta: ScenarioMeta) -> void :
	current_scenario_meta = new_scenario_meta
	current_scenario_id = (new_scenario_meta as ScenarioMeta).id if new_scenario_meta is ScenarioMeta else 0

	if new_scenario_meta:
		current_inventory = Inventory.new()
		current_inventory.configure(new_scenario_meta)
	else:
		current_inventory = null

	scenario_meta_changed.emit(new_scenario_meta)


func _prepare_locked_scenarios() -> void :
	_locked_scenarios = []
	var unlocked_scenarios: Array = PersistenceManager.state.get(KEY_UNLOCKED_SCENARIOS)
	for scenario: Array in REQUIREMENTS.data:
		var scenario_id: int = scenario[INDEX_SCENARIO_ID]
		var puzzle_ids: Array = scenario[INDEX_PUZZLE_IDS]

		var unlocked: bool = scenario_id in unlocked_scenarios

		if unlocked:
			continue

		register_unlockable_scenario(scenario_id, puzzle_ids)


class PuzzleItemCollection:
	var used_item_ids: Dictionary = {}
	var puzzle_solved: bool = false




func change_screen(context: Variant) -> void :

	if context == null:
		push_warning("An attempt to change screens without any context!")
		return

	var previous_screen: Node = get_tree().root.get_child(get_tree().root.get_child_count() - 1)

	@warning_ignore("unused_variable")
	var previous_scenario_id: int = -1

	if current_scenario:
		previous_scenario_id = current_scenario_id
	screen_change_called.emit()

	if previous_screen != LoadingScreen:


		previous_screen.queue_free()


	for child in dialog_layer.get_children():
		child.queue_free()

	print("Before await: ", Engine.get_frames_drawn())
	await get_tree().process_frame
	print("After await: ", Engine.get_frames_drawn())


	var new_screen: Node
	var new_screen_path: String


	if context is ScenarioMeta:
		if not len(context.path):
			push_warning("An attempt to launch a scenario without a defined path! Name: ", context.name)
			return


		if not scenario_visited(context.id as int):
			new_screen = load("res://shared/ui/scenario_intro_screen/scenario_intro_screen.tscn").instantiate()
			new_screen.scenario_meta = context
			get_tree().root.add_child(new_screen)
			visited_scenarios.append(context.id)
			save_visited_scenarios()
			MusicPlayer.stop(MusicPlayer.PlayerGroup.MUSIC, 2.0)
			MusicPlayer.stop(MusicPlayer.PlayerGroup.AMBIENCE, 2.0)
			return
		else:

			LoadingScreen.queue_load((context as ScenarioMeta).path)
			return


	if context is ArcMeta:
		if not len(context.hub_scene_path):
			push_warning("An attempt to launch an arc without a defined path! Name: ", context.name)
			return


		if context.id == 6:
			if not 61 in ProgressManager.intermissions_shown:
				new_screen_path = "res://acts/roys_dlc/intermissions/banter_intermission.tscn"
				new_screen = load(new_screen_path).instantiate()
				get_tree().root.add_child(new_screen)
				return


		if not arc_visited(context.id as int):
			new_screen = load("res://shared/ui/scenario_intro_screen/arc_intro_screen.tscn").instantiate()
			new_screen.arc_meta = context
			get_tree().root.add_child(new_screen)
			visited_arcs.append(context.id)
			save_visited_arcs()
			MusicPlayer.stop(MusicPlayer.PlayerGroup.MUSIC, 2.0)
			MusicPlayer.stop(MusicPlayer.PlayerGroup.AMBIENCE, 2.0)
			return

		LoadingScreen.queue_load((context as ArcMeta).hub_scene_path)
		return


	if context is String:
		new_screen_path = context


	if context is PackedScene:
		get_tree().root.add_child((context as PackedScene).instantiate())
		return

	new_screen = load(new_screen_path).instantiate()
	get_tree().root.add_child(new_screen)


func scenario_visited(id: int) -> bool:
	if id in visited_scenarios:
		return true
	else:
		return false


func arc_visited(id: int) -> bool:
	if id in visited_arcs:
		return true
	else:
		return false


func is_location_visited(location_id: int) -> bool:
	if not visited_locations.has(current_scenario_id):
		return false

	if not location_id in visited_locations[current_scenario_id]:
		return false

	return true


func add_location_visited(location_id: int) -> void :
	if not current_scenario:
		return

	if not visited_locations.has(current_scenario_id):
		visited_locations[current_scenario_id] = []

	if location_id in visited_locations[current_scenario_id]:
		return

	visited_locations[current_scenario_id].append(location_id)
	location_visited.emit(location_id)
	PersistenceManager.state[LOCATIONS_VISITED] = visited_locations
	PersistenceManager.mark_state_changed()


func reset_visited_locations(scenario_id: int) -> void :
	visited_locations.erase(scenario_id)
	PersistenceManager.state[LOCATIONS_VISITED] = visited_locations
	PersistenceManager.state[GSK.LAST_LOCATIONS].erase(scenario_id)
	PersistenceManager.mark_state_changed()


func load_visited_locations(new_gamestate: Dictionary) -> void :
	visited_locations = new_gamestate[LOCATIONS_VISITED]


func _on_state_load() -> void :
	_prepare_locked_scenarios()

	for puzzle_id: int in _get_solved_puzzles():
		_set_puzzle_item_collection_as_solved(puzzle_id)

	var new_gamestate: Dictionary = PersistenceManager.state
	var _unlocked_scenarios: Array = new_gamestate.get(PersistenceManager.GameStateKey.UNLOCKED_SCENARIOS)

	load_visited_arcs(new_gamestate)
	load_visited_scenarios(new_gamestate)
	load_intermission_shown(new_gamestate)
	load_finished_arcs(new_gamestate)
	load_visited_locations(new_gamestate)
	load_unlocked_hints(new_gamestate)
	load_shown_final_credits_scene(new_gamestate)
	load_tutorial_finished(new_gamestate)
	load_visited_snippets(new_gamestate)

	if "--skip-tutorial" in OS.get_cmdline_args():
		tutorial_finished = true
