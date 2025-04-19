@tool
extends CanvasLayer

const POS_PHRASE_INVENTORY: = Vector2i(50, 50)
const ScenarioVictoryScene: = preload("res://shared/ui/scenario_victory/scenario_victory.tscn")
const PhraseInventoryScene: = preload("res://shared/ui/thinking_ui/phrase_inventory/phrase_inventory.tscn")
const UnlockSummaryScene: = preload("res://shared/ui/unlock_summary/unlock_summary.tscn")

const LastPuzzleCompletedMusic: AudioStreamOggVorbis = preload("res://shared/assets/music/last_puzzle_complete.ogg")
const ScenarioCompletedMusic: AudioStreamOggVorbis = preload("res://shared/assets/music/scenario_complete.ogg")

@onready var transform_area: Control = $TransformArea

var _ghost_summary_stack: Array[Node] = []
var arc_puzzle_ids: Array = []
var victory_button_shown: bool
var end_sequence_scale_tween: Tween

func _ready() -> void :
    if Engine.is_editor_hint():
        var bottom_panel: Control = (load("res://shared/ui/thinking_ui/bottom_panel/bottom_panel.tscn") as PackedScene).instantiate()
        add_child(bottom_panel)
        return

    ProgressManager.entities_unlocked.connect(show_unlock_summary.bind(false))
    ProgressManager.ghost_summary_requested.connect(show_unlock_summary.bind(true))
    DialogManager.dialog_closed.connect(_pop_ghost_summary)
    ContainerDragAndDropManager.transform_area = transform_area
    ProgressManager.puzzle_solved.connect(_on_puzzle_solved)


    for child in get_children():
        if child is PuzzleContainer:
            if child.is_arc_win_condition:
                arc_puzzle_ids.append(child.puzzle_group.get_child(0).puzzle_meta.puzzle_id)
            child.scale = SettingsManager.get_ui_scale()
            SettingsManager.ui_scale_changed.connect(child.on_ui_scale_changed as Callable)


func init_windows() -> Array[ScenarioUIWindow]:
    var puzzle_windows: Array[ScenarioUIWindow] = []



    var inv: Control
    if ProgressManager.current_scenario:
        inv = PhraseInventoryScene.instantiate()
        add_child(inv)

        var gpos: = POS_PHRASE_INVENTORY
        inv.global_position = gpos

        var inv_win: ScenarioUIWindow = ScenarioUIWindow.new()
        inv_win.instance = inv

        puzzle_windows.append(inv_win)

        ProgressManager.scenario_beaten.connect(show_victory_sequence)

    for thinking_layer_window in get_children():
        if thinking_layer_window == transform_area or thinking_layer_window == inv:
            continue

        var win: ScenarioUIWindow = ScenarioUIWindow.new()
        win.instance = thinking_layer_window
        win.sequence_element_id = thinking_layer_window.sequence_element_id

        if "puzzle_group" in thinking_layer_window:

            var puzzle_group: PuzzleGroup = thinking_layer_window.puzzle_group
            var puzzle_meta_list: Array[PuzzleMeta] = []

            for puzzle in puzzle_group.get_children():
                puzzle_meta_list.append(puzzle.puzzle_meta)
            win.puzzles = puzzle_meta_list
            win.label = puzzle_group.group_name
            win.icon = puzzle_group.group_icon

            var unlocks_items: Array[int] = []
            for item_id: PhraseGridItem in thinking_layer_window.unlocks_items:
                unlocks_items.append(item_id.linked_item_ref_id)
            win.unlocks_items = unlocks_items

        puzzle_windows.append(win)

    return puzzle_windows


func show_unlock_summary(item_ids: Array[int], character_id: int, puzzles: Array[PuzzleMeta], hypothetical_item_ids: Array[int], ghost: bool) -> void :

    if not ProgressManager.current_scenario:
        return

    if not character_id and not len(item_ids) and not len(puzzles):
        if ghost:
            _ghost_summary_stack.append(null)
        return

    var summary: Control = UnlockSummaryScene.instantiate()
    summary.ghost_mode = ghost
    summary.character_id = character_id
    summary.item_ids = item_ids
    summary.puzzles = puzzles
    summary.hypthetical_item_ids = hypothetical_item_ids
    summary.inventory_gpos = ProgressManager.inventory_card.global_position

    DialogManager.dialog_layer.add_child(summary)

    summary.show_summary()
    if ghost:

        for prev_summary in _ghost_summary_stack:
            if prev_summary is CanvasItem:
                prev_summary.hide()
        _ghost_summary_stack.append(summary)
    elif character_id != 0 or len(puzzles):
        AudioManager.play(AudioManager.Sound.CHARACTER_DISCOVERED)


func _pop_ghost_summary() -> void :
    if not len(_ghost_summary_stack):
        return

    if not DialogManager.get_top():

        for prev_summary in _ghost_summary_stack:
            if prev_summary is Node:
                prev_summary.queue_free()
        _ghost_summary_stack = []
        return

    var top: Variant = _ghost_summary_stack.pop_back()
    if top is Node:
        top.queue_free()

    var size: int = _ghost_summary_stack.size()
    if size:
        var new_top: Variant = _ghost_summary_stack[size - 1]
        if new_top is CanvasItem:
            new_top.show()

func _on_puzzle_solved(_puzzle_meta: PuzzleMeta) -> void :
    if ProgressManager.current_arc_id in ProgressManager.arcs_finished:
        return

    if arc_puzzle_ids.size() < 1:
        return

    for id: int in arc_puzzle_ids:
        if not ProgressManager.is_puzzle_solved(id):
            return

    call_deferred("_chapter_finished", _puzzle_meta)


func _chapter_finished(puzzle_meta: PuzzleMeta) -> void :
    ProgressManager.arcs_finished.append(ProgressManager.current_arc_id)
    ProgressManager.save_finished_arcs()

    var arc_meta: Variant = ProgressManager.get_current_arc_meta()
    if arc_meta is ArcMeta:
        Platform.award_achievement(arc_meta.achievement_id as PlatformBase.Achievement)
    show_victory_sequence(-1, puzzle_meta)










func show_victory_sequence(_scenario_id: int, puzzle_meta: PuzzleMeta) -> void :
    ProgressManager.victory_sequence_playing = true

    var victory_puzzle: Control
    var puzzle_group: Control
    var nodes: Array = get_children()

    NodeUtils.unfocus()

    for node: Control in nodes:
        if not node is PuzzleContainer:
            continue

        puzzle_group = node.puzzle_group

        for child in puzzle_group.get_children():
            if child.puzzle_meta == puzzle_meta:
                victory_puzzle = node
                break

        if victory_puzzle == node:
            break

    if not victory_puzzle:
            return

    start_victory_animation(victory_puzzle)


func start_victory_animation(victory_puzzle: Control) -> void :

    victory_puzzle.indicator.disconnect_state_tracking()
    victory_puzzle.close_button.visible = false


    var dark_background: ColorRect = ColorRect.new()
    dark_background.size = Vector2(1920, 1080)
    dark_background.color = Color(0, 0, 0, 0.8)
    ProgressManager.dialog_layer.add_child(dark_background)


    victory_puzzle.get_parent().remove_child(victory_puzzle)
    ProgressManager.dialog_layer.add_child(victory_puzzle)


    var input_blocker: Control = Control.new()
    input_blocker.size = Vector2(1920, 1080)
    input_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
    ProgressManager.dialog_layer.add_child(input_blocker)


    var target_position: Vector2 = Vector2(960, 540) - victory_puzzle.size * victory_puzzle.scale / 2
    var tween: Tween = create_tween()
    tween.set_trans(Tween.TRANS_QUAD)
    tween.tween_property(victory_puzzle, "position", target_position, 1)


    victory_puzzle.indicator.change_indicator(Puzzle.PuzzleCompletenessState.UNSET)


    MusicPlayer.restore_gain()
    MusicPlayer.disable_filter(MusicPlayer.FilterType.LOWPASS, MusicPlayer.BUS_MUSIC)
    MusicPlayer.disable_filter(MusicPlayer.FilterType.HIGHPASS, MusicPlayer.BUS_MUSIC)

    MusicPlayer.stop(MusicPlayer.PlayerGroup.AMBIENCE, 1.0)
    MusicPlayer.play_bg_audio([LastPuzzleCompletedMusic], [], true)

    tween.finished.connect(animate_slots.bind(victory_puzzle))


func animate_slots(victory_puzzle: Control) -> void :

    var all_slots: Array = []



    for child: Control in victory_puzzle.puzzle_group.get_children():
        var puzzle_slots: Array = child.get_all_slots()
        all_slots.append_array(puzzle_slots)

    for i: int in range(all_slots.size()):
        if not ProgressManager.victory_sequence_playing:
            break

        var slot: Control = all_slots[i]
        var last_slot: bool = false


        if i == all_slots.size() - 1:
            last_slot = true
        slot_animation(slot, victory_puzzle).connect(slot_animation_2.bind(slot, victory_puzzle, last_slot))

        AudioManager.play(
            AudioManager.Sound.PUZZLE_SOLVED_PHRASE_HIGHLIGHT, 
            SoundParams.new().with_pitch_scale(1 + 0.01 * i)
        )

        await get_tree().create_timer(0.2).timeout


func slot_animation(slot: Control, _victory_puzzle: Control) -> Signal:
    var scale_tween: Tween = create_tween()
    var color_tween: Tween = create_tween()
    scale_tween.tween_property(slot, "scale", Vector2(1.1, 1.1), 0.2)
    color_tween.tween_property(slot, "modulate", Color.GREEN_YELLOW, 0.3)
    return scale_tween.finished


func slot_animation_2(slot: Control, victory_puzzle: Control, last_slot: bool) -> void :
    var scale_tween: Tween = create_tween()
    var color_tween: Tween = create_tween()
    scale_tween.tween_property(slot, "scale", Vector2(1, 1), 0.2)
    color_tween.tween_property(slot, "modulate", Color.WHITE, 0.3)
    if last_slot:
        scale_tween.finished.connect(victory_sequence_done.bind(victory_puzzle))


func victory_sequence_done(victory_puzzle: Control) -> void :

    var indicator: Control = victory_puzzle.indicator
    animate_indicator(indicator, victory_puzzle)


func animate_indicator(indicator: Control, victory_puzzle: Control) -> void :
    var scale_duration: float = 2.0
    end_sequence_scale_tween = create_tween()

    end_sequence_scale_tween.set_ease(Tween.EASE_IN)
    end_sequence_scale_tween.tween_property(indicator, "scale", Vector2(1.1, 1.1), scale_duration)

    var start_pos: = indicator.position
    var shake_tween: Tween = create_tween()
    var shake: float = 2.0
    var shake_duration: float = 0.025
    var shake_count: float = floorf(scale_duration / shake_duration)

    for i in shake_count:
        var shake_scale: float = i / shake_count
        var posx: = indicator.position.x
        var posy: = indicator.position.y
        shake_tween.tween_property(
            indicator, 
            "position", 
            Vector2(
                randf_range(posx - shake * shake_scale, posx + shake * shake_scale), 
                randf_range(posy - shake * shake_scale, posy + shake * shake_scale)
            ), 
            shake_duration)
    shake_tween.tween_property(indicator, "position", start_pos, shake_duration)

    AudioManager.play(AudioManager.Sound.PUZZLE_SOLVED_INDICATOR_BUILDUP)

    end_sequence_scale_tween.finished.connect(animate_indicator_2.bind(indicator, victory_puzzle))


func animate_indicator_2(indicator: Control, victory_puzzle: Control) -> void :
    indicator.change_indicator(Puzzle.PuzzleCompletenessState.COMPLETE_CORRECT)
    AudioManager.play(AudioManager.Sound.PUZZLE_SOLVED_CORRECTLY_END_SEQUENCE)

    end_sequence_scale_tween = create_tween()

    end_sequence_scale_tween.set_ease(Tween.EASE_OUT)
    end_sequence_scale_tween.tween_property(indicator, "scale", Vector2(1, 1), 0.2)

    end_sequence_scale_tween.finished.connect(show_victory_button.bind(victory_puzzle))


func show_victory_button(victory_puzzle: Control) -> void :
    if victory_button_shown:
        return
    victory_button_shown = true

    var screen_size: = get_viewport().get_visible_rect().size
    var victory_button: Button = load("res://shared/ui/victory_sequence/scenario_victory_button.tscn").instantiate()
    ProgressManager.dialog_layer.add_child(victory_button)
    victory_button.position.x = screen_size.x / 2 - victory_button.size.x / 2
    victory_button.position.y = screen_size.y - victory_button.size.y - 10
    victory_button.pressed.connect(_on_victory_button_pressed.bind(victory_button, victory_puzzle))
    victory_button.grab_focus()


func _on_victory_button_pressed(victory_button: Button, victory_puzzle: Control) -> void :
    AudioManager.play(AudioManager.Sound.BUTTON_CLICK)
    AudioManager.stop_sound(AudioManager.Sound.PUZZLE_SOLVED_INDICATOR_BUILDUP)

    if end_sequence_scale_tween:
        end_sequence_scale_tween.kill()


    if victory_puzzle.is_win_condition:
        if victory_button:
            victory_button.queue_free()
        if victory_puzzle:
            victory_puzzle.get_parent().remove_child(victory_puzzle)
            add_child(victory_puzzle)
            victory_puzzle.close_button.visible = true

        var victory_popup: ColorRect
        if len(ProgressManager.current_scenario_meta.custom_victory_dialog_path) > 0:
            victory_popup = load(ProgressManager.current_scenario_meta.custom_victory_dialog_path).instantiate()
        else:
            victory_popup = ScenarioVictoryScene.instantiate()
        victory_popup.scenario_meta = ProgressManager.current_scenario_meta
        victory_popup.quit_to_menu_requested.connect(ProgressManager.current_scenario.exit_pressed, CONNECT_ONE_SHOT)

        MusicPlayer.play_bg_audio([ScenarioCompletedMusic], [], true)
        ProgressManager.dialog_layer.add_child(victory_popup)
    elif victory_puzzle.is_arc_win_condition:
        ProgressManager.victory_sequence_playing = false

        var target_scene_path: String = ""
        match ProgressManager.current_arc_id:
            1: target_scene_path = "res://acts/full_game/intermisions/pursuit_intermission.tscn"
            2: target_scene_path = "res://acts/full_game/intermisions/machine_intermission.tscn"
            3: target_scene_path = "res://acts/full_game/intermisions/trials_intermission.tscn"
            4: target_scene_path = "res://acts/full_game/intermisions/pinnacle_intermission.tscn"
            5: target_scene_path = "res://acts/full_game/intermisions/finals_intermission.tscn"
            6:

                ProgressManager.change_screen(ProgressManager.current_chapter_meta)
                return

        ProgressManager.change_screen(target_scene_path)


func get_puzzle_group_puzzles(group: PuzzleGroup) -> Array[PuzzleMeta]:
    var puzzles: Array[PuzzleMeta] = []

    for child in group.get_children():
        var puzzle_meta: PuzzleMeta = child.get("puzzle_meta")
        if puzzle_meta is PuzzleMeta:
            puzzles.append(puzzle_meta)

    return puzzles


func get_solved_puzzles() -> Array[PuzzleMeta]:
    var puzzles: Array[PuzzleMeta] = []

    for child in get_children():
        if child is PuzzleContainer:
            var puzzle_metas: Array[PuzzleMeta] = get_puzzle_group_puzzles(
                child.puzzle_group as PuzzleGroup
            )
            for puzzle_meta in puzzle_metas:
                if ProgressManager.is_puzzle_solved(puzzle_meta.puzzle_id):
                    puzzles.append(puzzle_meta)

    return puzzles


func is_music_escalated() -> bool:
    return get_solved_puzzles().any(
        func(puzzle: PuzzleMeta) -> bool:
            return puzzle.escalate_music_on_solve
    )


func get_music_escalation_level() -> int:
    var escalation_levels: Array = get_solved_puzzles().map(
        func(puzzle: PuzzleMeta) -> int:
            return puzzle.escalation_level
    )

    if escalation_levels.size():
        return escalation_levels.max()
    else:
        return 0


class ScenarioUIWindow:
    var instance: Control
    var label: String
    var icon: Texture2D
    var puzzles: Array[PuzzleMeta] = []
    var unlocks_items: Array[int] = []
    var sequence_element_id: String
