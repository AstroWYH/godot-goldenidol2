extends VBoxContainer

const DynamicPuzzleLine: = preload("res://shared/ui/dynamic_puzzle/dynamic_puzzle_line/dynamic_puzzle_line.tscn")

@export var dynamic_puzzle_tree: DynamicPuzzleTree


func _ready() -> void :
    if not dynamic_puzzle_tree:
        return

    for child in dynamic_puzzle_tree.root.children:
        var child_line: = DynamicPuzzleLine.instantiate()
        child_line.dynamic_puzzle_node = child
        add_child(child_line)
