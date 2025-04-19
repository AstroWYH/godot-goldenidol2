@icon("res://shared/assets/icons/puzzle.png")
class_name PuzzleMeta
extends Resource



enum SegmentationMode{

    NONE, 


    PUZZLE_DEFAULT, 


    OBSCURE_ALL, 


    SPECIFY, 
}




@export var puzzle_id: int = 0
@export var puzzle_name: String
@export var puzzle_icon: Texture2D
@export var arc_puzzle: = false

@export var locked_by_default: = true
@export var hide_card_when_locked: = false
@export var unlocks_puzzles_on_solve: Array[PuzzleMeta] = []
@export var unlocks_segments_on_solve: Array[PuzzleSegmentUnlock] = []
@export var escalate_music_on_solve: bool = false
@export var escalation_level: int = 0


@export_group("Segments")
@export var segmentation_mode: SegmentationMode = SegmentationMode.NONE

@export var specified_segments: Array[int] = []

var puzzle: Control
