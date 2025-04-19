extends TextureButton

const COLOR_FOCUS: Color = Color(1.2, 1.2, 1.2)
const COLOR_NOFOCUS: Color = Color.WHITE

var dialog: Control
var unlocked: bool = false
const victory_screen_path_from_hub_path: String = "res://shared/ui/hub/victory_dialog_from_hub.tscn"

@export var scenario_meta: ScenarioMeta


func _ready() -> void :
    if not scenario_meta:
        push_error(name, " is missing scenario meta")
        modulate = Color(1, 0, 0)
        return

    var scenario_id: int = scenario_meta.id
    if ProgressManager.is_scenario_beaten(scenario_id):
        unlocked = true



    if not unlocked:
        visible = false
        return

    elif unlocked:
        visible = true

    modulate = COLOR_FOCUS
    focus_entered.connect(_on_control_focus_changed.bind(true))
    focus_exited.connect(_on_control_focus_changed.bind(false))
    NodeUtils.greedy_focus(self)


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


func _on_pressed() -> void :
    release_focus()
    if len(scenario_meta.custom_hub_victory_dialog_path):
        dialog = load(scenario_meta.custom_hub_victory_dialog_path).instantiate()
    else:
        dialog = load(victory_screen_path_from_hub_path).instantiate()
    ProgressManager.dialog_layer.add_child(dialog)

    dialog.configure(scenario_meta, self)
