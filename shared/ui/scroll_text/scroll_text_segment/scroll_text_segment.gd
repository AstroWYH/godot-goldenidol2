@tool
extends Control

const ANIM_REVEAL: = "reveal"

@export var id: int = 0

var obscured: bool = false:
    set = set_obscured
var _queue: Array[Node] = []
var _segments_sized: bool = false
var _reveal_sound: AudioManager.Sound = AudioManager.Sound.PUZZLE_PART_REVEALED

@onready var flow_container: FlowContainer = % FlowContainer
@onready var mouse_blocker: ColorRect = % MouseBlocker
@onready var segment_block: NinePatchRect = % SegmentBlock
@onready var animation_player: AnimationPlayer = % AnimationPlayer
@onready var layout_detacher: Control = % DetachFromContainerLayout


func _ready() -> void :
    for node in _queue:
        flow_container.add_child(node)
    _queue = []
    set_obscured(obscured)


func add_text(text_node: CanvasItem) -> void :
    if not flow_container:
        _queue.append(text_node)
        return
    flow_container.add_child(text_node)


func get_all_slots() -> Array:
    if not flow_container:
        return []

    var slots: Array = []

    for node: Control in flow_container.get_children():
        if node is PhraseSlot:
            slots.append((node as PhraseSlot).get_slot_node())

    return slots


func set_obscured(value: bool) -> void :
    obscured = value

    if not mouse_blocker or not segment_block:
        return

    var el: Array[CanvasItem] = [
        mouse_blocker, 
        segment_block, 
        layout_detacher, 
    ]

    for e in el:
        e.visible = value

    for child in flow_container.get_children():
        if child is PhraseSlot:
            (child as PhraseSlot).obscured = value


func reveal() -> void :
    if animation_player.is_playing():
        return
    animation_player.play(ANIM_REVEAL)
    for child in flow_container.get_children():
        if child is PhraseSlot:
            (child as PhraseSlot).obscured = false
    animation_player.animation_finished.connect(
        func(_anim: String) -> void :
            mouse_blocker.queue_free()
            mouse_blocker = null
            segment_block.queue_free()
            segment_block = null
            layout_detacher.queue_free()
            layout_detacher = null
            , 
        CONNECT_ONE_SHOT, 
    )

    if not AudioManager.is_playing_sound(_reveal_sound):
        AudioManager.play(_reveal_sound)


func _set_seg_block_size() -> void :
    var extent: int = 20
    var double_extent: int = extent * 2
    segment_block.size = flow_container.size + Vector2(double_extent, double_extent)
    segment_block.position = Vector2.ZERO - Vector2(extent, extent)



func _on_flow_container_resized() -> void :
    if flow_container.size.y == 0 or flow_container.size.x == 0:
        return
    if _segments_sized:
        return
    call_deferred("_set_seg_block_size")
    _segments_sized = true


func resize_flow_container() -> void :
    if flow_container.size.y == 0 or flow_container.size.x == 0:
        return
    if _segments_sized:
        return
    call_deferred("_set_seg_block_size")
    _segments_sized = true
