extends TextureButton




func _on_mouse_entered() -> void :
    modulate = Color(1.2, 1.2, 1.2)


func _on_mouse_exited() -> void :
    modulate = Color(1, 1, 1)
