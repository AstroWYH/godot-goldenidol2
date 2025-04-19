@tool
extends Control
class_name HubScenario

signal mouse_on(scenario_meta: ScenarioMeta)
signal mouse_off(scenario_meta: ScenarioMeta)
signal scenario_load_requested(scenario_meta: ScenarioMeta)

enum ScenarioStatus{
    BEATEN, 
    AVAILABLE, 
    DISABLED, 
}

const ANIM_DEFAULT: = "default"
const ANIM_COLOUR: = "colour"
const ANIM_BW: = "bw"
const COLOR_MOUSEOFF: = Color8(180, 180, 180, 255)
const COLOR_DISABLED: = Color8(70, 70, 70, 255)

@export var scenario_meta: ScenarioMeta
@export var texture: Texture2D:
    set = set_texture
@export var animation: AnimatedSprite2D
@export var sequence_element_id: String

var loading: bool = false
var _status: ScenarioStatus:
    set = _set_status

@onready var texture_button: TextureButton = % TextureButton
@onready var highlighter: AnimatedSprite2D = % Highlighter
@onready var solved_icon: TextureRect = % SolvedIcon


func _ready() -> void :
    highlighter.play(ANIM_DEFAULT)
    texture_button.texture_normal = texture
    texture_button.modulate = COLOR_MOUSEOFF

    if not scenario_meta:
        return

    var s_id: = scenario_meta.id

    if Engine.is_editor_hint():
        return

    focus_mode = FOCUS_ALL
    if len(sequence_element_id) and SequenceManager.get_element_state(sequence_element_id) == SequenceManager.ElementState.ACTIVE:
        _status = ScenarioStatus.DISABLED
        animation.visible = false
    elif ProgressManager.is_scenario_beaten(s_id):
        _status = ScenarioStatus.BEATEN
        animation.visible = true
        animation.play(ANIM_COLOUR)
    elif ProgressManager.is_scenario_unlocked(s_id):
        _status = ScenarioStatus.DISABLED
        animation.visible = false

        var scenario_discovery_state: = DiscoveryManager.is_scenario_discovered(s_id)
        if scenario_discovery_state == DiscoveryManager.DiscoveryState.UNDISCOVERED:
            await get_tree().create_timer(1).timeout
            AudioManager.play(AudioManager.Sound.SCENARIO_UNLOCKED)
            DiscoveryManager.mark_scenario_discovered(s_id)

        _status = ScenarioStatus.AVAILABLE
        animation.visible = true
        animation.play(ANIM_BW)

    else:
        _status = ScenarioStatus.DISABLED
        animation.visible = false

    SequenceManager.sequence_element_requested.connect(_on_sequence_element_requested)

    focus_entered.connect(_on_control_focus_changed.bind(true))
    focus_exited.connect(_on_control_focus_changed.bind(false))
    NodeUtils.greedy_focus(self)


func set_texture(t: Texture2D) -> void :
    texture = t
    if texture_button and t is Texture2D:
        texture_button.texture_normal = t


func _on_mouse_entered() -> void :
    _on_texture_button_mouse_entered()


func _on_mouse_exited() -> void :
    _on_texture_button_mouse_exited()


func _on_control_focus_changed(focus_gained: bool) -> void :
    if focus_gained:
        _on_texture_button_mouse_entered()
        return
    _on_texture_button_mouse_exited()


func _on_gui_input(event: InputEvent) -> void :
    if GamepadUtils.accept_pressed():
        _on_texture_button_pressed()
        return

    if not event is InputEventMouseButton:
        return

    var button_event: InputEventMouseButton = event

    if button_event.button_index != MOUSE_BUTTON_LEFT:
        return

    if not button_event.pressed:
        return

    _on_texture_button_pressed()


func _on_texture_button_pressed() -> void :
    if loading or _status == ScenarioStatus.DISABLED:
        return

    if len(sequence_element_id):
        SequenceManager.mark_handled(sequence_element_id)

    scenario_load_requested.emit(scenario_meta)
    get_viewport().set_input_as_handled()
    _set_selected(false)
    release_focus()


func _on_texture_button_mouse_exited() -> void :
    mouse_off.emit(scenario_meta)
    if has_focus():
        return
    _set_selected(false)


func _on_texture_button_mouse_entered() -> void :
    if loading:
        return

    mouse_on.emit(scenario_meta)

    if _status != ScenarioStatus.DISABLED:
        _set_selected(true)


func _set_selected(is_selected: bool) -> void :
    texture_button.modulate = Color.WHITE if is_selected else COLOR_MOUSEOFF


func _set_status(new_status: ScenarioStatus) -> void :
    _status = new_status

    if new_status == ScenarioStatus.DISABLED:
        focus_mode = FOCUS_NONE

    else:
        focus_mode = FOCUS_ALL


    if solved_icon:
        if new_status == ScenarioStatus.BEATEN:
            solved_icon.show()
        else:
            solved_icon.hide()


func _on_sequence_element_requested(seq_el_id: String) -> void :

    if seq_el_id == sequence_element_id:
        _status = ScenarioStatus.AVAILABLE
        animation.visible = true
        animation.play(ANIM_BW)
        SequenceManager.sequence_element_requested.disconnect(_on_sequence_element_requested)
