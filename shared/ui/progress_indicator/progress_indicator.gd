extends Control

signal everything_is_explored


enum ChangeSource{
    NONE, 
    SPOT, 
    PHRASE, 
}

var max_phrases: int = 45
var phrases: int = 0
var max_spots: int = 52
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

@onready var phrases_done_indicator: Sprite2D = % PhrasesDone
@onready var spots_done_indicator: Sprite2D = % SpotsDone


func _ready() -> void :
    if ProgressManager.current_scenario_meta:
        var scen_meta: ScenarioMeta = ProgressManager.current_scenario_meta
        max_phrases = scen_meta.phrases_name + \
scen_meta.phrases_object + \
scen_meta.phrases_action + \
scen_meta.phrases_special + \
scen_meta.phrases_numeral + \
scen_meta.phrases_local

        max_spots = scen_meta.max_spots
    else:

        queue_free()

    if max_phrases == 0:
        max_phrases = 0
    if max_spots == 0:
        max_spots = 0

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

    HotspotManager.hotspot_visited.connect(new_spot_clicked)
    spots = HotspotManager.get_visited_hotspot_count()
    ProgressManager.items_unlocked.connect(phrases_discovered)
    ProgressManager.scenario_reset.connect(_on_scenario_reset)
    phrases = ProgressManager.get_current_item_count()

    update_progress_visually()

    phrase_timer.timeout.connect(tween_phrase_bar)
    phrase_timer.wait_time = 0.1

    spot_timer.timeout.connect(tween_spot_bar)
    spot_timer.wait_time = 0.1


func new_spot_clicked(_hotspot_id: String) -> void :
    spots += 1
    update_progress_visually(ChangeSource.SPOT)


func phrases_discovered(item_ids: Array[int]) -> void :
    phrases += len(item_ids)
    update_progress_visually(ChangeSource.PHRASE)


func tween_phrase_bar() -> void :
    var tween: = create_tween()
    tween.tween_property(phrase_front_bar, "value", phrases * 100, 1)


func is_everything_explored() -> bool:
    var everything_explored: = phrases == max_phrases and spots == max_spots
    return everything_explored


func tween_spot_bar() -> void :
    var tween: = create_tween()
    tween.tween_property(spot_front_bar, "value", spots * 100, 1)


func update_progress_visually(source: ChangeSource = ChangeSource.NONE) -> void :
    phrase_label.text = tr("PHRASE_PROGRESS_BAR_LABEL") + " " + str(phrases) + " / " + str(max_phrases)
    spots_label.text = tr("SPOT_PROGRESS_BAR_LABEL") + " " + str(spots) + " / " + str(max_spots)
    phrase_bar.value = phrases
    spot_bar.value = spots

    if spot_timer.is_stopped:
        spot_timer.start()

    if phrase_timer.is_stopped:
        phrase_timer.start()

    if phrases == max_phrases:
        phrases_done_indicator.visible = true
    if spots == max_spots:
        spots_done_indicator.visible = true

    var sound: = AudioManager.Sound.SCENARIO_EXPLORED
    var is_playing_explore_sound: = AudioManager.is_playing_sound(sound)
    var everything_explored: = phrases == max_phrases and spots == max_spots

    if everything_explored:
        everything_is_explored.emit()

    if source != ChangeSource.NONE and everything_explored and not is_playing_explore_sound:
        AudioManager.play(sound)



func _on_scenario_reset(_scenario_id: int) -> void :
    phrases = 0
    spots = 0
    phrases_done_indicator.visible = false
    spots_done_indicator.visible = false
    update_progress_visually()
