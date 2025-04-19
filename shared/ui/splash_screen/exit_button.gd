extends Button


@onready var dialog_handler: Node = $ConfirmationDialogCaller


func _ready() -> void :
    mouse_entered.connect(_on_mouse_entered)


func _unhandled_input(_event: InputEvent) -> void :
    if disabled:
        return
    GamepadUtils.handle_confirm(self, dialog_handler.on_parent_pressed as Callable)


func confirmed() -> void :
    var tree: SceneTree = get_tree()
    tree.root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
    tree.quit()


func _on_mouse_entered() -> void :
    if focus_mode != FOCUS_ALL:
        return
    grab_focus()
