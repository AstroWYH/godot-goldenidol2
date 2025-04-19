extends VisibleOnScreenNotifier2D

@export var sound: AudioManager.Sound = AudioManager.Sound.NONE
@export var fade_out_time: float = 8.0
var player_id: int


func _on_screen_entered() -> void :
    if sound and not AudioManager.is_playing(player_id):
        player_id = await AudioManager.play(sound)


func _on_screen_exited() -> void :
    stop_sound()


func _on_tree_exited() -> void :
    stop_sound()


func stop_sound() -> void :
    if player_id:
        AudioManager.stop(player_id, fade_out_time)
