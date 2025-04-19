extends Control

var max_phrases: int = 26
var phrases: int = 0
var max_spots: int = 18
var spots: int = 0
var max_progress: int
var anim_length: float


@onready var phrase_label: Label = % PhraseLabel
@onready var spots_label: Label = % SpotLabel


@onready var phrase_bar: ProgressBar = % PhraseBar
@onready var phrase_front_bar: ProgressBar = % PhraseFrontBar

@onready var spot_bar: ProgressBar = % SpotBar
@onready var spot_front_bar: ProgressBar = % SpotFrontBar

@onready var phrase_timer: Timer = % PhraseTimer
@onready var spot_timer: Timer = % SpotTimer


func _ready() -> void :
    max_progress = max_phrases
    phrase_bar.max_value = max_progress
    phrase_bar.min_value = 0
    phrase_bar.step = 1
    phrase_bar.value = 0
    phrase_front_bar.step = phrase_bar.step
    phrase_front_bar.value = 0
    phrase_front_bar.max_value = phrase_bar.max_value * 100
    phrase_front_bar.min_value = phrase_bar.min_value

    spot_bar.max_value = max_spots
    spot_bar.min_value = 0
    spot_bar.step = 1
    spot_bar.value = 0
    spot_front_bar.step = spot_bar.step
    spot_front_bar.value = 0
    spot_front_bar.max_value = spot_bar.max_value * 100
    spot_front_bar.min_value = spot_bar.min_value


    HotspotManager.new_spot_clicked.connect(new_spot_clicked)

    ProgressManager.item_unlocked.connect(phrase_discovered)
    update_progress_visually()
    phrase_timer.timeout.connect(tween_phrase_bar)
    phrase_timer.wait_time = 0.1

    spot_timer.timeout.connect(tween_spot_bar)
    spot_timer.wait_time = 0.1


func new_spot_clicked() -> void :
    spots += 1
    update_progress_visually()


func phrase_discovered(_id: int) -> void :
    phrases += 1
    update_progress_visually()


func tween_phrase_bar() -> void :
    var tween: = create_tween()

    tween.tween_property(phrase_front_bar, "value", phrases * 100, 1)


func tween_spot_bar() -> void :
    var tween: = create_tween()

    tween.tween_property(spot_front_bar, "value", spots * 100, 1)


func update_progress_visually() -> void :
    phrase_label.text = "Phrases found: " + str(phrases) + " / " + str(max_phrases)
    spots_label.text = "Spots explored: " + str(spots) + " / " + str(max_spots)
    phrase_bar.value = phrases
    spot_bar.value = spots

    if spot_timer.is_stopped:
        spot_timer.start()

    if phrase_timer.is_stopped:
        phrase_timer.start()
