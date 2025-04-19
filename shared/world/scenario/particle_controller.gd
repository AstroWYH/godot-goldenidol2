extends GPUParticles2D


@export var parent_panel: Panel
@export var timer: Timer


func _ready() -> void :
    if parent_panel:
        parent_panel.visibility_changed.connect(_on_parent_visibility_changed)
        parent_panel.item_rect_changed.connect(_on_parent_rect_changed)
        emitting = false
        visible = false
    timer.wait_time = 0.15
    timer.timeout.connect(_on_timer_finished)


func _on_parent_visibility_changed() -> void :
    if not parent_panel.visible:
        visible = false
        restart()
        emitting = false
    else:
        if timer.is_stopped():
            timer.start()


func _on_parent_rect_changed() -> void :
    restart()

func _on_timer_finished() -> void :
    visible = true
    emitting = true
    timer.stop()
