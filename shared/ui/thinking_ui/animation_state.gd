extends RefCounted

const ANIMATION_TIME: float = 0.1
static  var animating: bool = false


static func mark_as_animating(caller: Node) -> void :
    animating = true
    caller.create_tween()\
.tween_callback(func() -> void : unmark_animating())\
.set_delay(ANIMATION_TIME)


static func unmark_animating() -> void :
    animating = false
