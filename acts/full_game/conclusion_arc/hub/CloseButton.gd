extends Button



func _ready() -> void :
    pressed.connect(_on_pressed)



func _on_pressed() -> void :
    get_parent().queue_free()
