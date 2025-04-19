extends Button

var _scenario: Node
var _location_queue: Array[int] = []

func _on_pressed() -> void :
    disabled = true

    if not ProgressManager.current_scenario:
        return

    _scenario = ProgressManager.current_scenario

    for loc_meta: LocationMeta in (_scenario.scenario_meta as ScenarioMeta).locations:
        _location_queue.append(loc_meta.location_id)

    parse_locations()


func _handle_hotspot(hotspot: Hotspot) -> void :
    hotspot._init_dialog_placeholder()
    hotspot.handle_click(true)


func parse_locations() -> void :
    if len(_location_queue) == 0:
        _finalize_collect()
        return

    var location_id: int = _location_queue.pop_front()
    if _scenario._current_location.location_meta.location_id != location_id:
        _scenario.location_change_finished.connect(
            func(new_location: Location) -> void : call_deferred("parse_hotspots", new_location), 
            CONNECT_ONE_SHOT, 
        )
        _scenario._init_load_location(location_id, Location.LocationTransition.FADE)
        return

    parse_hotspots(_scenario._current_location as Location)


func parse_hotspots(location: Location) -> void :

    for hotspot: Hotspot in location.hotspot_cache:

        _handle_hotspot(hotspot)
        for dep: Hotspot in hotspot._dependencies:
            _handle_hotspot(dep)
    parse_locations()


func _finalize_collect() -> void :
    _location_queue = []
    _scenario = null
    disabled = false
