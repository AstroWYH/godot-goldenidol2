extends "res://shared/ui/location_button/location_change_button.gd"


@export var december_17_buttons: Array[LocationButton] = []


func _ready() -> void :
    super ()
    ProgressManager.puzzle_solved.connect(_on_puzzle_solved)



func _on_puzzle_solved(_puzzle_meta: PuzzleMeta) -> void :


    for button in december_17_buttons:
        if button.visible:
            focus_neighbor_left = button.get_path()
