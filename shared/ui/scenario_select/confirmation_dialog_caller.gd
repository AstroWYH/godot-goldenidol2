extends Node

const ConfirmationDialogScene: PackedScene = preload("res://shared/ui/confirmation_dialog/confirmation_dialog.tscn")
@export_multiline var prompt_text: String
@export var confirm_button_text: String
@export var reject_button_text: String

@onready var parent: Button = get_parent()


func _ready() -> void :
    if parent is Button:
        parent.pressed.connect(on_parent_pressed)


func on_parent_pressed() -> void :
    var dialog: CanvasLayer = ConfirmationDialogScene.instantiate()
    dialog.prompt_text = prompt_text
    dialog.confirm_button_text = confirm_button_text
    dialog.reject_button_text = reject_button_text
    dialog.closed.connect(_on_dialog_closed, CONNECT_ONE_SHOT)
    get_tree().root.add_child(dialog)
    dialog.confirmed.connect(parent.confirmed)
    AudioManager.play(AudioManager.Sound.BUTTON_CLICK)


func _on_dialog_closed() -> void :
    if parent.focus_mode == Control.FOCUS_NONE:
        return
    parent.grab_focus()
