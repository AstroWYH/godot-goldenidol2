extends CanvasLayer

signal faded_in


func fade_in() -> void :
    var tween: Tween = create_tween()
    var fade_time: float = 1.0
    tween.tween_property($ColorRect, "color", Color.html("222034"), fade_time)

    MusicPlayer.stop(MusicPlayer.PlayerGroup.MUSIC, fade_time, true)
    MusicPlayer.stop(MusicPlayer.PlayerGroup.AMBIENCE, fade_time, true)

    var focus_owner: Control = get_viewport().gui_get_focus_owner()
    if focus_owner is Control:
        focus_owner.release_focus()

    tween.finished.connect(
        func() -> void :
            faded_in.emit()
            queue_free()
            , 
        CONNECT_ONE_SHOT
    )
