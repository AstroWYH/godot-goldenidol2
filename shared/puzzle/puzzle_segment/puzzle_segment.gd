extends RefCounted
class_name PuzzleSegment

const PROP_MODULATE: = "modulate"
const ANIM_DURATION: = 1.0


var node: Node
var obscurer: NinePatchRect
var id: int
var obscured: bool = false:
    set = set_obscured


func set_obscured(value: bool) -> void :
    obscured = value
    if obscurer:
        obscurer.visible = value
        obscurer.modulate = Color.WHITE if value else Color.TRANSPARENT




func reveal() -> void :
    obscured = true
    var tween: = obscurer.create_tween()
    tween.tween_property(obscurer, PROP_MODULATE, Color.TRANSPARENT, ANIM_DURATION)
    tween.finished.connect(
        func() -> void :
            obscurer.visible = false, 
        CONNECT_ONE_SHOT, 
    )
