class_name ScenarioHubScreen
extends TextureRect

signal screen_unlocked

enum ScenarioStatus{
    BEATEN, 
    AVAILABLE, 
    DISABLED, 
}

const COLOR_FOCUS: Color = Color(1.1, 1.1, 1.1, 1)
const COLOR_NOFOCUS: Color = Color.WHITE

@export var scenario_meta: ScenarioMeta
@export var available_animation_path: String
@export var finished_animation_path: String
@export var sequence_element_id: String
@export var label_node: Label

@onready var animated_sprite: AnimatedSprite2D = % AnimatedSprite2D
@onready var focus_indicator: TextureRect = % FocusIndicator



var _status: ScenarioStatus = ScenarioStatus.BEATEN:
    set = set_status
var starting_label_pos: Vector2


func _ready() -> void :
    var scenario_id: = scenario_meta.id
    focus_indicator.visible = false
    gui_input.connect(_on_gui_input)
    mouse_entered.connect(_on_mouse_entered)
    mouse_exited.connect(_on_mouse_exited)

    if len(sequence_element_id) and SequenceManager.get_element_state(sequence_element_id) == SequenceManager.ElementState.ACTIVE:
        _status = ScenarioStatus.DISABLED
        animated_sprite.sprite_frames = null

    elif ProgressManager.is_scenario_beaten(scenario_id):
        _status = ScenarioStatus.BEATEN
        animated_sprite.sprite_frames = load(finished_animation_path)
        animated_sprite.play("default")

    elif ProgressManager.is_scenario_unlocked(scenario_id):
        _status = ScenarioStatus.DISABLED

        var scenario_discovery_state: = DiscoveryManager.is_scenario_discovered(scenario_id)
        if scenario_discovery_state == DiscoveryManager.DiscoveryState.UNDISCOVERED:
            await get_tree().create_timer(1).timeout
            AudioManager.play(AudioManager.Sound.SCENARIO_UNLOCKED)
            DiscoveryManager.mark_scenario_discovered(scenario_id)
            screen_unlocked.emit()

        _status = ScenarioStatus.AVAILABLE
        animated_sprite.sprite_frames = load(available_animation_path)
        animated_sprite.play("default")

    else:
        _status = ScenarioStatus.DISABLED
        animated_sprite.sprite_frames = null

    focus_mode = FOCUS_NONE if _status == ScenarioStatus.DISABLED else FOCUS_ALL

    focus_entered.connect(_on_control_focus_changed.bind(true))
    focus_exited.connect(_on_control_focus_changed.bind(false))
    NodeUtils.greedy_focus(self)
    SequenceManager.sequence_element_requested.connect(_on_sequence_element_requested)
    if label_node:
        label_node.hide()


func set_status(v: ScenarioStatus) -> void :
    _status = v
    mouse_default_cursor_shape = CursorShape.CURSOR_ARROW if _status == ScenarioStatus.DISABLED else CursorShape.CURSOR_POINTING_HAND


func _on_sequence_element_requested(seq_el_id: String) -> void :

    if seq_el_id == sequence_element_id:
        await get_tree().create_timer(1).timeout
        AudioManager.play(AudioManager.Sound.SCENARIO_UNLOCKED)
        _status = ScenarioStatus.AVAILABLE
        animated_sprite.sprite_frames = load(available_animation_path)
        animated_sprite.play("default")
        focus_mode = FOCUS_ALL
        SequenceManager.sequence_element_requested.disconnect(_on_sequence_element_requested)
        screen_unlocked.emit()


func _on_gui_input(event: InputEvent) -> void :
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                _change_screen()
    if GamepadUtils.accept_pressed():
        _change_screen()


func _change_screen() -> void :
    if _status == ScenarioStatus.DISABLED:
        return

    release_focus()

    if len(sequence_element_id):
        SequenceManager.mark_handled(sequence_element_id)

    ProgressManager.change_screen(scenario_meta)


func _on_mouse_entered() -> void :
    if not _status == ScenarioStatus.DISABLED:
        modulate = COLOR_FOCUS
        grab_focus()
    if scenario_meta.id in ProgressManager.visited_scenarios and ProgressManager.is_scenario_unlocked(scenario_meta.id):
        if label_node:
            label_node.show()


func _on_mouse_exited() -> void :
    if not _status == ScenarioStatus.DISABLED and not has_focus():
        modulate = COLOR_NOFOCUS
    if label_node:
        label_node.hide()


func _on_control_focus_changed(focus_gained: bool) -> void :
    if (focus_gained):
        DialogManager.set_last_exploration_control(self)

    focus_indicator.visible = focus_gained
    focus_indicator.z_as_relative = not focus_gained
    focus_indicator.z_index = 2 if focus_gained else 0

    modulate = COLOR_FOCUS if focus_gained else COLOR_NOFOCUS
