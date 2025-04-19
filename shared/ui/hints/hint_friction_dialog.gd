extends ColorRect

signal unlocked

var hint_id: int = -1
var hint_path: String
var hint_title: String
var breathing_finished: bool = false
var _previous_focus: Control
var _refocus_on_destroy: bool = true

@onready var skip_button: BaseButton = % Button
@onready var breathe_button: Button = % BreatheButton
@onready var player: AnimationPlayer = % AnimationPlayer


func _ready() -> void :
    gui_input.connect(_on_gui_input)
    _previous_focus = get_viewport().gui_get_focus_owner()
    skip_button.pressed.connect(_on_skip_pressed)
    breathe_button.pressed.connect(on_breathe_pressed)
    breathe_button.mouse_entered.connect(_on_breathe_mouse_entered)
    breathe_button.grab_focus()
    player.animation_finished.connect(on_breathing_done)
    player.current_animation = "breathing"
    player.seek(0, true)
    player.pause()


func _unhandled_input(_event: InputEvent) -> void :
    if GamepadUtils.back_pressed():
        get_viewport().set_input_as_handled()
        queue_free()
        return


func _exit_tree() -> void :
    AudioManager.stop_sound(AudioManager.Sound.HINT_BREATHE)
    MusicPlayer.restore_mix(2.0)
    if is_instance_valid(_previous_focus) and _previous_focus is Control and _refocus_on_destroy:
        _previous_focus.grab_focus()


func _on_gui_input(event: InputEvent) -> void :
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                queue_free()


func on_breathe_pressed() -> void :
    AudioManager.play(AudioManager.Sound.BUTTON_CLICK)
    if not breathing_finished:
        AudioManager.play(AudioManager.Sound.HINT_BREATHE)
        MusicPlayer.attenuate_mix(-18, 4.0)
        % BackButton.grab_focus()
        player.play("breathing")
        breathe_button.visible = false
    else:
        grant_hint()


func _on_skip_pressed() -> void :
    AudioManager.play(AudioManager.Sound.BUTTON_CLICK)
    grant_hint()


func on_breathing_done(_animation: String) -> void :
    MusicPlayer.restore_mix(2.0)
    breathe_button.visible = true
    breathe_button.text = tr("RECEIVE_HINT_BUTTON")
    breathing_finished = true


func grant_hint() -> void :
    unlocked.emit()
    ProgressManager.unlock_hint(hint_id)
    var new_dialog: Control = load(hint_path).instantiate()
    new_dialog.title = hint_title



    _refocus_on_destroy = false
    new_dialog.previous_focus = _previous_focus

    ProgressManager.dialog_layer.add_child(new_dialog)
    queue_free()


func _on_breathe_mouse_entered() -> void :
    grab_focus()
