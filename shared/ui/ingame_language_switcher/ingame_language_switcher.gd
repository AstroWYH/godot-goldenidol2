extends OptionButton

@export var parent_dialog: CanvasLayer


const LABEL_MAP: = {
    "en": "English", 
    "lv": "Latviski", 
    "de": "Deutsch", 
    "es": "Español (Spanish)", 
    "es_MX": "Español (Latin America)", 
    "fr": "Français", 
    "it": "Italiano", 
    "pl": "Polski", 
    "pt_BR": "Português do Brasil", 
    "tr": "Türkçe", 
    "ja": "日本語", 
    "zh_TW": "中文", 
    "ko": "한국어", 
}


const SETTINGS_SECTION = SettingsManager.Keys.SECTION_GENERAL
const SETTINGS_KEY = SettingsManager.Keys.SETTING_LANGUAGE


func _ready() -> void :
    var current_locale: = TranslationServer.get_locale()
    var loaded_locales: = TranslationServer.get_loaded_locales()
    var preselect_idx: = 0
    var locales: PackedStringArray = ["en"]
    locales.append_array(loaded_locales)



    var unique_locales: = []
    for locale in locales:
        if locale not in unique_locales:
            unique_locales.append(locale)

    for idx in range(unique_locales.size()):
        var locale: String = unique_locales[idx]

        add_item(LABEL_MAP.get(locale, "unknown") as String, idx)
        set_item_metadata(idx, {
            "locale": locale
        })

        if current_locale.find(locale) == 0:


            preselect_idx = idx

    select(preselect_idx)


func _notification(what: int) -> void :
    if what == NOTIFICATION_TRANSLATION_CHANGED:

        pass


func _on_option_button_item_selected(idx: int) -> void :
    var meta: Dictionary = get_item_metadata(idx)
    var locale: String = meta.get("locale") as String

    var current_locale: = TranslationServer.get_locale()
    if current_locale != locale:
        TranslationServer.set_locale(locale)
        SettingsManager.set_setting(
            SETTINGS_SECTION, 
            SETTINGS_KEY, 
            locale
        )

    if parent_dialog:
        parent_dialog.visible = false
