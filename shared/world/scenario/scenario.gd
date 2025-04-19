extends Node2D
class_name Scenario

signal location_change_finished(new_location: Location)
signal initial_location_loaded(new_location: Location)


const STATE_LOCATION_KEY: PersistenceManager.GameStateKey = PersistenceManager.GameStateKey.LAST_LOCATIONS
const ANIM_LOADING: = "loading_curtain"
const PROP_GLOBAL_POS: = "global_position"
const PAN_DURATION: = 0.66
const ScenarioSelectorScene: = preload("res://shared/ui/scenario_select/scenario_select.tscn")
const ThinkingUI: Resource = preload("res://shared/ui/thinking_ui/thinking_ui.gd")

@export var scenario_meta: ScenarioMeta
@export var thinking_layer: CanvasLayer


var starting_location_meta: LocationMeta

var _worker: Thread
var _worker_running: bool
var _semaphore: Semaphore
var _mutex: Mutex
var _cached_locations: = {}
var _current_location: Node2D
var _queued_transition: Variant
var _layer_data_intro_music: Array[MusicPlayer.LayerData] = []
var _layer_data_music: Array[MusicPlayer.LayerData] = []
var _layer_data_ambience: Array[MusicPlayer.LayerData] = []
var _intro_music_played: bool = false
var _data_cleared: bool = false
var _exit_in_progress: bool = false


var _locations: Dictionary = {}
var _scene_root: Node


var initial_load: int = 0

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var location_container: Node = $Locations
@onready var camera: Camera2D = $Camera2D
@onready var dialog_manager: DialogManager = $ / root / DialogManager
@onready var in_game_menu: CanvasLayer = % InGameMenu
@onready var _music_escalated: bool = thinking_layer.is_music_escalated()
@onready var _music_escalation_level: int = thinking_layer.get_music_escalation_level()


func _enter_tree() -> void :
    ProgressManager.current_scenario_meta = scenario_meta
    ProgressManager.current_scenario = self
    ProgressManager.screen_change_called.connect(_on_progressmanager_screen_change)


func _ready() -> void :
    _scene_root = get_parent()
    DevTools.reset_now()
    DevTools.set_scene_root(_scene_root)

    var scenario_id: int = scenario_meta.id

    if (scenario_id == 0):
        push_error("A scenario id is not assigned.")

    ProgressManager.escalate_music_request.connect(_on_music_escalate_request)
    in_game_menu.scenario_exit_pressed.connect(_on_menu_scenario_exit_pressed)

    _init_ui()

    for location in scenario_meta.locations:

        _locations[location.location_id] = location

    _mutex = Mutex.new()
    _semaphore = Semaphore.new()
    _worker_running = true
    _worker = Thread.new()
    _worker.start(_resource_load_status_worker)

    var last_location_id: Variant = PersistenceManager.state.get(
        STATE_LOCATION_KEY, {}
    ).get(scenario_id)

    if not last_location_id is int:
        starting_location_meta = scenario_meta.locations[0]
    else:
        starting_location_meta = _locations[last_location_id]

    var starting_location_path: String = starting_location_meta.path
    var instance: Location = load(starting_location_path).instantiate()

    instance.ready.connect(
        _location_ready.bind(instance), 
        CONNECT_ONE_SHOT
    )

    instance.location_change_request.connect(_init_load_location)
    location_container.add_child(instance)
    initial_location_loaded.emit(instance)
    ProgressManager.add_location_visited(instance.location_meta.location_id)
    _cached_locations[starting_location_path] = instance
    _current_location = instance
    DialogManager.dialog_layer = get_node("DialogLayer")

    for i in scenario_meta.intro_music.size():
        var stream: AudioStream = scenario_meta.intro_music[i]
        _layer_data_intro_music.append(MusicPlayer.LayerData.create(stream))

    for i in scenario_meta.loop_music.size():
        var stream: AudioStream = scenario_meta.loop_music[i]
        _layer_data_music.append(MusicPlayer.LayerData.create(stream).set_is_oneshot(scenario_meta.oneshot_layer_ids.has(i)))

    for i in scenario_meta.ambience.size():
        var stream: AudioStream = scenario_meta.ambience[i]
        _layer_data_ambience.append(MusicPlayer.LayerData.create(stream).set_active_on_start(true))

    AudioManager.set_transposition(scenario_meta.sfx_transposition)
    _play_location_ambience()

    DevTools.report_load_finished()
    DevTools.set_scenario_mode(true)
    LoadingScreen.hide_screen()


func _unhandled_input(event: InputEvent) -> void :
    if Input.is_action_just_pressed(GamepadUtils.ACTION_MAIN_MENU):
        get_viewport().set_input_as_handled()
        in_game_menu.show()
        return

    if Input.is_action_just_pressed("ui_cancel"):
        if DialogManager.has_dialogs_open:
            return
        if not event is InputEventJoypadButton and not event is InputEventJoypadMotion:

            in_game_menu.show()
            get_viewport().set_input_as_handled()
        return


func hide_menu() -> void :
    if not in_game_menu:
        return
    in_game_menu.hide()


func clear_scenario_data() -> void :
    if _data_cleared:
        return
    _data_cleared = true

    DevTools.set_scenario_mode(false)
    DialogManager.close_all()
    DragAndDropManager.clean()
    ProgressManager.clear_scenario_data()
    NodeUtils.unfocus()


func get_current_location_id() -> int:
    if _current_location:
        return _current_location.location_meta.location_id
    else:
        return -1


func exit_pressed() -> void :
    ProgressManager.victory_sequence_playing = false
    get_viewport().set_input_as_handled()

    if _exit_in_progress:
        return
    _exit_in_progress = true



    clear_scenario_data()


    var intermission_id: int = -1
    var intermission_path: String = ""


    if scenario_meta.arc == null:

        if not ProgressManager.is_scenario_beaten(scenario_meta.id):
            ProgressManager.change_screen("res://shared/ui/hub_of_hubs/hub_of_hubs.tscn")
            return


        if not scenario_meta.id == 11 and not scenario_meta.id == 55:
            ProgressManager.change_screen("res://shared/ui/hub_of_hubs/hub_of_hubs.tscn")
            return

        match scenario_meta.id:
            11:
                intermission_id = 1
                intermission_path = "res://acts/full_game/intermisions/intro_intermission.tscn"
            55:
                intermission_id = 7
                intermission_path = "res://acts/full_game/intermisions/finale01_intermission.tscn"


        if intermission_id in ProgressManager.intermissions_shown:
            ProgressManager.change_screen("res://shared/ui/hub_of_hubs/hub_of_hubs.tscn")
            return


        ProgressManager.change_screen(intermission_path)
        return


    else:

        match scenario_meta.id:
            63:
                intermission_id = 62
                intermission_path = "res://acts/roys_dlc/intermissions/escape_intermission.tscn"
            64:
                intermission_id = 63
                intermission_path = "res://acts/roys_dlc/intermissions/page1_intermission.tscn"

        if intermission_id in ProgressManager.intermissions_shown:
            ProgressManager.change_screen(scenario_meta.arc)
            return


        if intermission_id != -1:
            ProgressManager.change_screen(intermission_path)
            return
        else:
            ProgressManager.change_screen(scenario_meta.arc)
            return


func connect_location_button(location_change_button: LocationButton) -> void :
    location_change_button.location_change_request.connect(_init_load_location)


func _init_load_location(location_id: int, transition: Location.LocationTransition, sound: AudioManager.TransitionSound = AudioManager.TransitionSound.DEFAULT) -> void :
    DevTools.reset_now()
    var path: String = _locations[location_id].path

    var existing_locations: Dictionary = PersistenceManager.state[STATE_LOCATION_KEY]
    var current_last_location: Variant = existing_locations.get(scenario_meta.id)
    if current_last_location != location_id:
        existing_locations[scenario_meta.id] = location_id
        PersistenceManager.mark_state_changed()

    if not _path_loaded(path):
        ResourceLoader.load_threaded_request(path, "", true)

    AudioManager.play_transition(sound)

    if transition == Location.LocationTransition.FADE:
        animation_player.animation_finished.connect(
            func(_anim_name: String) -> void : _load_location(path, transition), 
            CONNECT_ONE_SHOT, 
        )
        animation_player.play(ANIM_LOADING)
        return

    _load_location(path, transition)


func _load_location(path: String, transition: Location.LocationTransition) -> void :
    _mutex.lock()
    _queued_transition = [path, transition]
    _mutex.unlock()
    _semaphore.post()


func _perform_transition(node: Location, transition: Location.LocationTransition) -> void :
    var viewport_rect: Rect2 = get_viewport_rect()
    var viewport_width: = viewport_rect.size.x
    var viewport_height: = viewport_rect.size.y
    var node_id: = node.get_instance_id()
    var other_nodes: Array[Node] = location_container.get_children().filter(
        func(child: Node) -> bool: return child.get_instance_id() != node_id and child.get_instance_id() != _current_location.get_instance_id()
    )



    for location in other_nodes:
        if location.has_method("on_navigate_away"):
            location.on_navigate_away()
        location.hide()

    var extra_x_offset: int = 0
    var extra_y_offset: int = 0
    var current_location_meta: LocationMeta = _current_location.location_meta as LocationMeta
    if current_location_meta.background and _current_location.background_offset:
        extra_x_offset = abs(Constants.BACKGROUND_OFFSET.x) * 2
        extra_y_offset = abs(Constants.BACKGROUND_OFFSET.y) * 2

    match transition:
        Location.LocationTransition.FADE:


            _current_location.hide()

            node.global_position = camera.global_position
            animation_player.play_backwards(ANIM_LOADING)
        Location.LocationTransition.PAN_RIGHT:
            node.global_position.x = _current_location.global_position.x + viewport_width + extra_x_offset
            node.global_position.y = _current_location.global_position.y
            _pan_camera(node.global_position)
        Location.LocationTransition.PAN_LEFT:
            node.global_position.x = _current_location.global_position.x - viewport_width - extra_x_offset
            node.global_position.y = _current_location.global_position.y
            _pan_camera(node.global_position)
        Location.LocationTransition.PAN_DOWN:
            node.global_position.x = _current_location.global_position.x
            node.global_position.y = _current_location.global_position.y + viewport_height + extra_y_offset
            _pan_camera(node.global_position)
        Location.LocationTransition.PAN_UP:
            node.global_position.x = _current_location.global_position.x
            node.global_position.y = _current_location.global_position.y - viewport_height - extra_y_offset
            _pan_camera(node.global_position)

    node.show()
    _location_load_finalized(node)


func _location_load_finalized(node: Location) -> void :
    _current_location = node
    _play_location_ambience()

    node.on_navigate_to()
    node.focus_initial_node()
    DevTools.report_load_finished()
    location_change_finished.emit(node)
    ProgressManager.add_location_visited(node.location_meta.location_id)


func _play_location_ambience() -> void :
    var loc_meta: LocationMeta = _current_location.location_meta
    var music_layer_ids: Array[int] = loc_meta.music_layer_ids
    var group_amb: = MusicPlayer.PlayerGroup.AMBIENCE

    match loc_meta.audio_side_effect:
        LocationMeta.AudioSideEffect.NONE:
            MusicPlayer.restore_gain()
            MusicPlayer.disable_filter(MusicPlayer.FilterType.LOWPASS, MusicPlayer.BUS_MUSIC)
            MusicPlayer.disable_filter(MusicPlayer.FilterType.HIGHPASS, MusicPlayer.BUS_MUSIC)
        LocationMeta.AudioSideEffect.ACCENTED_MUSIC:
            MusicPlayer.accent()
        LocationMeta.AudioSideEffect.ACCENTED_AMBIENCE:
            MusicPlayer.accent(group_amb)
        LocationMeta.AudioSideEffect.MUSIC_MIDS_ONLY:
            MusicPlayer.enable_filter(MusicPlayer.FilterType.LOWPASS, MusicPlayer.BUS_MUSIC, 1000.0)
            MusicPlayer.enable_filter(MusicPlayer.FilterType.HIGHPASS, MusicPlayer.BUS_MUSIC, 200.0)

    if _layer_data_intro_music.size() and not _intro_music_played:
        MusicPlayer.crossfade(_layer_data_intro_music)

        for i in _layer_data_intro_music.size():
            MusicPlayer.fade_player(true, i)

        MusicPlayer.set_on_finished(_handle_intro_music_finished)
    elif _layer_data_music.size() and music_layer_ids.size():
        var fade_time: = MusicPlayer.TWEEN_DURATION_LAYER_FADE
        MusicPlayer.crossfade(_layer_data_music)

        if _music_escalated:
            if scenario_meta.stop_existing_music_on_escalation:
                fade_time = 5.0
                music_layer_ids = [scenario_meta.escalation_layer_ids[_music_escalation_level]]
            else:
                music_layer_ids.append_array(scenario_meta.escalation_layer_ids)

        for i in _layer_data_music.size():
            MusicPlayer.fade_player(music_layer_ids.has(i), i, MusicPlayer.PlayerGroup.MUSIC, false, fade_time)
    else:
        MusicPlayer.stop()

    if loc_meta.ambience_layers.size():
        var layer_data: Array[MusicPlayer.LayerData] = []
        for stream: AudioStream in loc_meta.ambience_layers:
            layer_data.append(MusicPlayer.LayerData.create(stream).set_active_on_start(true))
        MusicPlayer.crossfade(layer_data, group_amb)
    elif _layer_data_ambience.size():
        MusicPlayer.crossfade(_layer_data_ambience, group_amb)
    else:
        MusicPlayer.stop(group_amb)


func _handle_intro_music_finished() -> void :
    _intro_music_played = true
    _play_location_ambience()


func _path_loaded(path: String) -> bool:
    return _cached_locations.has(path)


func _location_ready(instance: Location) -> void :
    animation_player.play_backwards(ANIM_LOADING)
    instance.focus_initial_node()


func _pan_camera(final_position: Vector2) -> void :
    var tween: = create_tween()
    tween.bind_node(self)
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_QUART)

    tween.tween_property(
        camera, 
        PROP_GLOBAL_POS, 
        final_position, 
        PAN_DURATION
    )


func _resource_load_status_worker() -> void :
    while true:

        _semaphore.wait()

        _mutex.lock()
        var should_exit: = not _worker_running
        _mutex.unlock()

        if should_exit:
            break

        if not _queued_transition:
            continue

        _mutex.lock()
        var path: String = _queued_transition[0]
        var transition: Location.LocationTransition = _queued_transition[1]
        var is_path_loaded: = _path_loaded(path)
        _mutex.unlock()

        if not is_path_loaded:
            call_deferred(
                "_init_new_location", 
                ResourceLoader.load_threaded_get(path), 
                path, 
                transition
            )
        else:
            _mutex.lock()
            var node: Location = _cached_locations.get(path)
            _mutex.unlock()
            call_deferred("_perform_transition", node, transition)


func _init_new_location(resource: PackedScene, path: String, transition: Location.LocationTransition) -> void :
    var node: Location = resource.instantiate()
    node.location_change_request.connect(_init_load_location)

    _mutex.lock()
    _cached_locations[path] = node
    _queued_transition = null
    _mutex.unlock()

    location_container.add_child(node)
    _perform_transition(node, transition)


func _init_ui() -> void :
    if not thinking_layer:
        return

    var thinking_ui: Node = ThinkingUI.new(self)

    thinking_ui.bootstrap()


func _on_music_escalate_request(escalation_level: int = 0) -> void :
    _music_escalated = true
    _music_escalation_level = escalation_level
    _play_location_ambience()


func _exit_tree() -> void :

    clear_scenario_data()
    AudioManager.set_transposition(AudioManager.Transposition.DEFAULT)
    MusicPlayer.restore_gain()
    MusicPlayer.disable_filter(MusicPlayer.FilterType.LOWPASS, MusicPlayer.BUS_MUSIC)
    MusicPlayer.disable_filter(MusicPlayer.FilterType.HIGHPASS, MusicPlayer.BUS_MUSIC)

    _mutex.lock()
    _worker_running = false
    _mutex.unlock()

    _semaphore.post()
    _worker.wait_to_finish()


func _on_progressmanager_screen_change() -> void :
    clear_scenario_data()


func _on_menu_scenario_exit_pressed() -> void :
    exit_pressed()
