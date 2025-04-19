extends ColorRect

var name_appear_time: float = 1.5
var description_appear_time: float = 2.5

var name_interval: float = 0
var description_interval: float = 0
var intro_ready_to_skip: bool = false
var scenario_meta: ScenarioMeta
var _loading_done: bool = false
var _scenario_path: String

@onready var timer: Timer = % Timer
@onready var name_label: Label = % NameLabel
@onready var description_label: Label = % DescriptionLabel
@onready var promt_label: Label = % PromtLabel
@onready var loading_indicator: Sprite2D = % LoadingIndicator


func _ready() -> void :
    promt_label.visible = false

    name_label.text = tr(scenario_meta.name)
    description_label.text = tr(scenario_meta.description)

    if name_label.text == "":
        name_label.text = "--Missing scenario name--"
    if description_label.text == "":
        description_label.text = "--Missing scenario description--"

    name_interval = 0.12
    description_interval = 0.08



    name_label.visible_characters = 0
    description_label.visible_characters = 0

    timer.wait_time = name_interval
    timer.timeout.connect(_on_timer_finished)
    timer.start()


    _scenario_path = scenario_meta.path
    ResourceLoader.load_threaded_request(_scenario_path)
    set_process(true)


func _process(_delta: float) -> void :
    var status: int = ResourceLoader.load_threaded_get_status(_scenario_path)

    if status == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_FAILED:
        Logger.write_err("Error loading " + _scenario_path)
        set_process(false)
        ProgressManager.change_screen(_scenario_path)
        return

    if status != ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED:
        return

    call_deferred(&"_mark_loading_done")
    set_process(false)


func _on_timer_finished() -> void :
    if intro_ready_to_skip:
        return

    if not name_label.get_total_character_count() == name_label.visible_characters:
        timer.wait_time = name_interval
        name_label.visible_characters += 1

        AudioManager.play_typewriter(
            name_label.text[name_label.visible_characters - 1]
        )

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

    intro_ready_to_skip = true

    if _loading_done:
        promt_label.show()


func _unhandled_input(_event: InputEvent) -> void :
    if GamepadUtils.back_pressed() or GamepadUtils.accept_pressed():
        _handle_skip()


func _input(event: InputEvent) -> void :
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            _handle_skip()


func tween_done(tween: Tween) -> void :
        tween.tween_property(loading_indicator, "rotation", 10, 10)
        tween.finished.connect(tween_done.bind(tween))



func _handle_skip() -> void :
    if not intro_ready_to_skip:
        name_label.visible_characters = -1
        description_label.visible_characters = -1
        timer.stop()
        intro_ready_to_skip = true
        get_viewport().set_input_as_handled()
        if _loading_done:
            promt_label.show()
        return

    if intro_ready_to_skip and _loading_done:
        promt_label.hide()
        get_viewport().set_input_as_handled()
        load_scenario.call_deferred()


func load_scenario() -> void :
    ProgressManager.change_screen(ResourceLoader.load_threaded_get(scenario_meta.path))


func _mark_loading_done() -> void :
    _loading_done = true
    loading_indicator.hide()
    if intro_ready_to_skip:
        promt_label.show()
