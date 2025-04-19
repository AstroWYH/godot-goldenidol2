@tool
extends Button

@export var button_label: String
@export var texture: Texture
@export var dialog_path: String
@export var text_color: Color = Color(0.125, 0.122, 0.22)
@export var mouse_over_color: Color = Color(0.125, 0.122, 0.22)
@export var remove_this_on_click: Control = null


@onready var label: Label = % Label
@onready var texture_rect: TextureRect = % TextureRect



func _ready() -> void :
    label.text = button_label
    texture_rect.texture = texture
    pressed.connect(_on_pressed)
    label.set("theme_override_colors/font_color", text_color)
    mouse_entered.connect(_on_mouse_entered)
    focus_entered.connect(_on_mouse_entered)
    mouse_exited.connect(_on_mouse_exited)
    focus_exited.connect(_on_mouse_exited)


func _on_pressed() -> void :
    AudioManager.play(AudioManager.Sound.BUTTON_CLICK)
    if len(dialog_path):
        var new_dialog: Control = load(dialog_path).instantiate()
        ProgressManager.dialog_layer.add_child(new_dialog)

    if remove_this_on_click:
        remove_this_on_click.queue_free()


func _on_mouse_entered() -> void :
    label.set("theme_override_colors/font_color", mouse_over_color)
    texture_rect.position.y -= 5
    label.position.y -= 5
    grab_focus()


func _on_mouse_exited() -> void :
    label.set("theme_override_colors/font_color", text_color)
    texture_rect.position.y += 5
    label.position.y += 5
