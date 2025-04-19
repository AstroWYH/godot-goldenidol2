extends TextureRect

const outline_material = preload("res://shared/ui/container_switcher_prototype/assets/outline.material")


func _ready() -> void :
    if get_parent() is Hotspot:
        get_parent().mouse_entered.connect(_on_mouse_entered)
        get_parent().mouse_exited.connect(_on_mouse_exited)


func _on_mouse_entered() -> void :
    modulate = Color(1, 1, 0.5)


func _on_mouse_exited() -> void :
    modulate = Color(1, 1, 1)
