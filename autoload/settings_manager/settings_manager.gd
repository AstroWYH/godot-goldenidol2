extends Node

signal settings_loaded()
signal setting_changed(section: String, key: String, value: Variant)
signal fullscreen_toggled(is_fullscreen: bool)
signal ui_scale_changed(scale: Vector2)

const SETTINGS_FILENAME: = "settings.ini"
const Keys: = preload("res://autoload/settings_manager/keys.gd")

var settings_path: = ""
var config: ConfigFile = ConfigFile.new()
var _last_nonfullscreen_winmode: DisplayServer.WindowMode


func _unhandled_input(_event: InputEvent) -> void :
    if Input.is_action_just_pressed("fullscreen_toggle"):
        toggle_fullscreen()


func configure(new_user_id: String) -> void :
    var prefix: = "user://%s" % new_user_id
    settings_path = "%s/%s" % [prefix, SETTINGS_FILENAME]

    if not DirAccess.dir_exists_absolute(prefix):
        DirAccess.make_dir_absolute(prefix)

    load_settings()


func load_settings() -> void :
    var result: Error = config.load(settings_path)
    if result == ERR_PARSE_ERROR:
        config.clear()
    settings_loaded.emit()

    var locale: String = get_setting(
        Keys.SECTION_GENERAL, 
        Keys.SETTING_LANGUAGE, 
        TranslationServer.get_locale()
    ) as String
    TranslationServer.set_locale(locale)


func save_settings() -> void :
    config.save(settings_path)



func set_setting(section: String, key: String, value: Variant = null) -> void :
    config.set_value(section, key, value)
    setting_changed.emit(section, key, value)
    save_settings()


func get_setting(section: String, key: String, default: Variant = null) -> Variant:
    return config.get_value(section, key, default)


func has_setting(section: String, key: String) -> bool:
    return config.has_section_key(section, key)


func is_fullscreen() -> bool:
    return DisplayServer.window_get_mode() == DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN


func toggle_fullscreen() -> void :
    var current_winmode: DisplayServer.WindowMode = DisplayServer.window_get_mode()
    var fullscreen: bool

    @warning_ignore("unused_variable")
    var final_mode: DisplayServer.WindowMode

    if current_winmode == DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN:


        DisplayServer.window_set_mode(_last_nonfullscreen_winmode)
        final_mode = _last_nonfullscreen_winmode
        fullscreen = false
    else:
        _last_nonfullscreen_winmode = current_winmode
        fullscreen = true
        final_mode = DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN
        DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN)




    "\n	var override: ConfigFile = ConfigFile.new()\n	var path: String = OS.get_executable_path().get_base_dir() + \"/override.cfg\"\n	override.set_value(\"display\", \"window/size/mode\", final_mode)\n	override.save(path)\n	"






    fullscreen_toggled.emit(fullscreen)


func change_ui_scale(new_scale: Vector2) -> void :
    var ui_scale: Vector2 = get_setting(Keys.SECTION_GENERAL, Keys.SETTING_UI_SCALE)
    if ui_scale == new_scale:
        return

    set_setting(Keys.SECTION_GENERAL, Keys.SETTING_UI_SCALE, new_scale)
    ui_scale_changed.emit(new_scale)


func get_ui_scale() -> Vector2:
    var default: Vector2 = Vector2.ONE
    var result: Variant = get_setting(Keys.SECTION_GENERAL, Keys.SETTING_UI_SCALE, default)
    if not result is Vector2:
        return Vector2.ONE
    return result


func get_click_to_drag() -> bool:
    var default: bool = false
    var result: Variant = get_setting(Keys.SECTION_GENERAL, Keys.SETTING_CLICK_TO_DRAG, default)
    if not result is bool:
        return default
    return result
