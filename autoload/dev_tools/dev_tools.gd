extends CanvasLayer

signal devtools_toggled(is_visible: bool)

const TOGGLE_ACTION_NAME: = "ui_debug_dev"
const FSTRING_FPS: = "FPS: %d"
const FSTRING_RAM: = "Static RAM: %d MB"
const FSTRING_VRAM: = "Video RAM: %d MB"
const FSTRING_LOAD_TIME: = "Load time: %fs"
const FSTRING_DIAG_TIME: = "Dialog time: %fs"
const FSTRING_FOCUS: = "Focus: %s, parent: %s"
const MBYTE = 1048576

@onready var now: int
@onready var diagnostics_container: Container = % DiagnosticsContainer
@onready var phrase_data: Panel = % PhraseData
@onready var phrase_data_label: Label = % PhraseDataLabel
@onready var fps_label: = % FPSLabel
@onready var static_mem_label: = % RAMLabel
@onready var vram_mem_label: = % VRAMLabel
@onready var load_label: = % LoadLabel
@onready var diag_time_label: = % DialogTimerLabel
@onready var focus_target_label: = % FocusTargetLabel
@onready var top_bar: = % TopBar
@onready var scenario_progress_container: = % ScenarioProgressContainer
@onready var main_containers: Array[Control] = [
    diagnostics_container, 
    phrase_data, 
    top_bar, 
    scenario_progress_container, 
]
@onready var scenario_containers: Array[CanvasItem] = [
    phrase_data, 
    scenario_progress_container, 
]

var active: bool = true
var overlay_visible: bool = false
var _scenario_mode: bool = false
var _phrase_type_to_label: Dictionary = {}
var _scene_switcher: Node
var _scene_root: Node
var _dialog_timer: int


func _ready() -> void :
    if Engine.is_editor_hint():
        _deactivate()
        return
    if not OS.is_debug_build():
        _deactivate()
        return

    _scene_switcher = (load("res://autoload/dev_tools/scene_changer.tscn") as PackedScene).instantiate()
    add_child(_scene_switcher)

    _set_container_visibility(false)

    for entry: String in GIItem.PhraseType.keys():
        _phrase_type_to_label[GIItem.PhraseType.get(entry)] = entry

    ProgressManager.items_unlocked.connect(_on_items_unlocked)

    get_viewport().gui_focus_changed.connect(_on_gui_focus_changed)
    _set_focus_owner_label(get_viewport().gui_get_focus_owner())

    var clear_achievements_button: Button = % ClearAchievementsButton
    clear_achievements_button.pressed.connect(_on_clear_achievements_button_pressed.bind(clear_achievements_button))
    if not Platform.is_platform_loaded():
        clear_achievements_button.hide()


func _unhandled_input(_event: InputEvent) -> void :
    if not active:
        return

    if Input.is_action_just_pressed("hide_ui_for_video_capturing"):

        var elements_to_hide: Array = get_tree().get_nodes_in_group("hide_for_capturing")
        for element: Control in elements_to_hide:
            element.visible = !element.visible

    if Input.is_action_just_pressed("ui_debug_scene_switcher"):
        _scene_switcher.visible = true

    if Input.is_action_just_pressed("reload_current_screen"):
        get_tree().reload_current_scene()

    if Input.is_action_just_pressed("cycle_language_forward"):
        cycle_language(true)

    if Input.is_action_just_pressed("cycle_language_backward"):
        cycle_language(false)

    if not Input.is_action_just_pressed(TOGGLE_ACTION_NAME):
        return

    _set_container_visibility( not overlay_visible)
    get_viewport().set_input_as_handled()


func _process(_delta: float) -> void :
    fps_label.text = FSTRING_FPS % Performance.get_monitor(Performance.Monitor.TIME_FPS)
    static_mem_label.text = FSTRING_RAM % (Performance.get_monitor(Performance.Monitor.MEMORY_STATIC) / MBYTE)
    vram_mem_label.text = FSTRING_VRAM % (Performance.get_monitor(Performance.Monitor.RENDER_VIDEO_MEM_USED) / MBYTE)


func reset_now() -> void :
    if not active:
        return
    now = _get_now()


func reset_dialog_timer() -> void :
    if not active:
        return
    _dialog_timer = _get_now()


func report_load_finished() -> void :
    if not active:
        return
    var delta_ms: int = _get_now() - now
    load_label.text = FSTRING_LOAD_TIME % (delta_ms / 1000.0)
    reset_now()


func report_dialog_load_finished(_hotspot_name: String) -> void :
    if not active:
        return
    var delta_ms: int = _get_now() - _dialog_timer
    var load_time: String = FSTRING_DIAG_TIME % (delta_ms / 1000.0)
    diag_time_label.text = load_time


func set_scene_root(new_root: Node) -> void :
    if not active:
        return

    _scene_root = new_root


func set_scenario_mode(is_on: bool) -> void :
    _scenario_mode = is_on

    if not active:
        return

    if is_on:
        _format_inventory_groups()
        if overlay_visible:
            for c in scenario_containers:
                c.show()
    else:
        phrase_data_label.text = ""
        for c in scenario_containers:
            c.hide()

    _update_topbar_position()


func _get_now() -> int:
    return Time.get_ticks_msec()


func _deactivate() -> void :
    active = false
    overlay_visible = false
    set_process(false)
    for c in main_containers:
        c.queue_free()
    main_containers = []


func _set_container_visibility(make_visible: bool) -> void :
    overlay_visible = make_visible
    if make_visible:
        for c in main_containers:
            if c in scenario_containers and not _scenario_mode:
                continue
            c.show()
    else:
        for c in main_containers:
            c.hide()

    _update_topbar_position()
    devtools_toggled.emit(make_visible)


func _update_topbar_position() -> void :
    var p: Control.LayoutPreset = Control.PRESET_CENTER_TOP
    top_bar.set_anchors_and_offsets_preset(p)
    top_bar.position.y = 16
    scenario_progress_container.set_anchors_and_offsets_preset(p)


func _on_items_unlocked(_item_ids: Array[int]) -> void :
    _format_inventory_groups()


func _format_inventory_groups() -> void :
    if not active:
        return

    if not _scenario_mode:
        return

    if not ProgressManager.current_scenario_id:
        return

    var groups: Dictionary = {}
    var inventory: Array[int] = ProgressManager.get_scenario_inventory()
    for item_id in inventory:
        if not item_id:
            continue
        var item: GIItem = Database.get_item_by_id(item_id)
        var type: GIItem.PhraseType = item.meta.type
        groups[type] = groups.get(type, 0) + 1

    var final_string: String = "Inventory info:\n"
    if not len(groups.keys()):
        final_string += "EMPTY"
    else:
        for k: GIItem.PhraseType in groups:
            final_string += "%s: %d\n" % [_phrase_type_to_label[k], groups[k]]
    phrase_data_label.text = final_string


func _set_focus_owner_label(focus_owner: Control) -> void :
    if not focus_owner:
        return

    var parent: StringName = focus_owner.get_parent().name
    if focus_owner is Control:
        focus_target_label.text = FSTRING_FOCUS % [focus_owner.name, parent]
    if focus_owner is Button:
        focus_target_label.text = FSTRING_FOCUS % [focus_owner.name + " " + focus_owner.text, parent]


func _on_gui_focus_changed(new_owner: Control) -> void :
    _set_focus_owner_label(new_owner)


func _on_reset_scenario_state_button_pressed() -> void :
    if not active:
        return

    if not _scenario_mode:
        return

    if not ProgressManager.current_scenario_id:
        return

    ProgressManager.request_current_scenario_reset()


func _on_clear_achievements_button_pressed(trigger: Button) -> void :
    if not active:
        return

    if not Platform.is_platform_loaded():
        return

    trigger.disabled = true
    create_tween().tween_callback(func() -> void : trigger.disabled = false).set_delay(1)

    Platform.clear_achievements()


func cycle_language(forward: bool) -> void :
    const LABEL_MAP: = {
        0: "en", 
        1: "de", 
        2: "es", 
        3: "es_MX", 
        4: "fr", 
        5: "it", 
        6: "pl", 
        7: "pt_BR", 
        8: "tr", 
        9: "ja", 
        10: "zh_TW", 
        11: "ko", 
    }
    var current_lang_id: int = LABEL_MAP.find_key(TranslationServer.get_locale())
    var next_id: int
    if forward:
        next_id = current_lang_id + 1
        if next_id == LABEL_MAP.size():
            next_id = 0
    elif not forward:
        next_id = current_lang_id - 1
        if next_id == -1:
            next_id = LABEL_MAP.size() - 1

    var locale: String = LABEL_MAP[next_id]
    var current_locale: = TranslationServer.get_locale()
    const SETTINGS_SECTION = SettingsManager.Keys.SECTION_GENERAL
    const SETTINGS_KEY = SettingsManager.Keys.SETTING_LANGUAGE
    if current_locale != locale:
        TranslationServer.set_locale(locale)
        SettingsManager.set_setting(
            SETTINGS_SECTION, 
            SETTINGS_KEY, 
            locale
        )
