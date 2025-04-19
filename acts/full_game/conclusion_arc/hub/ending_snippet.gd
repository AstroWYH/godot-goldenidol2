extends SnippetDialog

@export var music_layers: Array[AudioStream]
@export var ambience_layers: Array[AudioStream]

@onready var close_button: Button = % CloseButton

func _ready() -> void :
    close_button.pressed.connect(_close_dialog)
    MusicPlayer.play_bg_audio(music_layers, ambience_layers)


func _close_dialog() -> void :
    if ProgressManager.ending_credits_shown:
        ProgressManager.change_screen("res://shared/ui/hub_of_hubs/hub_of_hubs.tscn")
    else:
        ProgressManager.change_screen("res://shared/ui/credits/credits_endgame.tscn")
