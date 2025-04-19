extends MarginContainer

@export var allowed_scenario_metas: Array[ScenarioMeta]



func _ready() -> void :
    visible = false
    for scenario in allowed_scenario_metas:
        if ProgressManager.current_scenario_id == scenario.id:
            visible = true
            break
