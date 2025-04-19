@tool
class_name Location
extends Node2D




signal location_change_request(
    new_location_id: int, 
    transition: LocationTransition, 
    sound: AudioManager.TransitionSound
)

enum LocationTransition{
    FADE, 
    PAN_RIGHT, 
    PAN_LEFT, 
    PAN_UP, 
    PAN_DOWN, 
}


@export var location_meta: LocationMeta



@export var focus_node: Control:
    set = set_focus_node


@export var background_offset: bool = true
@export var background_scale: Vector2 = Vector2.ONE

var _background_node: Sprite2D


var hotspot_cache: Array[Hotspot] = []


func _ready() -> void :
    if location_meta and location_meta.background is Texture2D:
        set_background(location_meta.background as Texture2D)

    if Engine.is_editor_hint():
        return

    set_focus_node(focus_node)
    _build_hotspot_tree(self)





func on_navigate_away() -> void :
    pass




func on_navigate_to() -> void :
    pass


func set_background(value: Texture2D) -> void :
    _background_node = Sprite2D.new()
    _background_node.centered = false
    _background_node.texture = value
    _background_node.scale = background_scale

    if background_offset:
        _background_node.position = Constants.BACKGROUND_OFFSET

    add_child(_background_node)
    move_child(_background_node, 0)

func set_focus_node(value: Control) -> void :
    if not HotspotManager:
        focus_node = value
        return

    var hotspot_or_value: = HotspotManager.get_hotspot(value)
    focus_node = hotspot_or_value


func focus_initial_node() -> void :
    if not visible:
        return

    if not focus_node or not focus_node.is_inside_tree():
        return

    if focus_node.focus_mode != Control.FOCUS_ALL:
        return

    focus_node.grab_focus()


func _build_hotspot_tree(root: Node, parent_hotspot: Hotspot = null) -> void :
    for child in root.get_children():
        if child is Hotspot:
            if not focus_node is Control:


                focus_node = child

            if DevTools.active:
                hotspot_cache.append(child)

            (child as Hotspot).location_change_request.connect(
                func(new_id: int, transition: LocationTransition, sound: AudioManager.TransitionSound) -> void :
                    location_change_request.emit(new_id, transition, sound)
            )

            if parent_hotspot:
                parent_hotspot.add_dependent_hotspot(child as Hotspot)

            _build_hotspot_tree(child, child as Hotspot)
        else:
            _build_hotspot_tree(child, parent_hotspot)
