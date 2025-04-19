class_name PhraseSlotButton
extends Button

signal global_transform_changed
signal focus_mode_requested(focus_mode: Control.FocusMode)


func _notification(what: int) -> void :
    if what != NOTIFICATION_TRANSFORM_CHANGED:
        return
    global_transform_changed.emit()



func request_focus_mode(new_focus_mode: Control.FocusMode) -> void :
    focus_mode_requested.emit(new_focus_mode)


func raise() -> void :
    z_index = 10 if ThinkingWindow.can_raise(self) else 0


func lower() -> void :


    z_index = 0
