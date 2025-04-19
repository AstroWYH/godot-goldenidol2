extends IntermissionDialog


func _on_replay_pressed() -> void :
    AudioManager.play(AudioManager.Sound.BUTTON_CLICK)

    var first_intermission: IntermissionDialog = load("res://acts/full_game/intermisions/finale01_intermission.tscn").instantiate()
    get_parent().add_child(first_intermission)
    queue_free()


func _on_close_pressed() -> void :
    AudioManager.play(AudioManager.Sound.BUTTON_CLICK)

    if not ProgressManager.ending_credits_shown:
        ProgressManager.change_screen("res://acts/full_game/conclusion_arc/hub/ending_snippet.tscn")
    else:
        ProgressManager.change_screen("res://shared/ui/hub_of_hubs/hub_of_hubs.tscn")
