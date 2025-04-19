extends ThinkingWindow
class_name InventoryDialog

signal active_changed(state: bool)

var selected: bool = true
var active: bool = false:
    set = set_active

@onready var scenario_inventory: Control = % ScenarioInventory


func _ready() -> void :
    SettingsManager.ui_scale_changed.connect(_on_ui_scale_changed)


func request_state_change(_open: bool, new_y_pos: float) -> void :
    position.y = new_y_pos


func request_focus(side: Constants.FocusSide) -> void :
    scenario_inventory.request_focus(side)


func _on_close_button_pressed() -> void :
    close_pressed.emit()
    AudioManager.play(AudioManager.Sound.BUTTON_CLICK)


func set_active(state: bool) -> void :
    active = state
    active_changed.emit(state)


func _on_ui_scale_changed(ui_scale: Vector2) -> void :
    if visible:
        scale = ui_scale
