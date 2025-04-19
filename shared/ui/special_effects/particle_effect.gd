extends GPUParticles2D

func _exit_tree() -> void :
    stop_sound()


func play_sound() -> void :
    AudioManager.play_puzzle_unlock_loop(get_instance_id())


func stop_sound() -> void :
    AudioManager.stop_puzzle_unlock_loop(get_instance_id())


func _on_visible_on_screen_notifier_2d_screen_entered() -> void :
    play_sound()


func _on_visible_on_screen_notifier_2d_screen_exited() -> void :
    stop_sound()
