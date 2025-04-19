extends Button

signal fast_forwarded

func _ready() -> void :
    if not ProgressManager.fast_forward_available():
        queue_free()
        return


func confirmed() -> void :
    PersistenceManager.fast_forward()
    fast_forwarded.emit()
    queue_free()
