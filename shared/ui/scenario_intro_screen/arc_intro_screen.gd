extends ColorRect

var header_appear_time: float = 2.5
var name_appear_time: float = 1.5
var description_appear_time: float = 2.5

var header_interval: float = 0
var name_interval: float = 0
var description_interval: float = 0
var intro_ready_to_skip: bool = false
var arc_meta: ArcMeta
var _loading_done: bool = false
var _scene_path: String

@onready var timer: Timer = % Timer
@onready var header_label: Label = % HeaderLabel
@onready var name_label: Label = % NameLabel
@onready var description_label: Label = % DescriptionLabel
@onready var promt_label: Label = % PromtLabel
@onready var loading_indicator: Sprite2D = % LoadingIndicator


func _ready() -> void :
    promt_label.visible = false

    header_label.text = tr(arc_meta.header_label)
    name_label.text = tr(arc_meta.name)
    description_label.text = tr(arc_meta.description)

    if header_label.text == "":
        header_label.text = "--Missing chapter header--"
    if name_label.text == "":
        name_label.text = "--Missing chapter name--"
    if description_label.text == "":
        description_label.text = "--Missing chapter description--"

    header_interval = 0.08
    name_interval = 0.12
    description_interval = 0.08



    header_label.visible_characters = 0
    name_label.visible_characters = 0
    description_label.visible_characters = 0

    timer.wait_time = name_interval
    timer.timeout.connect(_on_timer_finished)
    timer.start()


    _scene_path = arc_meta.hub_scene_path
    ResourceLoader.load_threaded_request(_scene_path)
    set_process(true)


func _process(_delta: float) -> void :
    var status: int = ResourceLoader.load_threaded_get_status(_scene_path)

    if status == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_FAILED:
        Logger.write_err("Error loading " + _scene_path)
        set_process(false)
        ProgressManager.change_screen(_scene_path)
        return

    if status != ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED:
        return

    call_deferred(&"_mark_loading_done")
    set_process(false)


func _on_timer_finished() -> void :
    if intro_ready_to_skip:
        return

    if not header_label.get_total_character_count() == header_label.visible_characters:
        timer.wait_time = header_interval
        header_label.visible_characters += 1

        AudioManager.play_typewriter(
            header_label.text[header_label.visible_characters - 1]
        )

        timer.start()
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
    promt_label.visible = true


func _unhandled_input(_event: InputEvent) -> void :
    if GamepadUtils.back_pressed() or GamepadUtils.accept_pressed():
        _handle_skip()


func _input(event: InputEvent) -> void :
    if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
        if event.pressed:
            _handle_skip()


func _handle_skip() -> void :
    if not intro_ready_to_skip:
        header_label.visible_characters = -1
        name_label.visible_characters = -1
        description_label.visible_characters = -1
        timer.stop()
        intro_ready_to_skip = true
        get_viewport().set_input_as_handled()
        return

    if intro_ready_to_skip and _loading_done:
        get_viewport().set_input_as_handled()
        promt_label.hide()
        if len(arc_meta.autoload_intermission_path) > 0:
            load_intermission.call_deferred()
        else:
            load_arc.call_deferred()


func load_arc() -> void :
    ProgressManager.change_screen(ResourceLoader.load_threaded_get(_scene_path))


func load_intermission() -> void :
    ProgressManager.change_screen(arc_meta.autoload_intermission_path)


func _mark_loading_done() -> void :
    _loading_done = true
    loading_indicator.hide()
    promt_label.show()
