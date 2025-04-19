extends TextureButton

const COLOR_FOCUS: Color = Color(1.2, 1.2, 1.2)
const COLOR_NOFOCUS: Color = Color.WHITE

@export var scenario_meta: ScenarioMeta
@export var dialog_layer: CanvasLayer

var victory_screen_path_from_hub_path: String = "res://shared/ui/hub/victory_dialog_from_hub.tscn"
var dialog: Control
var unlocked: bool = false



func _ready() -> void :
    mouse_entered.connect(_on_mouse_entered)
    mouse_exited.connect(_on_mouse_exited)
    pressed.connect(_on_pressed)

    if not scenario_meta:
        push_error(name, " is missing scenario meta")
        modulate = Color(1, 0, 0)
        return

    check_availability()
    PersistenceManager.state_loaded.connect(check_availability.unbind(1))

    modulate = COLOR_NOFOCUS

    if len(scenario_meta.custom_hub_victory_dialog_path) > 0:
        victory_screen_path_from_hub_path = scenario_meta.custom_hub_victory_dialog_path



func focus_changed(focus_gained: bool) -> void :
    _on_control_focus_changed(focus_gained)



func accept_requested() -> void :
    _on_pressed()


func check_availability() -> void :
    var scenario_id: int = scenario_meta.id
    unlocked = ProgressManager.is_scenario_beaten(scenario_id)
    visible = unlocked


func _on_mouse_entered() -> void :
    modulate = COLOR_FOCUS
    $FocusTarget.grab_focus()


func _on_mouse_exited() -> void :
    if has_focus():
        return
    modulate = COLOR_NOFOCUS


func _on_control_focus_changed(focus_gained: bool) -> void :
    modulate = COLOR_FOCUS if focus_gained else COLOR_NOFOCUS


func _on_pressed() -> void :
    var focus_target: Control = $FocusTarget
    focus_target.release_focus()
    dialog = load(victory_screen_path_from_hub_path).instantiate()
    dialog_layer.add_child(dialog)
    dialog.configure(scenario_meta, focus_target)
