extends Node2D

@export var music_layers: Array[AudioStream]
@export var ambience_layers: Array[AudioStream]

var years_interval: float = 0.15
var pause_length: float = 3
var description_interval: float = 0.15

var dramatic_pause_happened: bool = false
var second_dramatic_pause_happened: bool = false
var sequence_done: bool = false

@onready var background: Sprite2D = % BackgroundSprite
@onready var animation: AnimatedSprite2D = % Animation
@onready var idol: Sprite2D = % IdolSprite

@onready var timer: Timer = % Timer
@onready var years_label: Label = % Years
@onready var description_label: Label = % Name
@onready var next_button: Button = % NextButton



func _ready() -> void :
    next_button.visible = false

    years_label.text = tr("DEMO_OUTRO_TITLE_1")
    description_label.text = tr("DEMO_OUTRO_TITLE_2")

    years_label.visible_characters = 0
    description_label.visible_characters = 0

    timer.wait_time = years_interval
    timer.timeout.connect(_on_timer_finished)
    timer.start()



func _on_timer_finished() -> void :
    if sequence_done:
        return

    if not years_label.get_total_character_count() == years_label.visible_characters:
        timer.wait_time = years_interval
        years_label.visible_characters += 1

        AudioManager.play_typewriter(
            years_label.text[years_label.visible_characters - 1]
        )

        timer.start()
        return

    if not dramatic_pause_happened:
        timer.wait_time = pause_length
        timer.start()
        dramatic_pause_happened = true
        return

    if not background.visible:
        background.visible = true
        animation.visible = true
        timer.wait_time = pause_length
        timer.start()

        MusicPlayer.play_bg_audio(music_layers, ambience_layers)
        return

    if not second_dramatic_pause_happened:
        second_dramatic_pause_happened = true
        timer.wait_time = description_interval
        timer.start()
        return

    if not description_label.get_total_character_count() == description_label.visible_characters:
        timer.wait_time = description_interval
        description_label.visible_characters += 1

        AudioManager.play_typewriter(
            description_label.text[description_label.visible_characters - 1]
        )

        timer.start()
        return

    sequence_done = true
    next_button.visible = true
    var tween: Tween = get_tree().create_tween()
    tween.tween_property(idol, "modulate", Color(0.757, 1, 1), 1)
