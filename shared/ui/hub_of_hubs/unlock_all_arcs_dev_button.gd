extends CheckButton

@export var arc_container: Control
@export var scenario_container: Array[Control]

func _ready() -> void :
    toggled.connect(_on_toggled)
    set_pressed_no_signal(ProgressManager.all_arcs_unlocked)


func _on_toggled(_pressed: bool) -> void :
    ProgressManager.all_arcs_unlocked = _pressed

    for button in scenario_container:
        if _pressed:
            button.visible = true
        else:
            if button.has_method("check_availability"):
                button.check_availability()
