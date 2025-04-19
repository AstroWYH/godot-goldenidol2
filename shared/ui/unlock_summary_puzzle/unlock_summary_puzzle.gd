extends HBoxContainer

@export var puzzle_meta: PuzzleMeta


func _ready() -> void :
    ($Icon as TextureRect).texture = puzzle_meta.puzzle_icon


func update_texture() -> void :
    ($Icon as TextureRect).texture = puzzle_meta.puzzle_icon
