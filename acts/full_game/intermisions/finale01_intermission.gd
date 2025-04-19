extends IntermissionDialog


func _on_close_pressed() -> void :
    AudioManager.play(AudioManager.Sound.BUTTON_CLICK)

    var second_intermission: IntermissionDialog = load("res://acts/full_game/intermisions/finale02_intermission.tscn").instantiate()
    get_parent().add_child(second_intermission)
    queue_free()
