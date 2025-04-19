extends Button

@onready var language_popup: CanvasLayer = % LanguagePopup

const LOCALE_MAP: Dictionary = {
    "en": "ENG", 
    "de": "DE", 
    "es_mx": "ES-LA", 
    "es": "ES", 
    "fr": "FRA", 
    "it": "IT", 
    "pl": "PL", 
    "pt_br": "PT-BR", 
    "tr": "TR", 
    "ja": "日本語", 
    "zh_tw": "中文", 
    "ko": "한국어", 
}


func _ready() -> void :
    pressed.connect(_on_pressed)
    language_popup.visibility_changed.connect(_on_language_popup_visibility_changed)
    mouse_entered.connect(_on_mouse_entered)
    _set_text()


func _unhandled_input(_event: InputEvent) -> void :
    GamepadUtils.handle_confirm(self, _on_pressed)


func _notification(what: int) -> void :
    if what == NOTIFICATION_TRANSLATION_CHANGED:
        _set_text()


func _on_pressed() -> void :
    language_popup.show()


func _on_language_popup_visibility_changed() -> void :
    if not language_popup.visible and focus_mode != FOCUS_NONE:
        grab_focus()


func _set_text() -> void :
    var locale: String = TranslationServer.get_locale().to_lower()

    for k: String in LOCALE_MAP:
        if locale.find(k.to_lower()) == 0:

            text = LOCALE_MAP[k]
            return


    text = locale.to_upper()


func _on_mouse_entered() -> void :
    if focus_mode != FOCUS_ALL:
        return
    grab_focus()
