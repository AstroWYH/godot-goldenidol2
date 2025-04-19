extends TextureButton

const ANIM_APPEAR: = "appear"

const COLOR_FOCUS: Color = Color(1.2, 1.2, 1.2)
const COLOR_NOFOCUS: Color = Color.WHITE

var snippet: Control
var unlocked: bool = false

@export var snippet_path: String
@export var scenario_meta: ScenarioMeta
@export var sequence_element_id: String
@export var unlocks_segments_on_click: Array[PuzzleSegmentUnlock] = []
@export var sound: AudioManager.SnippetSound = AudioManager.SnippetSound.NONE
@export var id: int = -1

var _particle_effect: GPUParticles2D



@export var sprite: Node2D

@onready var player: AnimationPlayer = $AnimationPlayer


func _ready() -> void :
    if not scenario_meta:
        push_error(name, " is missing scenario meta")
        modulate = Color(1, 0, 0)
        return

    var scenario_id: int = scenario_meta.id

    SequenceManager.sequence_element_requested.connect(_on_sequence_element_requested)

    if len(sequence_element_id):
        var element_state: = SequenceManager.get_element_state(sequence_element_id)
        if element_state == SequenceManager.ElementState.ACTIVE:

            unlocked = false
        elif element_state == SequenceManager.ElementState.HEAD:

            unlocked = true
        elif ProgressManager.is_scenario_beaten(scenario_id):

            unlocked = true
    elif ProgressManager.is_scenario_beaten(scenario_id):
        unlocked = true

    if not unlocked:
        visible = false
        return

    elif unlocked:
        visible = true
        play_appear_animation()

    modulate = COLOR_NOFOCUS
    focus_entered.connect(_on_control_focus_changed.bind(true))
    focus_exited.connect(_on_control_focus_changed.bind(false))
    NodeUtils.greedy_focus(self)


func play_appear_animation() -> void :
    if not id in ProgressManager.snippets_visited:
        player.play(ANIM_APPEAR)
        player.animation_finished.connect(_on_appear_animation_done)



func _on_mouse_entered() -> void :
    modulate = COLOR_FOCUS
    grab_focus()


func _on_mouse_exited() -> void :
    if has_focus():
        return
    modulate = COLOR_NOFOCUS


func _on_control_focus_changed(focus_gained: bool) -> void :
    if (focus_gained):
        DialogManager.set_last_exploration_control(self)
    modulate = COLOR_FOCUS if focus_gained else COLOR_NOFOCUS
    if sprite:
        sprite.modulate = COLOR_FOCUS if focus_gained else COLOR_NOFOCUS


func _on_pressed() -> void :
    release_focus()
    snippet = load(snippet_path).instantiate()
    if snippet.get("sequence_element_id") is String:
        snippet.sequence_element_id = sequence_element_id

    snippet.tree_exiting.connect(
        func() -> void :



            if not get_viewport().gui_get_focus_owner():
                grab_focus()
            , 
        CONNECT_ONE_SHOT, 
    )

    if len(unlocks_segments_on_click):
        for unlock: PuzzleSegmentUnlock in unlocks_segments_on_click:
            ProgressManager.unlock_puzzle_segments(
                unlock.puzzle_meta.puzzle_id, 
                unlock.segment_indices, 
            )

    AudioManager.play_snippet(sound)
    get_parent().add_child(snippet)
    if _particle_effect:
        _particle_effect.restart()
        _particle_effect.queue_free()
        _particle_effect = null
    if not id in ProgressManager.snippets_visited:
        ProgressManager.snippets_visited.append(id)
        ProgressManager.save_visited_snippets()


func _on_sequence_element_requested(seq_el_id: String) -> void :
    if seq_el_id == sequence_element_id:

        visible = true
        play_appear_animation()
        SequenceManager.sequence_element_requested.disconnect(_on_sequence_element_requested)


func _on_appear_animation_done(_anim_name: String) -> void :
    _particle_effect = load("res://shared/ui/special_effects/particle_effect.tscn").instantiate()
    add_child(_particle_effect)
    _particle_effect.position = size / 2
    _particle_effect.process_material.emission_ring_inner_radius = size.y / 2
    _particle_effect.process_material.emission_ring_radius = size.y
