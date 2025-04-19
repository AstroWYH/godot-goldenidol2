extends Node2D
class_name ScenarioSelect

@export var music_layers: Array[AudioStream]
@export var ambience_layers: Array[AudioStream]

@onready var play_button: Button = % PlayButton
@onready var settings_button: Button = % SettingsButton
@onready var in_game_menu: CanvasLayer = % InGameMenu
@onready var full_screen_info_label: Label = % FullScreenInfo

func _init() -> void :
    DevTools.reset_now()


func _ready() -> void :
    DevTools.set_scene_root(self)
    AudioManager.stop_all(1.0)
    MusicPlayer.play_bg_audio(music_layers, ambience_layers)
    MusicPlayer.restore_gain()
    DevTools.report_load_finished()
    _configure_settings_button()


func _configure_settings_button() -> void :
    settings_button.pressed.connect(
        func() -> void :
            AudioManager.play(AudioManager.Sound.BUTTON_CLICK)
            in_game_menu.show()
    )
    in_game_menu.visibility_changed.connect(
        func() -> void :
            if in_game_menu.visible:
                return
            settings_button.grab_focus()
    )
