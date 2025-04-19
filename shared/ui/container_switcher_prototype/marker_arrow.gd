extends Control


func _ready() -> void :
    visible = false
    animate_forward()


func animate_forward() -> void :
    var tween: = create_tween()
    tween.tween_property(self, "position", position + Vector2(0, 10), 0.5)
    tween.finished.connect(animate_back)


func animate_back() -> void :
    var tween: = create_tween()
    tween.tween_property(self, "position", position + Vector2(0, -10), 0.5)
    tween.finished.connect(animate_forward)
