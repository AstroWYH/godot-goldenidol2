extends CanvasLayer

var _queued_path: String
var language: String

@onready var margin_container: MarginContainer = % MarginContainer
@onready var percentage_label: Label = % LoadingPercentage
@onready var icon: TextureRect = % TextureRect


func _ready() -> void :
    set_process(false)
    margin_container.hide()
    language = TranslationServer.get_locale()
    SettingsManager.setting_changed.connect(_on_settings_changed)


func _process(_delta: float) -> void :
    var prog: Array = []
    var status: int = ResourceLoader.load_threaded_get_status(_queued_path, prog)

    _update_percentage(prog[0] as float)

    if status == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_FAILED:
        Logger.write_err("Error loading " + _queued_path)
        set_process(false)
        return

    if status != ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED:
        return

    call_deferred(&"_mark_loading_done")
    set_process(false)


func _on_settings_changed(_section: String, key: String, value: Variant) -> void :
    if key == SettingsManager.Keys.SETTING_LANGUAGE:
        language = value


func show_screen() -> void :
    margin_container.show()


func hide_screen() -> void :
    margin_container.hide()


func queue_load(path: String) -> void :
    show_screen()
    _queued_path = path
    ResourceLoader.load_threaded_request(_queued_path)
    set_process(true)


func _mark_loading_done() -> void :
    ProgressManager.change_screen(ResourceLoader.load_threaded_get(_queued_path))
    _queued_path = ""


func _update_percentage(percentage: float) -> void :
    var perc: int = int(percentage * 100)
    if language == "tr":
        percentage_label.text = "%" + str(perc)
    else:
        percentage_label.text = str(perc) + "%"
