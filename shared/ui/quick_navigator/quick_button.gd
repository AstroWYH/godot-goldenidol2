extends Button

var available: bool = false

signal screen_change_called


@export var arc_meta: ArcMeta
@export var scenario_meta: ScenarioMeta


func _ready() -> void :
    visible = false

    if arc_meta:
        text = arc_meta.name
        if ProgressManager.current_arc_id == arc_meta.id and not ProgressManager.current_scenario:
            disabled = true

        if ProgressManager.arc_visited(arc_meta.id):
            available = true
        else:
            available = false
            return
    elif scenario_meta:
        text = scenario_meta.name
        if ProgressManager.current_scenario_id == scenario_meta.id:
            disabled = true
        if ProgressManager.scenario_visited(scenario_meta.id):
            available = true
        else:
            available = false
            return

    pressed.connect(on_pressed)
    mouse_entered.connect(on_mouse_entered)
    mouse_exited.connect(on_mouse_exited)


func on_pressed() -> void :
    AudioManager.play(AudioManager.Sound.BUTTON_CLICK)

    screen_change_called.emit()
    if arc_meta:
        ProgressManager.change_screen(arc_meta)
        return
    elif scenario_meta:
        ProgressManager.change_screen(scenario_meta)
        return


func on_mouse_entered() -> void :
    if disabled:
        return
    position.y -= 3
    modulate = Color(1.2, 1.2, 1.2, 1)


func on_mouse_exited() -> void :
    if disabled:
        return
    position.y += 3
    modulate = Color(1, 1, 1, 1)
