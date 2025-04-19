class_name CustomSegment
extends Control









const ANIM_REVEAL: = "reveal"

var id: int = 0
var obscured: bool = false:
    set = set_obscured
var host: Node
var _initial_mouse_filter: MouseFilter

@onready var segment_block: NinePatchRect = % SegmentBlock
@onready var animation_player: AnimationPlayer = % AnimationPlayer


func _ready() -> void :
    host = get_parent()
    if host is Control:
        _initial_mouse_filter = host.mouse_filter
    set_obscured(obscured)
    _update_obscurer_size()


func set_obscured(value: bool) -> void :
    obscured = value

    if host:
        if host is Control:

            host.mouse_filter = MOUSE_FILTER_STOP if value else _initial_mouse_filter

    if segment_block:
        segment_block.visible = value


func reveal() -> void :
    if animation_player.is_playing():
        return

    if not obscured:
        obscured = true

    animation_player.play(ANIM_REVEAL)
    animation_player.animation_finished.connect(
        func(_anim: String) -> void :
            segment_block.queue_free()
            segment_block = null, 
        CONNECT_ONE_SHOT, 
    )


func _update_obscurer_size() -> void :
    if not host or not segment_block:
        return

    segment_block.size = host.size
    segment_block.global_position = host.global_position
    segment_block.custom_minimum_size = host.custom_minimum_size
