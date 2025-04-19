@tool
extends Control

const ANIM_LOADING: = "rotate_loading"
const ThinkingUI: Resource = preload("res://shared/ui/thinking_ui/thinking_ui.gd")

@export var thinking_layer: CanvasLayer
@export var arc_meta: ArcMeta

var _loading: bool = false

@onready var background_texturerect: TextureRect = % Background


func _init() -> void :
    if not Engine.is_editor_hint():
        DevTools.reset_now()


func _enter_tree() -> void :
    if arc_meta and not Engine.is_editor_hint():
        ProgressManager.current_arc_id = arc_meta.id


func _ready() -> void :
    if Engine.is_editor_hint():
        return

    DevTools.set_scene_root(get_parent())
    AudioManager.stop_all(1.0)

    _init_ui()
    if arc_meta:
        ProgressManager.current_chapter_meta = arc_meta
        MusicPlayer.play_bg_audio(arc_meta.music_layers, arc_meta.ambience_layers)
        MusicPlayer.accent(MusicPlayer.PlayerGroup.AMBIENCE)
        MusicPlayer.enable_filter(MusicPlayer.FilterType.LOWPASS, MusicPlayer.BUS_MUSIC, 1000)
        MusicPlayer.enable_filter(MusicPlayer.FilterType.HIGHPASS, MusicPlayer.BUS_MUSIC, 300)

    for c in get_children():
        if not c is HubScenario:
            continue

        var hub_scenario: = c as HubScenario
        hub_scenario.scenario_load_requested.connect(_on_scenario_load_requested)

    DevTools.report_load_finished()
    LoadingScreen.hide_screen()


func _exit_tree() -> void :
    if not Engine.is_editor_hint():
        MusicPlayer.disable_filter(MusicPlayer.FilterType.LOWPASS)
        MusicPlayer.disable_filter(MusicPlayer.FilterType.HIGHPASS)
        DragAndDropManager.clean()
        ProgressManager.current_chapter_meta = null


func _on_scenario_load_requested(scenario_meta: ScenarioMeta) -> void :
    if _loading:
        return
    _loading = true

    for c in get_children():
        if not c is HubScenario:
            continue
        (c as HubScenario).loading = true

    if not Engine.is_editor_hint():
        ProgressManager.change_screen(scenario_meta)


func _load_scenario(path: String) -> void :
    ResourceLoader.load_threaded_request(path)
    var packed_scene: PackedScene = ResourceLoader.load_threaded_get(path)
    call_thread_safe("_switch_to_scenario", packed_scene)


func _switch_to_scenario(packed_scene: PackedScene) -> void :
    var scenario: = packed_scene.instantiate()
    get_tree().root.add_child(scenario)


func _init_ui() -> void :
    if not thinking_layer:
        return
    var thinking_ui: Node = ThinkingUI.new(self)
    thinking_ui.bootstrap()
