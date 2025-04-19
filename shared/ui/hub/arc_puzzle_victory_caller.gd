extends Control

var dialog: Node

@export var puzzle: Control
@export var dialog_path: String

const PMConstants: = preload("res://autoload/persistence_manager/constants.gd")


func _ready() -> void :
    if puzzle:
        puzzle.solved_and_updated.connect(show_dialog)


func show_dialog() -> void :
    if PersistenceManager.state[PMConstants.GameStateKey.DEMO_ENDING_SHOWN]:
        return

    PersistenceManager.state[PMConstants.GameStateKey.DEMO_ENDING_SHOWN] = true

    ProgressManager.change_screen("res://shared/ui/scenario_select/demo_end_screen_zero.tscn")
