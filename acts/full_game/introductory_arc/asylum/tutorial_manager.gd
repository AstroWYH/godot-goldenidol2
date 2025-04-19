extends CanvasLayer

const TUTORIAL_PUZZLE_ID: int = 103

@export var blocker_layer: CanvasLayer
@export var tutorial_puzzle: Control
@export var thinking_layer: CanvasLayer
@export var music_layers: Array[AudioStream]
@export var ambience_layers: Array[AudioStream]
@export var scenario: Scenario

@export_group("Explore")
@export var explore_quest_dialog: Control
@export var explore_quest_prompt: Control
@export var explore_quest_progress: CheckBox

@export_group("Open")
@export var open_quest_dialog: Control
@export var open_quest_prompt: Control
@export var open_quest_progress: Control

@export_group("Organize")
@export var organize_quest_dialog: Control
@export var organize_quest_prompt: Control
@export var organize_quest_indicator: Control

@export_group("Toggle")
@export var toggle_quest_dialog: Control
@export var toggle_quest_prompt: Control
@export var toggle_quest_indicator: Control

@export_group("Final")
@export var final_quest_dialog: Control

var black_hider: ColorRect
var bottom_panel: Control
var name_puzzle: Control
var event_puzzle: Control
var inventory: Control

var name_puzzle_open: bool = false
var event_puzzle_open: bool = false
var inventory_open: bool = false

var first_puzzle_finished: bool = false
var collect_quest_finished: bool = false
var open_quest_finished: bool = false
var organize_quest_finished: bool = false
var toggle_quest_finished: bool = false

var phrase_movement_count: int = 0
var switch_press_count: int = 0

var completion_sound: = AudioManager.Sound.TUTORIAL_PROGRESS

var completion_color: Color = Color.LAWN_GREEN

var spots_visited: int = 0

func _ready() -> void :
    if ProgressManager.tutorial_finished:
        queue_free()
        return






    black_hider = ColorRect.new()
    blocker_layer.add_child(black_hider)
    black_hider.size = Vector2(1920, 1080)
    black_hider.position = Vector2(0, 0)
    black_hider.color = Color.BLACK


    bottom_panel = get_tree().get_nodes_in_group("bottom_panel")[0]
    bottom_panel.visible = false

    name_puzzle = thinking_layer.get_child(2)
    event_puzzle = thinking_layer.get_child(3)
    for child in thinking_layer.get_children():
        if child is InventoryDialog:
            inventory = child
            break


    explore_quest_dialog.visible = false
    open_quest_dialog.visible = false
    organize_quest_dialog.visible = false
    toggle_quest_dialog.visible = false
    final_quest_dialog.visible = false

    ProgressManager.puzzle_solved.connect(_on_puzzle_solved)

    MusicPlayer.play_bg_audio([], ambience_layers)


    ProgressManager.initial_tutorial_in_progress = true


    check_if_intro_puzzle_solved()
    if not first_puzzle_finished:
        tutorial_puzzle.position = Vector2(1920, 1080) / 2 - tutorial_puzzle.size * tutorial_puzzle.scale / 2

        show_dialog(tutorial_puzzle)
    else:
        fadeout_black_screen()


func play_completion_sound() -> void :


    AudioManager.play(completion_sound)


func _on_puzzle_solved(_puzzle_meta: PuzzleMeta) -> void :
    if _puzzle_meta.puzzle_id == TUTORIAL_PUZZLE_ID:
        first_puzzle_finished = true
        await get_tree().create_timer(1.0).timeout
        disappear_puzzle()


func disappear_puzzle() -> void :
    DragAndDropManager.disable()
    var tween: Tween = create_tween()
    tween.tween_property(tutorial_puzzle, "position", Vector2(400, 1200), 3).set_trans(Tween.TRANS_QUART)
    tween.finished.connect(fadeout_black_screen)


func check_if_intro_puzzle_solved() -> void :
    if ProgressManager.is_puzzle_solved(TUTORIAL_PUZZLE_ID):
        first_puzzle_finished = true
    else:
        first_puzzle_finished = false


func fadeout_black_screen() -> void :
    tutorial_puzzle.visible = false
    var tween: Tween = create_tween()
    tween.tween_property(black_hider, "modulate", Color(0, 0, 0, 0), 3)
    tween.finished.connect(black_screen_fadeout_done)
    MusicPlayer.play_bg_audio(music_layers, ambience_layers)


func black_screen_fadeout_done() -> void :
    black_hider.visible = false
    bottom_panel.visible = true
    ProgressManager.initial_tutorial_in_progress = false
    bottom_panel.progress_indicator.everything_is_explored.connect(_on_everything_explored)


    show_dialog(explore_quest_dialog)

    _close_main_menu()


    DialogManager.focus_last_exploration_control()
    DragAndDropManager.enable()


    if bottom_panel.progress_indicator.is_everything_explored():
        _on_everything_explored()


func _close_main_menu() -> void :
    if not scenario:
        return
    scenario.hide_menu()


func _on_everything_explored() -> void :
    if collect_quest_finished:
        return

    explore_quest_dialog.modulate = completion_color
    explore_quest_progress.set_pressed_no_signal(true)
    explore_quest_prompt.visible = false
    collect_quest_finished = true


    name_puzzle.is_open_changed.connect(name_puzzle_changed)
    event_puzzle.is_open_changed.connect(event_puzzle_changed)
    inventory.active_changed.connect(inventory_changed)
    show_dialog(open_quest_dialog)


func name_puzzle_changed(state: bool) -> void :
    name_puzzle_open = state
    check_if_all_open()


func event_puzzle_changed(state: bool) -> void :
    event_puzzle_open = state
    check_if_all_open()


func inventory_changed(state: bool) -> void :
    inventory_open = state
    check_if_all_open()


func check_if_all_open() -> void :
    var required_count: int = 2
    if open_quest_finished:
        return
    var open_count: int = int(name_puzzle_open) + int(inventory_open)
    open_quest_progress.text = "%d / %d" % [open_count, required_count]

    if open_count == required_count:
        open_quest_prompt.visible = false
        open_quest_finished = true
        open_quest_dialog.modulate = completion_color
        play_completion_sound()
        fadeout_done_quest_dialog(explore_quest_dialog)


        show_dialog(organize_quest_dialog)
        ProgressManager.phrase_moved.connect(on_phrase_moved)


func on_phrase_moved() -> void :
    if organize_quest_finished:
        return

    phrase_movement_count += 1
    organize_quest_indicator.text = str(phrase_movement_count) + " / 3"

    if phrase_movement_count >= 3:
        organize_quest_prompt.visible = false
        organize_quest_finished = true
        organize_quest_dialog.modulate = completion_color
        play_completion_sound()


        fadeout_done_quest_dialog(open_quest_dialog)
        show_dialog(toggle_quest_dialog)
        bottom_panel.switch_pressed.connect(_on_switch_pressed)


func _on_switch_pressed() -> void :
    if toggle_quest_finished:
        return

    switch_press_count += 1
    toggle_quest_indicator.text = str(switch_press_count) + " / 4"

    if switch_press_count == 4:
        toggle_quest_prompt.visible = false
        toggle_quest_finished = true
        toggle_quest_dialog.modulate = completion_color
        play_completion_sound()


        fadeout_done_quest_dialog(organize_quest_dialog)
        final_quest_dialog.visible = true
        await get_tree().create_timer(1.0).timeout
        fadeout_done_quest_dialog(toggle_quest_dialog)
        ProgressManager.tutorial_finished = true
        ProgressManager.save_tutorial_finished()


func fadeout_done_quest_dialog(dialog: Control) -> void :
    var tween: Tween = create_tween()
    tween.tween_property(dialog, "modulate", Color(1, 1, 1, 0), 1)
    tween.finished.connect(hide_dialog.bind(dialog))


func hide_dialog(dialog: Control) -> void :
    dialog.visible = false


func show_dialog(dialog: Control) -> void :
    var tween: Tween = create_tween()
    dialog.visible = true
    dialog.modulate = Color.TRANSPARENT

    tween.set_parallel()
    tween.tween_property(dialog, "modulate", Color.WHITE, 2)
    if dialog is ThinkingWindow:
        tween.tween_callback(
            func() -> void : (dialog as PuzzleContainer).request_focus(Constants.FocusSide.RIGHT)
        ).set_delay(1)
