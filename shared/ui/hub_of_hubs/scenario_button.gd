extends TextureButton

const COLOR_FOCUS: Color = Color(1.2, 1.2, 1.2)
const COLOR_NOFOCUS: Color = Color.WHITE


@export var scenario_meta: ScenarioMeta
@export var required_puzzles_to_finish: Array[PuzzleMeta]
@export var unfinished_texture: Texture
@export var label_node: Label

var _particle_effect: GPUParticles2D
var _normal_texture: Texture2D

func _ready() -> void :
    pressed.connect(_on_pressed)
    _normal_texture = texture_normal

    if not scenario_meta:
        push_warning("Scenario button without defined scenario meta file")

    if ProgressManager.all_arcs_unlocked:
        visible = true
    else:
        check_availability()

    PersistenceManager.state_loaded.connect(check_availability.unbind(1))
    label_node.hide()


func mark_beaten() -> void :
    if _particle_effect:
        var tween: Tween = _particle_effect.create_tween()
        tween.tween_property(_particle_effect, "modulate", Color.TRANSPARENT, 1)
        tween.finished.connect(_particle_effect.queue_free, CONNECT_ONE_SHOT)
    texture_normal = _normal_texture



func focus_changed(focus_gained: bool) -> void :
    _on_control_focus_changed(focus_gained)



func accept_requested() -> void :
    _on_pressed()


func check_availability() -> void :
    if not ProgressManager.is_scenario_unlocked(scenario_meta.id):
        visible = false
        return

    for puzzle in required_puzzles_to_finish:
        if not ProgressManager.is_puzzle_solved(puzzle.puzzle_id):
            texture_normal = unfinished_texture
            break

    var visited: bool = false
    if scenario_meta.id in ProgressManager.visited_scenarios:
        visited = true

    if not visited:
        scale = Vector2.ZERO
        var tween: = create_tween()
        tween.finished.connect(_on_appear_animation_done)
        tween.tween_property(self, "scale", Vector2(1, 1), 1.5)
        visible = true
    elif visited:
        visible = true


func _on_appear_animation_done() -> void :
    _particle_effect = load("res://shared/ui/special_effects/particle_effect.tscn").instantiate()
    add_child(_particle_effect)
    _particle_effect.position = size / 2
    _particle_effect.process_material.emission_ring_inner_radius = size.y / 2
    _particle_effect.process_material.emission_ring_radius = size.y


func _on_pressed() -> void :
    release_focus()
    ProgressManager.change_screen(scenario_meta)
    AudioManager.play(AudioManager.Sound.BUTTON_CLICK)


func _on_mouse_entered() -> void :
    modulate = COLOR_FOCUS
    $FocusTarget.grab_focus()
    if scenario_meta.id in ProgressManager.visited_scenarios:
        label_node.show()



func _on_mouse_exited() -> void :
    if has_focus():
        return
    modulate = COLOR_NOFOCUS
    label_node.hide()


func _on_control_focus_changed(focus_gained: bool) -> void :
    modulate = COLOR_FOCUS if focus_gained else COLOR_NOFOCUS
