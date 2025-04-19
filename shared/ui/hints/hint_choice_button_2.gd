@tool
extends Button


@export var locked_texture: Texture
@export var unlocked_texture: Texture
@export var dialog_path: String
@export var text_unlocked_color: Color = Color(0.125, 0.122, 0.22)
@export var mouse_over_unlocked_color: Color = Color(0.212, 0.208, 0.351)
@export var text_locked_color: Color = Color(0.675, 0.196, 0.196)
@export var mouse_over_locked_color: Color = Color(0.801, 0.256, 0.252)

var locked: bool = true
var hint_title: String
var hint_path: String
var hint_id: int

@onready var label: Label = % Label
@onready var texture_rect: TextureRect = % TextureRect


func _ready() -> void :
    label.text = hint_title

    if hint_id in ProgressManager.unlocked_hints:
        locked = false
    else:
        locked = true
    set_locked_visual()

    pressed.connect(_on_pressed)
    mouse_entered.connect(_on_mouse_entered)
    focus_entered.connect(_on_mouse_entered)
    mouse_exited.connect(_on_mouse_exited)
    focus_exited.connect(_on_mouse_exited)


func set_locked_visual() -> void :
    if locked:
        label.set("theme_override_colors/font_color", text_locked_color)
        texture_rect.texture = locked_texture
    else:
        label.set("theme_override_colors/font_color", text_unlocked_color)
        texture_rect.texture = unlocked_texture


func _on_pressed() -> void :
    AudioManager.play(AudioManager.Sound.BUTTON_CLICK)
    if len(hint_path):
        var new_dialog: Control = null
        if locked:
            new_dialog = load("res://shared/ui/hints/hint_friction_dialog.tscn").instantiate()
            new_dialog.hint_id = hint_id
            new_dialog.hint_path = hint_path
            new_dialog.hint_title = hint_title
            new_dialog.unlocked.connect(_update_to_unlocked)
        else:
            new_dialog = load(hint_path).instantiate()
            new_dialog.title = hint_title

        ProgressManager.dialog_layer.add_child(new_dialog)


func _update_to_unlocked() -> void :
    locked = false
    set_locked_visual()


func _on_mouse_entered() -> void :
    if locked:
        label.set("theme_override_colors/font_color", mouse_over_locked_color)
    else:
        label.set("theme_override_colors/font_color", mouse_over_unlocked_color)
    texture_rect.position.y -= 5
    label.position.y -= 5
    grab_focus()


func _on_mouse_exited() -> void :
    if locked:
        label.set("theme_override_colors/font_color", text_locked_color)
    else:
        label.set("theme_override_colors/font_color", text_unlocked_color)
    texture_rect.position.y += 5
    label.position.y += 5
