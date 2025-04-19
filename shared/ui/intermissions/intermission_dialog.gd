extends ColorRect
class_name IntermissionDialog

@export var intermission_id: int
@export var video_length: float
@export var music_layers: Array[AudioStream]
@export var return_screen_meta: ArcMeta


@onready var video_player: VideoStreamPlayer = % VideoStreamPlayer
@onready var replay_button: Button = % ReplayButton
@onready var close_button: Button = % CloseButton
@onready var timer: Timer = % Timer


func _ready() -> void :
    close_button.pressed.connect(_on_close_pressed)
    replay_button.pressed.connect(_on_replay_pressed)
    gui_input.connect(_on_gui_input)
    replay_button.visible = false
    close_button.visible = false
    timer.timeout.connect(_on_timer_stopped)
    timer.wait_time = video_length - 1
    timer.start()
    video_player.play()

    play_audio()

    if not intermission_id in ProgressManager.intermissions_shown:
        ProgressManager.save_intermission_shown(intermission_id)


func _on_close_pressed() -> void :
    AudioManager.play(AudioManager.Sound.BUTTON_CLICK)

    if return_screen_meta:
        ProgressManager.change_screen(return_screen_meta)
        return
    else:
        ProgressManager.change_screen("res://shared/ui/hub_of_hubs/hub_of_hubs.tscn")


func _on_replay_pressed() -> void :
    AudioManager.play(AudioManager.Sound.BUTTON_CLICK)
    replay_button.visible = false
    close_button.visible = false
    timer.wait_time = video_length - 1
    timer.start()
    video_player.paused = false
    video_player.stop()
    video_player.play()

    var animation_player: AnimationPlayer = get_node("AnimationPlayer")

    if animation_player:
        animation_player.stop()
        animation_player.seek(0, true)
        animation_player.play()

    play_audio()


func _on_timer_stopped() -> void :
    video_player.paused = true
    _reveal_ui()


func _unhandled_input(_event: InputEvent) -> void :
    if (GamepadUtils.accept_pressed() or GamepadUtils.back_pressed()) and not _is_ui_revealed():
        _reveal_ui()
        get_viewport().set_input_as_handled()


func _on_gui_input(event: InputEvent) -> void :
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                _reveal_ui()


func _reveal_ui() -> void :
    replay_button.visible = true
    close_button.visible = true
    close_button.grab_focus()


func _is_ui_revealed() -> bool:
    return replay_button.visible and close_button.visible


func play_audio() -> void :

    await get_tree().process_frame
    AudioManager.stop_all(1.0)
    MusicPlayer.play_bg_audio(music_layers, [], true)
    MusicPlayer.restore_gain()


func stop_audio() -> void :
    MusicPlayer.stop(MusicPlayer.PlayerGroup.MUSIC, 1.0)
