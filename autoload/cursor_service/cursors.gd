extends RefCounted

enum CursorType{
    DEFAULT, 
    ACTIVE, 
    CLOSEUP_CLICKED, 
    LOCATION_CHANGE, 
    LOOK, 
}

const RES_CURSOR_DEFAULT: Array[Resource] = [preload("res://shared/assets/cursors/cursornormal.png")]
const RES_CURSOR_ACTIVE: Array[Resource] = [preload("res://shared/assets/cursors/active_mouse.png")]
const RES_CLOSEUP_CLICKED: Array[Resource] = [
    preload("res://shared/assets/cursors/cursorhotspot.png"), 
]
const RES_LOCATION_CHANGE: Array[Resource] = [
    preload("res://shared/assets/cursors/changelocation.png"), 

]
const RES_LOOK: Array[Resource] = [
    preload("res://shared/assets/cursors/cursorhotspot.png"), 
]

static  var cursor_map: = {
    CursorType.DEFAULT: Cursor.new(CursorType.DEFAULT, RES_CURSOR_DEFAULT), 
    CursorType.ACTIVE: Cursor.new(CursorType.ACTIVE, RES_CURSOR_ACTIVE), 
    CursorType.CLOSEUP_CLICKED: Cursor.new(CursorType.CLOSEUP_CLICKED, RES_CLOSEUP_CLICKED, 5), 
    CursorType.LOCATION_CHANGE: Cursor.new(CursorType.LOCATION_CHANGE, RES_LOCATION_CHANGE, 5, Vector2(13, 4)), 
    CursorType.LOOK: Cursor.new(CursorType.LOOK, RES_LOOK, 1, Vector2(2, 2)), 
}


class Cursor:
    var type: CursorType
    var fps: int
    var resources: Array[Resource]
    var hotspot: Vector2


    func _init(t: CursorType, res: Array[Resource], cursor_fps: int = 10, cursor_hotspot: Vector2 = Vector2(0, 0)) -> void :
        type = t
        resources = res
        fps = cursor_fps
        hotspot = cursor_hotspot
