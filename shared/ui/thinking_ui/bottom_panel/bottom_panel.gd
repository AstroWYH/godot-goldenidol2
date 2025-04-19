extends Control

signal switch_pressed

const AnimationState: = preload("res://shared/ui/thinking_ui/animation_state.gd")
const UICardScene: = preload("res://shared/ui/thinking_ui/thinking_ui_card/thinking_ui_card.tscn")

const WINDOW_POSITIONING_MARGIN: float = 50.0

var thinking_expanded: bool = false
var card_list: Array[ThinkingUICard]
var card_count: int:
    get: return len(card_list)


var _pad_idx_left: int = -1
var _pad_idx_right: int = -1
var _left_last_focused: bool = true
var _bottom_panel_gui_size: Vector2

@onready var switch: Control = % Switch
@onready var card_container: HBoxContainer = % CardContainer
@onready var back_button: BaseButton = % BackButton
@onready var progress_indicator: Control = % ProgressIndicator


func _ready() -> void :
    if not ProgressManager.current_scenario:
        back_button.visible = false
        switch.visible = false

    back_button.pressed.connect(_on_back_button_pressed)
    switch.switch_pressed.connect(_on_bottom_bar_switch_pressed)
    update_switch_state()
    _bottom_panel_gui_size = $MarginContainer.size
    DragAndDropManager.side_focus_requested.connect(_on_side_focus_requested)
    DragAndDropManager.dragged_node_released.connect(_on_dragged_node_released)
    DragAndDropManager.refocused_post_drop.connect(_on_refocused_post_drop)
    ProgressManager.scenario_reset.connect(_on_scenario_reset)
    SettingsManager.ui_scale_changed.connect(_on_ui_scale_changed)
    get_viewport().gui_focus_changed.connect(_on_gui_focus_changed)
    scale = SettingsManager.get_ui_scale()


func get_panel_rect() -> Rect2:
    return $MarginContainer.get_global_rect()


func add_puzzle_card(puzzles: Array, label: String = "", texture: Texture2D = null) -> Control:
    var card: ThinkingUICard = UICardScene.instantiate()
    card.icon_texture = texture
    card.label = label
    card.pressed_toggle_window.connect(_on_card_pressed)
    card.window_dragging_started.connect(_on_window_dragging_started.bind(card))
    card.puzzles = puzzles
    call_deferred("_connect_side_focus_request", card)


    if not puzzles.size():
        card.active = false

    card_container.add_child(card)
    card_list.append(card)

    return card


func _connect_side_focus_request(card: ThinkingUICard) -> void :
    card.side_focus_requested.connect(_on_side_focus_requested)


func _on_bottom_bar_switch_pressed(pressed: bool) -> void :
    for card: ThinkingUICard in card_list:
        if card.selected:
            card.toggle_state(pressed)

    update_switch_state()
    switch_pressed.emit()


func _unhandled_input(_event: InputEvent) -> void :
    if ProgressManager.victory_sequence_playing or ProgressManager.initial_tutorial_in_progress:
        return

    if Input.is_action_just_pressed(GamepadUtils.ACTION_PANEL_TOGGLE):
        _handle_panel_toggle()
        return

    if Input.is_action_just_pressed(GamepadUtils.ACTION_CYCLE_LEFT_NEXT):
        _handle_gamepad_cycle(true, true)
        return

    if Input.is_action_just_pressed(GamepadUtils.ACTION_CYCLE_RIGHT_NEXT):
        _handle_gamepad_cycle(false, true)
        return


func _on_card_pressed(card: ThinkingUICard, pressed: bool) -> void :
    if pressed:
        _set_pad_index_from_card(card)

    if not thinking_expanded:
        if pressed:

            for item: ThinkingUICard in card_list:
                if item.selected:
                    item.toggle_state(pressed)
        elif not pressed:

            pass

    update_switch_state()


func _on_side_focus_requested(focus_side: Constants.FocusSide) -> void :

    _handle_gamepad_cycle( not _left_last_focused, focus_side == Constants.FocusSide.LEFT, focus_side)


func update_switch_state() -> void :



    for item: ThinkingUICard in card_list:
        if item.active:
            switch.set_switch(2)
            thinking_expanded = true
            return


    for item: ThinkingUICard in card_list:
        if item.selected:
            switch.set_switch(1)
            thinking_expanded = false
            return


    switch.set_switch(0)
    thinking_expanded = false


func _on_back_button_pressed() -> void :
    AudioManager.play(AudioManager.Sound.BUTTON_CLICK)
    ProgressManager.current_scenario.in_game_menu.show()


func _mark_as_animating() -> void :
    AnimationState.mark_as_animating(self)



func _can_cycle(left_side: bool) -> bool:
    var selectable_count: int = len(card_list.filter(func(el: ThinkingUICard) -> bool: return not el.is_locked()))

    if selectable_count == 1:
        if left_side and _pad_idx_right != -1:

            return false
        elif not left_side and _pad_idx_left != -1:

            return false
        return true

    var candidates_left: int = selectable_count
    return candidates_left > 0


func _cycle_pad_idx_left(modifier: int) -> void :
    if card_count < 1:
        _pad_idx_left = 0
        return


    _pad_idx_left = wrapi(_pad_idx_left + modifier, -1, card_count)
    if _pad_idx_left != -1 and (_pad_idx_left == _pad_idx_right or card_list[_pad_idx_left].is_locked()):
        _cycle_pad_idx_left(modifier)


func _cycle_pad_idx_right(modifier: int) -> void :
    if card_count < 1:
        _pad_idx_right = 0
        return


    _pad_idx_right = wrapi(_pad_idx_right + modifier, -1, card_count)
    if _pad_idx_right != -1 and (_pad_idx_left == _pad_idx_right or card_list[_pad_idx_right].is_locked()):
        _cycle_pad_idx_right(modifier)


func _handle_gamepad_cycle(left_side: bool = true, next: bool = true, focus_side: Constants.FocusSide = Constants.FocusSide.ANY) -> void :
    get_viewport().set_input_as_handled()
    var other_side_card: ThinkingUICard


    var card_to_show: ThinkingUICard


    var modifier: int = 1 if next else -1

    if not _can_cycle(left_side):
        return

    if left_side:
        if not _left_last_focused and _pad_idx_left != -1:

            modifier = 0

        _cycle_pad_idx_left(modifier)

        card_to_show = card_list[_pad_idx_left] if _pad_idx_left >= 0 else null

        if _pad_idx_right > -1:
            other_side_card = card_list[_pad_idx_right]
    else:
        if _left_last_focused and _pad_idx_right != -1:

            modifier = 0

        _cycle_pad_idx_right(modifier)

        card_to_show = card_list[_pad_idx_right] if _pad_idx_right >= 0 else null

        if _pad_idx_left > -1:
            other_side_card = card_list[_pad_idx_left]

    _left_last_focused = left_side


    for card: ThinkingUICard in card_list:
        if card == card_to_show:
            card.open_window(true, focus_side)
            continue

        if card != other_side_card and card.is_window_visible():
            card.close_window()
            continue

    if card_to_show == null:
        return

    var screen_size: Vector2i = Vector2i(1920, 1080)
    var half_screen: Vector2 = Vector2(screen_size.x / 2, screen_size.y)
    var window_size: Vector2 = card_to_show.window_rect.size
    var window_scale: Vector2 = card_to_show.window_scale
    var gui_y: float = _bottom_panel_gui_size.y






    var final_size: Vector2 = (window_size / window_scale) * SettingsManager.get_ui_scale()


    var window_pos: Vector2 = Vector2(0, (half_screen.y - gui_y - final_size.y) / 2)

    var fits_in_half: bool = final_size.x + WINDOW_POSITIONING_MARGIN <= half_screen.x



    if left_side:
        if fits_in_half:
            window_pos.x += half_screen.x - final_size.x - WINDOW_POSITIONING_MARGIN
        else:
            window_pos.x += WINDOW_POSITIONING_MARGIN

        card_to_show.set_window_global_position(window_pos)
    else:
        if fits_in_half:
            window_pos.x += WINDOW_POSITIONING_MARGIN
        else:
            window_pos.x -= final_size.x - half_screen.x + WINDOW_POSITIONING_MARGIN
        card_to_show.set_window_global_position(Vector2(
            half_screen.x + window_pos.x, 
            window_pos.y, 
        ))

    card_to_show.mark_viewed()



func _on_window_dragging_started(_window: ThinkingWindow, card: ThinkingUICard) -> void :
    _set_pad_index_from_card(card)




func _set_pad_index_from_card(card: ThinkingUICard) -> void :
    var index: int = card_list.find(card)
    if index == _pad_idx_left or index == _pad_idx_right:

        return

    if _left_last_focused:
        _pad_idx_right = index
    else:
        _pad_idx_left = index


func _handle_panel_toggle() -> void :
    if AnimationState.animating:
        return
    get_viewport().set_input_as_handled()
    _mark_as_animating()

    if _pad_idx_left == -1 and _pad_idx_right == -1:

        _pad_idx_left = 0

    var new_state: = not thinking_expanded
    _on_bottom_bar_switch_pressed(new_state)

    if new_state == true:
        AudioManager.play(AudioManager.Sound.THINKING_TOGGLE_ON)

        for card: ThinkingUICard in card_list:
            if card.active:
                card.request_focus(Constants.FocusSide.ANY)
    else:
        DragAndDropManager.drop_dragged_node(DragAndDropManager.DropBehavior.REMOVE)
        DialogManager.focus_last_exploration_control()
        AudioManager.play(AudioManager.Sound.THINKING_TOGGLE_OFF)


func _on_scenario_reset(_scenario_id: int) -> void :

    var puzzles_to_lock: Array[int] = []

    for card in card_list:
        if not len(card.puzzles):
            continue
        var master_puzzle: PuzzleMeta = card.puzzles[0]
        if master_puzzle.locked_by_default:
            puzzles_to_lock.append(master_puzzle.puzzle_id)
            card.lock_card()

    ProgressManager.relock_puzzles(puzzles_to_lock)


func _on_ui_scale_changed(ui_scale: Vector2) -> void :
    if visible:
        scale = ui_scale


func _on_gui_focus_changed(focus_owner: Control) -> void :


    var card_index: int = -1
    for i in len(card_list):
        var tw: ThinkingWindow = card_list[i].get_thinking_window()
        if tw.is_ancestor_of(focus_owner):
            card_index = i
            break

    if card_index == -1:
        return

    _left_last_focused = card_index == _pad_idx_left


func _on_dragged_node_released() -> void :
    _on_refocused_post_drop(get_viewport().gui_get_focus_owner())


func _on_refocused_post_drop(focus_owner: Control) -> void :




    if not focus_owner:
        return

    for card in card_list:
        var tw: ThinkingWindow = card.get_thinking_window()
        if tw.is_ancestor_of(focus_owner):
            tw.move_to_front()
            return
