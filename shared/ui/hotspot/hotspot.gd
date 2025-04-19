@icon("res://shared/ui/hotspot/assets/hotspot_selected.png")
class_name Hotspot
extends Control







signal clicked
signal location_change_request(
    new_location_id: int, 
    transition: Location.LocationTransition, 
    sound: AudioManager.TransitionSound
)
signal explored
signal unlocked
signal _dialog_shown

enum HotspotType{
    DEFAULT, 
    EXPLORED, 
    LOCATION
}

const ANIM_DEFAULT: = "default"
const ANIM_LOCATION: = "location"
const ANIM_EXPLORED: = "explored"
const STATE_KEY: int = PersistenceManager.GameStateKey.VISITED_HOTSPOTS
const DialogScene: = preload("res://shared/ui/dialog/dialog.tscn")
const HIGHLIGHTER_SETTING: String = SettingsManager.Keys.SETTING_VISIBLE_HIGHLIGHTERS
const HIGHLIGHTER_SECTION: String = SettingsManager.Keys.SECTION_GENERAL


@export var hotspot_id: String:
    set = _set_hotspot_id
@export var hotspot_type: HotspotType:
    set = _set_hotspot_type
@export var highlight_point_hidden: bool:
    set = _set_highlight_point_hidden
@export var hover_cursor: CursorService.CursorType = CursorService.CursorType.ACTIVE

@export_group("Dialog")
@export_multiline var text: String



@export var hide_content_node_on_init: bool = true

@export_group("Progression")
@export var unlocked_character_ref_id: int
@export var unlocked_item_ref_id: int
@export var extra_items_unlocked: Array[PhraseGridItem] = []
@export var extra_hypothetical_items_unlocked: Array[PhraseGridItem] = []
@export var unlocked_puzzles: Array[PuzzleMeta] = []
@export var unlocked_puzzle_segments: Array[PuzzleSegmentUnlock] = []

@export_group("Location")
@export var target_location_meta: LocationMeta
@export var transition: Location.LocationTransition
@export var transition_sound: AudioManager.TransitionSound = AudioManager.TransitionSound.NONE

@export_group("Lockable state")
@export var locked: bool = false
@export var required_puzzles: Array[PuzzleMeta] = []

var hypothetical_item_ids: Array[int] = []
var _dialog: Dialog = null
var _dialog_content_node: CanvasItem
var _dependencies: Array[Hotspot] = []
var _dependencies_visited: int = 0
var _placeholder: InstancePlaceholder
var _clicked: bool = false
var _unlock_history: UnlockHistory
var _dialog_shown_emitted: bool = false
var _is_click_emulated: bool = false

@onready var hotspot_sprite: AnimatedSprite2D = % Highlighter
@onready var focus_indicator: AnimatedSprite2D = % FocusIndicator


func _ready() -> void :
    set_process(false)

    if not hotspot_id:
        push_error("assign an id to the hotspot $%s!" % get_path())
    _set_hotspot_type(hotspot_type)
    _set_hotspot_id(hotspot_id)

    focus_indicator.visible = false
    focus_entered.connect(_on_control_focus_changed.bind(true))
    focus_exited.connect(_on_control_focus_changed.bind(false))

    NodeUtils.greedy_focus(self)

    _set_highlight_point_hidden( not SettingsManager.get_setting(HIGHLIGHTER_SECTION, HIGHLIGHTER_SETTING, true) as bool)
    SettingsManager.setting_changed.connect(_on_settingsmanager_setting_changed)

    for child in get_children():
        if child is Panel or child is PanelContainer:




            _init_dialog(child as Control)
        if child is InstancePlaceholder:

            _placeholder = child

    DialogManager.add_hotspot(self)
    ProgressManager.scenario_reset.connect(_on_scenario_reset)

    $Indicators / FocusGrabber.mouse_entered.connect(_on_focusgrabber_mouse_entered)

    if locked and required_puzzles.size() > 0:
        if _check_if_unlocked():
            unlock_spot()
        else:
            ProgressManager.puzzle_solved.connect(_on_puzzle_solved)
            visible = false


    if ProgressManager.current_scenario_meta and ProgressManager.current_scenario_meta.id == 55:
        _setup_finale_timetravelbar_focus()


func _process(_delta: float) -> void :

    if ResourceLoader.load_threaded_get_status(_placeholder.get_instance_path()) == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED:
        set_process(false)
        show_dialog(_is_click_emulated)


func _on_gui_input(event: InputEvent) -> void :
    if event is InputEventMouseMotion:


        CursorService.set_cursor(hover_cursor)

    if not event is InputEventMouseButton:
        return

    if (event as InputEventMouseButton).button_index != MOUSE_BUTTON_LEFT:
        return

    if (event as InputEventMouseButton).pressed:
        return

    handle_click()


func _unhandled_input(event: InputEvent) -> void :
    if event.is_action_pressed("ui_accept") and has_focus():
        handle_click()
        return


func add_dependent_hotspot(hotspot: Hotspot) -> void :
    if hotspot in _dependencies:
        return

    if HotspotManager.is_hotspot_explored(hotspot.hotspot_id):
        _dependencies_visited += 1
    else:
        hotspot.explored.connect(
            _on_dependency_explored, 
            CONNECT_ONE_SHOT, 
        )

    _dependencies.append(hotspot)


func hide_indicator() -> void :
    hotspot_sprite.hide()
    focus_indicator.hide()


func show_indicator() -> void :
    if highlight_point_hidden and not target_location_meta:


        return

    hotspot_sprite.show()
    if get_viewport().gui_get_focus_owner() == self:
        focus_indicator.show()


func show_dependencies() -> void :
    for hs in _dependencies:
        hs.show_indicator()
        hs.show_dependencies()


func _on_dependency_explored() -> void :
    _dependencies_visited += 1
    if _dependencies_visited == _dependencies.size():
        _handle_explored()


func _on_control_focus_changed(focus_gained: bool) -> void :
    if (focus_gained):
        focus_indicator.show()
        DialogManager.set_last_exploration_control(self)
        return

    focus_indicator.hide()


func _set_hotspot_type(value: HotspotType) -> void :
    hotspot_type = value

    if not hotspot_sprite:
        return

    match value:
        HotspotType.DEFAULT:
            hotspot_sprite.play(ANIM_DEFAULT)
        HotspotType.EXPLORED:
            if not target_location_meta:
                hotspot_sprite.play(ANIM_EXPLORED)
            else:
                hotspot_sprite.play(ANIM_LOCATION)
        HotspotType.LOCATION:
            hotspot_sprite.play(ANIM_LOCATION)


func _set_highlight_point_hidden(value: bool) -> void :
    highlight_point_hidden = value

    if hotspot_sprite:
        if not highlight_point_hidden:
            hotspot_sprite.show()
            focus_mode = FOCUS_ALL
            if not DialogManager.has_last_exploration_control():
                DialogManager.set_last_exploration_control(self)

        elif not target_location_meta:

            hotspot_sprite.hide()
            focus_indicator.hide()

            focus_mode = FOCUS_NONE

            if get_viewport().gui_get_focus_owner() == self:
                release_focus()


func _set_hotspot_id(v: String) -> void :
    hotspot_id = v

    if not v:
        return

    if not PersistenceManager.state.has(STATE_KEY):

        return


    if HotspotManager.is_hotspot_explored(hotspot_id):
        hotspot_type = HotspotType.EXPLORED


func handle_click(emulated: bool = false) -> void :
    var dialog_stack_entry: DialogManager.DialogStackEntry = DialogManager.get_top()

    _is_click_emulated = emulated
    _dialog_shown_emitted = false

    if dialog_stack_entry and dialog_stack_entry.trigger == self:

        return

    DevTools.reset_dialog_timer()
    clicked.emit()

    process_awards(emulated, not _clicked)


    if not _clicked:
        _clicked = true
        if not target_location_meta:
            HotspotManager.mark_hotspot_visited(hotspot_id)


    if target_location_meta:
        if not emulated:
            location_change_request.emit(
                target_location_meta.location_id, transition, transition_sound
            )
        return

    if _placeholder:
        if not is_processing():
            set_process(true)
            ResourceLoader.load_threaded_request(_placeholder.get_instance_path(), "", true)

    else:
        show_dialog(emulated)


    if len(text) and not emulated:
        var delay: float = 0.2 if _dialog else 0.0
        DialogManager.spawn_text_dialog(text, global_position, self, delay)





func show_dialog(emulated: bool) -> void :


    _init_dialog_placeholder()


    if _dialog and not emulated:
        _dialog.starting_position = global_position
        _dialog_content_node.global_position = global_position
        _dialog.show_dialog(self)
        AudioManager.play(AudioManager.Sound.CLOSEUP_OPEN, SoundParams.new().with_pitch_range(Vector2(-0.1, 0.1)))

    _dialog_shown.emit()
    _dialog_shown_emitted = true
    DevTools.report_dialog_load_finished(name)

    check_if_exhausted()


func process_awards(emulated: bool, give_awards: bool) -> void :
    var is_character_discovered: bool = false
    var new_items: Array[int] = []

    is_character_discovered = unlocked_character_ref_id > 0 and not ProgressManager.is_character_discovered(unlocked_character_ref_id)

    if give_awards:

        if unlocked_item_ref_id > 0:
            new_items.append(unlocked_item_ref_id)


        if extra_items_unlocked:
            for phrase_grid_item in extra_items_unlocked:
                new_items.append(phrase_grid_item.linked_item_ref_id)


        hypothetical_item_ids.clear()
        if extra_hypothetical_items_unlocked:
            for phrase_grid_item in extra_hypothetical_items_unlocked:
                new_items.append(phrase_grid_item.linked_item_ref_id)
                hypothetical_item_ids.append(phrase_grid_item.linked_item_ref_id)

        _unlock_history = UnlockHistory.new()
        _unlock_history.item_ids = new_items
        _unlock_history.puzzles = unlocked_puzzles
        _unlock_history.character_id = unlocked_character_ref_id
        _unlock_history.hypothetical_item_ids = hypothetical_item_ids

    var unlocked_items: Array[int] = []
    var puzzles: Array[PuzzleMeta] = []

    if give_awards:
        if is_character_discovered:
            ProgressManager.discover_character(unlocked_character_ref_id)

        if len(new_items):
            unlocked_items = ProgressManager.unlock_items(new_items)

        if len(unlocked_puzzles):
            puzzles = ProgressManager.unlock_puzzles(unlocked_puzzles)

        if len(unlocked_puzzle_segments):
            for seg_unlock: PuzzleSegmentUnlock in unlocked_puzzle_segments:
                ProgressManager.unlock_puzzle_segments(
                    seg_unlock.puzzle_meta.puzzle_id, 
                    seg_unlock.segment_indices, 
                )

    if emulated:
        return

    var show_unlock_summaries: Callable = func() -> void :
        _unlock_history.show_ghost_summary()


        var passed_items_for_summary: Array[int] = []
        if len(unlocked_items):
            passed_items_for_summary = new_items

        ProgressManager.show_unlocked_entities(
            passed_items_for_summary, 
            unlocked_character_ref_id if is_character_discovered else 0, 
            puzzles, 
            hypothetical_item_ids, 
        )


    if _dialog_shown_emitted:
        show_unlock_summaries.call()
    else:
        _dialog_shown.connect(
            show_unlock_summaries, 
            CONNECT_ONE_SHOT, 
        )
    _dialog_shown_emitted = false


func _on_mouse_exited() -> void :
    CursorService.set_cursor()


func _init_dialog(content_node: CanvasItem) -> void :
    _dialog = DialogScene.instantiate()
    _dialog.add_frame = true
    _dialog.hide_content_node_on_init = hide_content_node_on_init
    add_child(_dialog)
    _dialog.positioning_mode = Dialog.DialogPositioningMode.FLY_TO_CENTER
    _dialog.content_node = content_node
    _dialog_content_node = content_node
    _dialog.starting_position = global_position
    _dialog_content_node.global_position = global_position
    _dialog.dialog_hide_started.connect(_handle_dialog_hide_started)
    _dialog.hide()


func _handle_explored() -> void :
    explored.emit()
    if hotspot_id is String:
        hotspot_type = HotspotType.EXPLORED
        HotspotManager.mark_hotspot_explored(hotspot_id)


func _build_dependencies(root: Node, parent_hotspot: Hotspot = null) -> void :
    for child in root.get_children():
        if child is Hotspot:
            if parent_hotspot:
                parent_hotspot.add_dependent_hotspot(child as Hotspot)

            _build_dependencies(child, child as Hotspot)
        else:
            _build_dependencies(child, parent_hotspot)


func _handle_dialog_hide_started() -> void :
    AudioManager.play(AudioManager.Sound.CLOSEUP_CLOSE, SoundParams.new().with_pitch_range(Vector2(-0.1, 0.1)))


func _on_scenario_reset(_scenario_id: int) -> void :
    _clicked = false
    _dependencies_visited = 0
    if hotspot_type != HotspotType.LOCATION:
        _set_hotspot_type(HotspotType.DEFAULT)

    for hotspot: Hotspot in _dependencies:
        var sig: Signal = hotspot.explored
        if not sig.is_connected(_on_dependency_explored):
            sig.connect(
                _on_dependency_explored, 
                CONNECT_ONE_SHOT, 
            )


func check_if_exhausted() -> void :
    if not len(_dependencies):
        _handle_explored()


func _init_dialog_placeholder() -> void :
    if not _placeholder:
        return

    var new_dialog: Control = _placeholder.create_instance(true)
    _placeholder = null

    _build_dependencies(new_dialog, self)
    _init_dialog(new_dialog)


func _on_puzzle_solved(_meta: PuzzleMeta) -> void :
    if not locked:
        return
    if _check_if_unlocked():
        unlock_spot()


func unlock_spot() -> void :
        locked = false
        visible = true
        unlocked.emit()


func _check_if_unlocked() -> bool:
    if required_puzzles.size() == 0:
        return true
    for puzzle in required_puzzles:
        if not ProgressManager.is_puzzle_solved(puzzle.puzzle_id):
            return false
    return true


func _on_settingsmanager_setting_changed(section: String, key: String, value: Variant) -> void :
    if section != HIGHLIGHTER_SECTION or key != HIGHLIGHTER_SETTING:
        return

    highlight_point_hidden = not value


func _on_focusgrabber_mouse_entered() -> void :
    if focus_mode != FOCUS_ALL:
        return
    grab_focus()


func _setup_finale_timetravelbar_focus() -> void :
    if find_valid_focus_neighbor(Side.SIDE_TOP) is Control or not DialogManager.get_time_travel_bar():
        return
    focus_neighbor_top = DialogManager.get_time_travel_bar().get_path()


class UnlockHistory:
    var item_ids: Array[int]
    var hypothetical_item_ids: Array[int]
    var puzzles: Array[PuzzleMeta]
    var character_id: int


    func show_ghost_summary() -> void :
        ProgressManager.show_ghost_summary(
            item_ids, 
            character_id, 
            puzzles, 
            hypothetical_item_ids, 
        )
