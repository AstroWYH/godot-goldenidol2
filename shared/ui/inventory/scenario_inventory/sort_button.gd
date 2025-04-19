extends Button

const DEBOUNCE_TIME_SEC = 0.175

var _debounce_timer: float = 0


func _ready() -> void :
    set_process(false)
    var locale: String = TranslationServer.get_locale()
    var lang: String = locale.substr(0, locale.find("_")).to_lower()

    if lang in Constants.CJK_LANGS:
        hide()
        return

    pressed.connect(
        func() -> void :
            _debounce_timer = DEBOUNCE_TIME_SEC
            set_process(true)
    )


func _process(delta: float) -> void :
    _debounce_timer = maxf(0, _debounce_timer - delta)

    if _debounce_timer == 0:
        set_process(false)
        ProgressManager.sort_pressed()
