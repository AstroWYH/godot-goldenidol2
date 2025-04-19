extends TextureButton


var button_sprite: Sprite2D
@onready var selected_shader: = preload("res://shared/ui/container_switcher_prototype/assets/outline.material")


func _ready() -> void :
    button_sprite = get_child(0)
    toggled.connect(set_selected)
    mouse_entered.connect(set_hover)
    mouse_exited.connect(unset_hover)


func set_selected(selected: bool) -> void :
    if selected:
        button_sprite.set_material(selected_shader)
    else:
        button_sprite.set_material(null)


func set_hover() -> void :
    modulate = Color("#ffc100")


func unset_hover() -> void :
    modulate = Color("#ffffff")
