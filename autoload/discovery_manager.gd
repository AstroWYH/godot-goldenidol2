extends Node

enum DiscoveryState{

    LOCKED, 


    DISCOVERED, 


    UNDISCOVERED, 
}

const GSK: = PersistenceManager.GameStateKey
const SegmentedPuzzleKey: = PersistenceManager.SegmentedPuzzleKey

var discovered_state: Dictionary = {}


func _ready() -> void :
    PersistenceManager.state_reset.connect(_clone_state)
    PersistenceManager.state_loaded.connect(func(_state: Dictionary) -> void : _clone_state())


func is_puzzle_discovered(puzzle_meta: PuzzleMeta) -> DiscoveryState:
    var puzzle_id: int = puzzle_meta.puzzle_id

    if not puzzle_meta.locked_by_default:
        return DiscoveryState.DISCOVERED

    if not ProgressManager.is_puzzle_unlocked(puzzle_id):
        return DiscoveryState.LOCKED

    var puzzle_disc_state: Array = discovered_state.get(GSK.UNLOCKED_PUZZLES, [])

    if puzzle_id in puzzle_disc_state:
        return DiscoveryState.DISCOVERED

    return DiscoveryState.UNDISCOVERED


func mark_puzzle_discovered(puzzle_id: int) -> void :
    var current_state: Array = discovered_state.get(GSK.UNLOCKED_PUZZLES, [])
    if puzzle_id in current_state:
        return
    current_state.append(puzzle_id)
    discovered_state[GSK.UNLOCKED_PUZZLES] = current_state


func is_scenario_discovered(scenario_id: int) -> DiscoveryState:
    if not ProgressManager.is_scenario_unlocked(scenario_id):
        return DiscoveryState.LOCKED

    var scenario_disc_state: Array = discovered_state.get(GSK.UNLOCKED_SCENARIOS, [])

    if scenario_id in scenario_disc_state:
        return DiscoveryState.DISCOVERED

    return DiscoveryState.UNDISCOVERED


func mark_scenario_discovered(scenario_id: int) -> void :
    var current_state: Array = discovered_state.get(GSK.UNLOCKED_SCENARIOS, [])
    if scenario_id in current_state:
        return
    current_state.append(scenario_id)
    discovered_state[GSK.UNLOCKED_SCENARIOS] = current_state




func mark_segments_discovered(puzzle_id: int, segment_discovery_state: SegmentDiscovery, segments: Array) -> void :
    var segments_total: int = len(segments)
    var diff: = segment_discovery_state.diff(segments_total)
    for i in segments_total:
        var segment_state: = diff[i]

        var segment: Variant = segments[i]



        if segment_state == DiscoveryState.DISCOVERED:
            segment.obscured = false
        elif segment_state == DiscoveryState.LOCKED:
            segment.obscured = true
        elif segment_state == DiscoveryState.UNDISCOVERED:
            segment.reveal()
    segment_discovery_state.sync(puzzle_id)


func get_segment_discovery_state(puzzle_id: int) -> SegmentDiscovery:
    var restored_state: Variant = ProgressManager.get_puzzle_state(puzzle_id)
    var segment_state: SegmentDiscovery = SegmentDiscovery.new()


    if typeof(restored_state) != TYPE_DICTIONARY:
        segment_state.prev_segment_state = 0
        segment_state.current_segment_state = 0
        return segment_state

    var segments: int = restored_state.get(SegmentedPuzzleKey.SEGMENTS, 0)
    segment_state.current_segment_state = segments

    var prev_puzzle_state: Variant = discovered_state[GSK.PUZZLE_STATES].get(puzzle_id, {})
    if not prev_puzzle_state:

        segment_state.prev_segment_state = 0
        return segment_state

    segment_state.prev_segment_state = prev_puzzle_state.get(SegmentedPuzzleKey.SEGMENTS, 0)

    return segment_state



func sync_puzzle_state(puzzle_id: int) -> void :
    var puzzle_state: Variant = ProgressManager.get_puzzle_state(puzzle_id)
    var is_null: bool = typeof(puzzle_state) == TYPE_NIL
    discovered_state[GSK.PUZZLE_STATES][puzzle_id] = puzzle_state if is_null else puzzle_state.duplicate(true)


func _clone_state() -> void :
    discovered_state = PersistenceManager.state.duplicate(true)


class SegmentDiscovery:

    var prev_segment_state: int


    var current_segment_state: int


    func is_equal() -> bool:
        return prev_segment_state == current_segment_state


    func diff(total_segments: int) -> Array[DiscoveryState]:
        var result: Array[DiscoveryState] = []

        for i in total_segments:
            var prev: int = FlagsUtils.flag_state_pos(prev_segment_state, i)
            var curr: int = FlagsUtils.flag_state_pos(current_segment_state, i)

            if prev == 0 and curr == 0:
                result.append(DiscoveryState.LOCKED)
                continue

            if prev == 1:
                result.append(DiscoveryState.DISCOVERED)
                continue

            if prev == 0:
                result.append(DiscoveryState.UNDISCOVERED)
                continue

        return result


    func sync(puzzle_id: int) -> void :
        prev_segment_state = current_segment_state
        DiscoveryManager.sync_puzzle_state(puzzle_id)
