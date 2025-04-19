extends Button

const ScenarioSelectorScene: = preload("res://shared/ui/scenario_select/scenario_select.tscn")


func _on_pressed() -> void :
    ProgressManager.change_screen("res://shared/ui/scenario_select/demo_end_screen.tscn")
