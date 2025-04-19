extends CanvasLayer

signal confirmed
signal closed

var prompt_text: String
var confirm_button_text: String
var reject_button_text: String

@onready var dialog_title: Label = % DialogLabel
@onready var accept_button: Button = % AcceptButton
@onready var reject_button: Button = % RejectButton


func _ready() -> void :
    reject_button.grab_focus()
    dialog_title.text = prompt_text
    accept_button.text = confirm_button_text
    reject_button.text = reject_button_text
    accept_button.pressed.connect(_on_accept_pressed)
    reject_button.pressed.connect(_on_reject_pressed)

    accept_button.gui_input.connect(_on_gui_input_pressed.bind(true))
    reject_button.gui_input.connect(_on_gui_input_pressed.bind(false))

    $ColorRect.gui_input.connect(_on_gui_input)


func _on_gui_input_pressed(_event: InputEvent, confirmed_action: bool) -> void :
    if not GamepadUtils.accept_pressed():
        return

    if confirmed_action:
        call_deferred("_on_accept_pressed")
        return
    else:
        call_deferred("_on_reject_pressed")
        return


func _unhandled_input(_event: InputEvent) -> void :
    if GamepadUtils.back_pressed():
        _on_reject_pressed()


func _on_gui_input(event: InputEvent) -> void :
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                _on_reject_pressed()


func _on_accept_pressed() -> void :
    AudioManager.play(AudioManager.Sound.BUTTON_CLICK)
    confirmed.emit()
    closed.emit()
    queue_free()


func _on_reject_pressed() -> void :
    closed.emit()
    AudioManager.play(AudioManager.Sound.BUTTON_CLICK)
    queue_free()
