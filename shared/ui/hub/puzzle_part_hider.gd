class_name PuzzlePartHider
extends NinePatchRect

signal revealed

const ANIM_REVEAL: = "reveal"
const PuzzleSegmentState: RefCounted = preload("res://shared/ui/containers/puzzle_segment_state.gd")

@export var puzzle_metas: Array[PuzzleMeta]

var _anim_in_progress: = false
var _reveal_sound: AudioManager.Sound = AudioManager.Sound.PUZZLE_PART_REVEALED

@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void :
    if PuzzleSegmentState.is_segment_revealed(name):

        revealed.emit()
        queue_free()
        return





func check_if_unlocked() -> bool:
    var everything_unlocked: bool = true
    for meta in puzzle_metas:
        if not ProgressManager.is_puzzle_solved(meta.puzzle_id):
            everything_unlocked = false
            break
    return everything_unlocked


func is_segment_revealed() -> bool:
    return PuzzleSegmentState.is_segment_revealed(name)


func will_animate() -> bool:
    return check_if_unlocked() and not is_segment_revealed()


func check_unlocking() -> void :
    if _anim_in_progress:
        return

    if check_if_unlocked():
        if is_segment_revealed():

            revealed.emit()
            queue_free()
            return
        _reveal()


func _reveal() -> void :
    if _anim_in_progress:
        return
    _anim_in_progress = true

    animation_player.play(ANIM_REVEAL)
    PuzzleSegmentState.reveal_segment(name)
    animation_player.animation_finished.connect(
        func(_anim: String) -> void : queue_free(), 
        CONNECT_ONE_SHOT, 
    )

    if not AudioManager.is_playing_sound(_reveal_sound):
        AudioManager.play(_reveal_sound)



    revealed.emit()
