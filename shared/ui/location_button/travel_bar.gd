extends Control

@export var travel_button_list: Array[TextureButton]

@export var immutable_focus_neighbors: bool = true
var scenario: Scenario

var _last_focused_idx: int = 0


func _enter_tree() -> void :
    DialogManager.set_time_travel_bar(self)


func _ready() -> void :
    scenario = ProgressManager.current_scenario
    scenario.location_change_finished.connect(update_button_state)
    scenario.initial_location_loaded.connect(update_button_state)

    _focus_setup()


func update_button_state(location: Location) -> void :
    for button: LocationButton in travel_button_list:
        if location.location_meta.location_id == button.target_location_meta.location_id:
            button.disabled = true
        else:
            button.disabled = false



func request_focus() -> void :
    var last_focused: LocationButton = travel_button_list[_last_focused_idx]

    if last_focused.disabled:
        _last_focused_idx = 0
        last_focused = travel_button_list[_last_focused_idx]

    last_focused.call_deferred(&"grab_focus")


func _update_bottom_focus_neighbor() -> void :
    if immutable_focus_neighbors:
        return

    if not DialogManager.get_last_exploration_control():
        return

    var path: NodePath = DialogManager.get_last_exploration_control().get_path()
    for button: LocationButton in travel_button_list:
        button.focus_neighbor_bottom = path


func _on_last_exploration_control_changed() -> void :
    _update_bottom_focus_neighbor()


func _focus_setup() -> void :
    for i: int in len(travel_button_list):
        travel_button_list[i].focus_entered.connect(func() -> void : _last_focused_idx = i)
    _update_bottom_focus_neighbor()

    DialogManager.last_exploration_control_changed.connect(_on_last_exploration_control_changed.unbind(1))
    focus_entered.connect(request_focus)
