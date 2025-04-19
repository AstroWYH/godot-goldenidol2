class_name ThinkingUICard
extends Button

signal window_dragging_started(window: ThinkingWindow)
signal toggled_window(open: bool)
signal pressed_toggle_window(open: bool)
signal window_show_requested

const ANIM_REQUESTING_ATTENTION: = "requesting_attention"
const ANIM_OUT_DURATION: = 0.5
const PROP_POSITION: = "position"
const TEXT_LOCKED = "-"
const AnimationState: = preload("res://shared/ui/thinking_ui/animation_state.gd")
const MiniIndicatorScene = preload("res://shared/ui/thinking_ui/mini_indicator/mini_indicator.tscn")
const SwitchPressedStylebox = preload("res://shared/ui/container_switcher_prototype/assets/switch_pressed.stylebox")
const LockedPuzzleTexture = preload("res://shared/assets/placeholder_ui/buttons/lockedpuzzle.png")
const frame_active_texture: Texture = preload("res://shared/assets/ui_icons/Frame_selected_active.png")
const frame_inactive_texture: Texture = preload("res://shared/assets/ui_icons/Frame_selected_inactive.png")

@export var icon_texture: Texture2D
@export var label: String
@export var puzzles: Array[PuzzleMeta]
@export var sequence_element_id: String

var active: bool = true:
    set = set_active
var window_rect: Rect2:
    get: return _window.get_global_rect()
var window_scale: Vector2:
    get: return _window.scale
var side_focus_requested: Signal:
    get: return _window.side_focus_requested
var selected: bool = false
var active_color: Color = Color("Green")
var particle_effect: GPUParticles2D

var _window: Control
var _last_window_pos: Vector2
var _locked: bool:
    set = set_locked
var _hide_card_when_locked: bool = false
var _clicked: bool = false
var _unlocks_items: Array[int] = []
var _animate_tween: Tween
var full_scale: Vector2
var disappearing_scale: Vector2
var enlarged_scale: Vector2

@onready var puzzle_icon: TextureRect = % PuzzleIcon
@onready var puzzle_label: Label = % PuzzleLabel
@onready var viewport_rect: Rect2 = get_viewport().get_visible_rect()
@onready var hidden_y: float = viewport_rect.size.y + 50
@onready var frame: NinePatchRect = % Frame
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var margin_container: Control = $MarginContainer
@onready var hbox_container: Control = $HBoxContainer


func _ready() -> void :
    SettingsManager.ui_scale_changed.connect(_on_ui_scale_changed)
    update_ui_scale_variables(SettingsManager.get_ui_scale())


    if puzzles.size():
        var texture: Texture2D = LockedPuzzleTexture
        var card_text: String = TEXT_LOCKED

        for puzzle_meta: PuzzleMeta in puzzles:
            var discovery_state: = DiscoveryManager.is_puzzle_discovered(puzzle_meta)
            _locked = puzzle_meta.locked_by_default and discovery_state == DiscoveryManager.DiscoveryState.LOCKED
            if _locked:
                _hide_card_when_locked = puzzle_meta.hide_card_when_locked


            if discovery_state == DiscoveryManager.DiscoveryState.UNDISCOVERED:
                _play_attention_request()


            break

        if not _locked:
            texture = icon_texture
            card_text = label
        else:
            if _hide_card_when_locked:
                hide()
            ProgressManager.puzzles_unlocked.connect(_unlock_puzzle)

        puzzle_icon.texture = texture
        puzzle_label.text = card_text
    else:
        puzzle_icon.texture = icon_texture
        puzzle_label.text = label

    update_inactive_visual()


func get_thinking_window() -> ThinkingWindow:
    return _window


func lock_card() -> void :
    _locked = true
    puzzle_icon.texture = LockedPuzzleTexture
    puzzle_label.text = TEXT_LOCKED
    _stop_attention_request()

    if active:
        close_window()
        _clicked = false


func connect_window(window: RefCounted, is_inventory: bool) -> void :
    _window = window.instance
    _window.close_pressed.connect(close_window)
    _window.dragging_started.connect(_on_window_dragging_started.bind(_window))

    _store_window_pos()
    _window.position.y = hidden_y

    if is_inventory and ProgressManager.current_scenario_meta is ScenarioMeta and (ProgressManager.current_scenario_meta as ScenarioMeta).no_inventory:

        lock_card()


    var puzzle_group: PuzzleGroup = _window.puzzle_group if "puzzle_group" in _window else null

    _unlocks_items = window.unlocks_items

    if puzzle_group:
        var mini_indicator: Control = MiniIndicatorScene.instantiate()
        mini_indicator.puzzle_group = puzzle_group
        add_child(mini_indicator)


    active = false
    selected = is_inventory
    update_inactive_visual()

    sequence_element_id = window.sequence_element_id
    if len(sequence_element_id):
        var state: = SequenceManager.get_element_state(sequence_element_id)
        if state == SequenceManager.ElementState.HEAD:
            open_window(true, Constants.FocusSide.LEFT)
        elif state == SequenceManager.ElementState.ACTIVE:
            SequenceManager.sequence_element_requested.connect(_on_sequence_element_requested)


func is_locked() -> bool:
    return _locked


func set_locked(v: bool) -> void :
    _locked = v
    mouse_default_cursor_shape = CursorShape.CURSOR_ARROW if _locked else CursorShape.CURSOR_POINTING_HAND


func _on_pressed() -> void :
    if _locked:
        return

    if AnimationState.animating:
        return
    _mark_as_animating()

    if animation_player.is_playing() and animation_player.current_animation == ANIM_REQUESTING_ATTENTION:

        mark_viewed()

        var tween: = create_tween().set_parallel()
        tween.tween_property(margin_container, PROP_POSITION, Vector2.ZERO, ANIM_OUT_DURATION)
        tween.tween_property(hbox_container, PROP_POSITION, Vector2.ZERO, ANIM_OUT_DURATION)

    if not active:

        if not _clicked and len(_unlocks_items):
            var new_items: Array[int] = ProgressManager.unlock_items(_unlocks_items)
            ProgressManager.show_unlocked_entities(new_items, 0, [], [])
        _window.move_to_front()
        open_window(false, Constants.FocusSide.ANY)
    elif active:
        close_window()
    AudioManager.play(AudioManager.Sound.THINKING_CARD_CLICK)


func request_focus(side: Constants.FocusSide) -> void :
    _window.request_focus(side)


func open_window(force_move_to_front: bool = false, focus_side: Constants.FocusSide = Constants.FocusSide.NONE) -> void :
    _clicked = true
    active = true
    selected = true

    if "active" in _window:
        _window.active = true

    toggled_window.emit(false)
    pressed_toggle_window.emit(self, true)

    if force_move_to_front:
        _window.move_to_front()

    if focus_side != Constants.FocusSide.NONE:


        window_show_requested.connect(
            func() -> void :
                request_focus(focus_side), 
            CONNECT_ONE_SHOT
        )

    show_window()


func close_window() -> void :
    active = false
    if "active" in _window:
        _window.active = false
    if selected:
        selected = false

    if _clicked:
        _store_window_pos()
    else:






        _window.hide()

    toggled_window.emit(false)
    pressed_toggle_window.emit(self, false)

    hide_window()


func set_window_global_position(new_win_pos: Vector2) -> void :
    _window.global_position = new_win_pos


func show_window() -> void :
    update_active_visual()
    animate_window_v2(true)
    window_show_requested.emit()


func hide_window() -> void :
    update_inactive_visual()
    animate_window_v2(false)

    if len(sequence_element_id) and SequenceManager.is_element_active(sequence_element_id):
        SequenceManager.mark_handled(sequence_element_id)


func animate_window_v2(open: bool) -> void :
    if _animate_tween and _animate_tween.is_running():

        return

    _window.position = _last_window_pos
    var anim_time: float = AnimationState.ANIMATION_TIME / 2

    adjust_pivot_and_position(_window, true)


    if open:
        _window.visible = true
    _animate_tween = create_tween()
    _animate_tween.tween_property(_window, "scale", enlarged_scale, anim_time)
    _animate_tween.finished.connect(tween_first_part_finished.bind(_window, open))


func tween_first_part_finished(_win: Control, open: bool) -> void :
    var size_tween: = create_tween()
    var anim_time: float = AnimationState.ANIMATION_TIME / 2
    if open:
        size_tween.tween_property(_window, "scale", full_scale, anim_time)
    else:
        size_tween.tween_property(_window, "scale", disappearing_scale, anim_time)
    size_tween.finished.connect(tween_second_part_finished.bind(_window, open))


func tween_second_part_finished(_win: Control, open: bool) -> void :
    if not open:
        _win.visible = false

    adjust_pivot_and_position(_win, false)
    _win.request_state_change(open, _win.position.y)


func adjust_pivot_and_position(_node: Control, _center_pivot: bool) -> void :
    pass
    "\n	if center_pivot:\n		node.pivot_offset = node.size / 2\n		node.position -= node.size * SettingsManager.get_ui_scale() / 2\n	else:\n		node.pivot_offset = Vector2.ZERO\n		node.position += node.size * SettingsManager.get_ui_scale() / 2\n	"









func set_active(v: bool) -> void :
    active = v


func _store_window_pos() -> void :
    _last_window_pos = _window.position


func is_window_visible() -> bool:
    return _window.visible


func update_active_visual() -> void :
    frame.texture = frame_active_texture
    frame.visible = true



func update_inactive_visual() -> void :


    if selected:
        frame.texture = frame_inactive_texture
        frame.visible = true

    if not selected:
        frame.visible = false


func _get_ypos(opened: bool) -> float:
    return _last_window_pos.y if opened else hidden_y


func _unlock_puzzle(unlocked_puzzles: Array[PuzzleMeta]) -> void :
    var hit: = false
    for unlocked_puzzle in unlocked_puzzles:
        for puzzle in puzzles:
            if puzzle.puzzle_id == unlocked_puzzle.puzzle_id:

                hit = true
                break

    if not hit:
        return

    if _hide_card_when_locked:
        show()

    _locked = false
    _play_attention_request()
    puzzle_icon.texture = icon_texture
    puzzle_label.text = label


func toggle_state(state_pressed: bool) -> void :
    if state_pressed:
        active = true
        if "active" in _window:
            _window.active = true
        show_window()
    elif not state_pressed:
        _store_window_pos()
        active = false
        if "active" in _window:
            _window.active = true
        hide_window()


func mark_viewed() -> void :
    if not animation_player.is_playing() or animation_player.current_animation != ANIM_REQUESTING_ATTENTION:
        return


    for puzzle_meta: PuzzleMeta in puzzles:
        DiscoveryManager.mark_puzzle_discovered(puzzle_meta.puzzle_id)

    _stop_attention_request()


func _on_mouse_entered() -> void :
    if is_locked():
        return

    puzzle_icon.modulate = Color(1.3, 1.3, 1.3, 1)
    puzzle_icon.pivot_offset = puzzle_icon.size / 2
    puzzle_icon.position.y -= 5
    puzzle_icon.rotation_degrees = 4



func _on_mouse_exited() -> void :
    if is_locked():
        return

    puzzle_icon.modulate = Color(1, 1, 1, 1)
    puzzle_icon.pivot_offset = puzzle_icon.size / 2
    puzzle_icon.position.y += 5
    puzzle_icon.rotation_degrees = 0



func _mark_as_animating() -> void :
    AnimationState.mark_as_animating(self)


func _on_sequence_element_requested(seq_el_id: String) -> void :
    if seq_el_id == sequence_element_id:

        open_window(true, Constants.FocusSide.ANY)
        SequenceManager.sequence_element_requested.disconnect(_on_sequence_element_requested)


func _on_window_dragging_started(window: ThinkingWindow) -> void :
    window_dragging_started.emit(window)


func _play_attention_request() -> void :
    animation_player.play(ANIM_REQUESTING_ATTENTION)
    particle_effect = load("res://shared/ui/special_effects/particle_effect.tscn").instantiate()
    puzzle_icon.add_child(particle_effect)


func _stop_attention_request() -> void :
    animation_player.pause()

    if particle_effect:
        particle_effect.queue_free()
        particle_effect = null


func update_ui_scale_variables(new_scale: Vector2) -> void :
    full_scale = new_scale
    disappearing_scale = full_scale * Vector2(0.75, 0.75)
    enlarged_scale = full_scale * Vector2(1.05, 1.05)


func _on_ui_scale_changed(new_scale: Vector2) -> void :
    update_ui_scale_variables(new_scale)
