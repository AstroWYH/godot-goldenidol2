extends Window

var scenario_paths: Array[String] = [


    "res://acts/full_game/introductory_arc/asylum/asylum_scenario_meta.tres", 
    "res://acts/full_game/introductory_arc/bridge/bridge_scenario_meta.tres", 
    "res://acts/full_game/introductory_arc/construction_yard/construction_yard_meta.tres", 
    "res://acts/full_game/introductory_arc/conference/conference_scenario_meta.tres", 


    "res://acts/full_game/colecting_parts_arc/retreat/retreat_scenario_meta.tres", 
    "res://acts/full_game/colecting_parts_arc/jail/prison_scenario_meta.tres", 
    "res://acts/full_game/colecting_parts_arc/drivein/drive_in_scenario_meta.tres", 
    "res://acts/full_game/colecting_parts_arc/auction/auction_scenario_meta.tres", 


    "res://acts/full_game/reconstruction_arc/burning_man/burning_man_scenario_meta.tres", 
    "res://acts/full_game/reconstruction_arc/banning/banning_scenario_meta.tres", 
    "res://acts/full_game/reconstruction_arc/eviction/eviction_scenario_meta.tres", 


    "res://acts/full_game/research_arc/aviary/aviary_scenario_meta.tres", 
    "res://acts/full_game/research_arc/talent_show/talent_show_scenario_meta.tres", 
    "res://acts/full_game/research_arc/dance/dance_scenario_meta.tres", 
    "res://acts/full_game/research_arc/complex/complex_scenario_meta.tres", 


    "res://acts/full_game/conclusion_arc/beach/beach_scenario.tres", 
    "res://acts/full_game/conclusion_arc/boardroom/boardroom_scenario_meta.tres", 
    "res://acts/full_game/conclusion_arc/museum/museum_scenario_meta.tres", 
    "res://acts/full_game/conclusion_arc/dark_experiments/dark_experiments_scenario.tres", 
    "res://acts/full_game/conclusion_arc/finale/finale_scenario.tres", 


    "res://acts/roys_dlc/1_alleyway/alleyway_scenario_meta.tres", 
    "res://acts/roys_dlc/2_dog_track/dog_track_scenario.tres", 
    "res://acts/roys_dlc/3_workshop/workshop_scenario_meta.tres", 
    "res://acts/roys_dlc/4_roy_finale/roy_finale_scenario.tres", 


    "res://acts/legacy_dlc/palace/palace_scenario_meta.tres", 
    "res://acts/legacy_dlc/sanctuary/sanctuary_scenario_meta.tres", 
    "res://acts/legacy_dlc/compound/compound_scenario_meta.tres", 
    "res://acts/legacy_dlc/cave/cave_scenario_meta.tres", 
    "res://acts/legacy_dlc/bunker/bunker_scenario_meta.tres", 


    "res://acts/inquisition_dlc/1_orchard/orchard_scenario.tres", 
    "res://acts/inquisition_dlc/2_court/court_scenarios.tres", 


    "res://acts/expedition_dlc/pub/pub_scenario_meta.tres", 
    "res://acts/expedition_dlc/ship/ship_scenario.tres", 
]
var arc_paths: Array[String] = [

    "res://acts/full_game/introductory_arc/introductory_arc_meta.tres", 
    "res://acts/full_game/colecting_parts_arc/hub/past_arc_meta.tres", 
    "res://acts/full_game/reconstruction_arc/hub/machine_arc_hub_meta.tres", 
    "res://acts/full_game/research_arc/hub/trials_arc_meta.tres", 
    "res://acts/full_game/conclusion_arc/hub/conclusion_arc_meta.tres", 


    "res://acts/roys_dlc/hub/roys_dlc_meta.tres", 
    "res://acts/legacy_dlc/hub/legacy_dlc_hub_meta.tres", 
]

@onready var main_container: Container = % MainContainer
@onready var arcs_container: Container = % Arcs
@onready var scenarios_container: Container = % Scenarios
@onready var scenarios_container_2: Container = % Scenarios2

func _ready() -> void :
    hide()
    var scenario_count: int = 0
    for path: String in scenario_paths:
        if not ResourceLoader.exists(path):

            continue

        var meta: ScenarioMeta = load(path)
        if not ResourceLoader.exists(meta.path):

            continue

        if scenario_count < 20:
            scenarios_container.add_child(_create_button(meta.name, meta))
        else:
            scenarios_container_2.add_child(_create_button(meta.name, meta))
        scenario_count += 1


    if scenario_count < 20:
        scenarios_container_2.hide()


    for path: String in arc_paths:
        if not ResourceLoader.exists(path):
            continue
        var meta: ArcMeta = load(path)
        if not ResourceLoader.exists(meta.hub_scene_path):
            continue
        arcs_container.add_child(_create_button(meta.name, meta))

    call_deferred("update_size")


func _unhandled_input(_event: InputEvent) -> void :
    if Input.is_action_just_pressed("ui_debug_scene_switcher"):
        visible = false
    get_viewport().set_input_as_handled()


func _create_button(label: String, meta: Variant) -> Button:
    var button: Button = Button.new()
    button.text = label
    button.pressed.connect(
        func() -> void : change_scene(meta)
    )
    return button


func change_scene(meta: Variant) -> void :
    hide()
    ProgressManager.change_screen(meta)









func update_size() -> void :
    self.size = main_container.size


func _on_close_requested() -> void :
    hide()
