extends Button

signal remove_confirmed
signal scenario_reset_confirmed

@export var deletes_savegame: bool = false

@onready var dialog_handler: Node = $ConfirmationDialogCaller


func set_mode(deletes_save_on_press: bool) -> void :
    deletes_savegame = deletes_save_on_press
    update_state()


func update_state() -> void :
    if deletes_savegame:
        text = "DELETE_SAVEGAME"
        dialog_handler.prompt_text = "DELETE_SAVEGAME_DIALOG"
        dialog_handler.confirm_button_text = "DELETE_SAVEGAME_DIALOG_CONFIRM"
        if PersistenceManager.savestate_exists():
            disabled = false
            focus_mode = Control.FOCUS_ALL
            mouse_default_cursor_shape = CursorShape.CURSOR_POINTING_HAND
        else:
            disabled = true
            focus_mode = Control.FOCUS_NONE
            mouse_default_cursor_shape = CursorShape.CURSOR_ARROW
    else:
        dialog_handler.prompt_text = "PROMPT_RESET_SCENARIO"
        dialog_handler.confirm_button_text = "CONFIRM_LABEL"
        text = "RESET_SCENARIO_BUTTON"

    dialog_handler.reject_button_text = "CANCEL_BUTTON"


func _unhandled_input(_event: InputEvent) -> void :
    if disabled:
        return
    GamepadUtils.handle_confirm(self, dialog_handler.on_parent_pressed as Callable)


func confirmed() -> void :
    if deletes_savegame:
        PersistenceManager.remove_save_file()
        remove_confirmed.emit()
    else:
        if not ProgressManager.current_scenario_id:
            return

        scenario_reset_confirmed.emit()
        ProgressManager.request_current_scenario_reset()

    update_state()
    AudioManager.play(AudioManager.Sound.SNIPPET_APPEARED_DISCS)
