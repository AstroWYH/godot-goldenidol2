extends Node

signal hotspot_visited(hotspot_id: String)

enum HotspotState{
    VISITED = 0, 
    EXPLORED = 1, 
}

const STATE_KEY = PersistenceManager.GameStateKey.VISITED_HOTSPOTS


func _ready() -> void :
    ProgressManager.scenario_reset.connect(_on_scenario_reset)


func is_hotspot_explored(hotspot_id: String) -> bool:
    var state: Dictionary = _get_current_scenario_state()
    return state.get(hotspot_id, -1) == HotspotState.EXPLORED


func mark_hotspot_visited(hotspot_id: String) -> void :
    var state: Dictionary = _get_current_scenario_state()
    if state.has(hotspot_id):

        return

    state[hotspot_id] = HotspotState.VISITED
    _set_current_scenario_state(state)
    hotspot_visited.emit(hotspot_id)


func mark_hotspot_explored(hotspot_id: String) -> void :
    var state: Dictionary = _get_current_scenario_state()
    if state.get(hotspot_id, -1) == HotspotState.EXPLORED:
        return

    state[hotspot_id] = HotspotState.EXPLORED
    _set_current_scenario_state(state)



func get_visited_hotspot_count() -> int:
    return _get_current_scenario_state().size()


func _get_current_scenario_id() -> int:
    return ProgressManager.current_scenario_id


func _get_current_scenario_state() -> Dictionary:
    return PersistenceManager.state[STATE_KEY].get(
        _get_current_scenario_id(), 
        {}, 
    )


func _set_current_scenario_state(new_state: Dictionary) -> void :
    PersistenceManager.state[STATE_KEY][_get_current_scenario_id()] = new_state
    PersistenceManager.mark_state_changed()


func _on_scenario_reset(_scenario_id: int) -> void :
    _set_current_scenario_state({})



static func get_hotspot(node: Control) -> Control:
    var target: Hotspot

    if not node:
        @warning_ignore("unassigned_variable")
        return target

    if node is Hotspot:
        target = node
    elif node.get_child_count():

        var first_child: = node.get_child(0)
        if first_child is Hotspot:
            target = first_child

    return target
