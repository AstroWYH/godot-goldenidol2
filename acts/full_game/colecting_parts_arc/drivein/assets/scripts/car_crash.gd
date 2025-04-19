extends AnimatedSprite2D


func _on_visible_on_screen_notifier_2d_screen_entered() -> void :
    var sound: = AudioManager.Sound.CAR_IMPACT

    if not AudioManager.is_playing_sound(sound):
        frame = 0
        AudioManager.play(sound)
