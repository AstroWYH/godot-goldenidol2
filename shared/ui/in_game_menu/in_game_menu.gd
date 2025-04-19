extends CanvasLayer

signal scenario_exit_pressed

@export var in_main_menu: bool = false

@onready var master_volume_slider: HSlider = % MasterVolumeSlider
@onready var music_volume_slider: HSlider = % MusicVolumeSlider
@onready var sfx_volume_slider: HSlider = % SFXVolumeSlider
@onready var show_highlights_checkbox: CheckBox = % ShowHighlightsCheckBox
@onready var full_screen_checkbox: CheckBox = % FullScreenCheckBox
@onready var ui_scale_slider: HSlider = % UIScaleSlider
@onready var background: ColorRect = % ColorRect
@onready var exit_scenario_button: Button = % ExitScenarioButton

var _prev_focus_owner: Control


func _ready() -> void :
    hide()
    % CloseButton.pressed.connect(_on_close_button_pressed)

    var reset_button: Button = % ResetButton
    reset_button.set_mode(in_main_menu)
    reset_button.scenario_reset_confirmed.connect(hide)

    if in_main_menu:
        exit_scenario_button.queue_free()
    else:
        exit_scenario_button.pressed.connect(_on_exit_scenario_button_pressed)

    var hints_button: Button = % HintsButton
    if _is_in_scenario_mode():

        hints_button.pressed.connect(
            func() -> void :

                hints_button.prev_focus_owner = _prev_focus_owner
                hide()
        )
        if ProgressManager.is_current_scenario_beaten():
            reset_button.hide()
        else:
            ProgressManager.scenario_beaten.connect(reset_button.hide.unbind(2))
    else:
        hints_button.queue_free()

    visibility_changed.connect(_on_visibility_changed)
    _init_settings()
    background.gui_input.connect(_on_background_gui_input)


func _on_background_gui_input(event: InputEvent) -> void :
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                hide()


func _is_in_scenario_mode() -> bool:
    return ProgressManager.current_scenario is Node2D


func _init_settings() -> void :
    _handle_volume_sliders()
    _handle_highlights_checkbox()
    _handle_fullscreen_checkbox()
    _handle_ui_scale_slider()


func _handle_fullscreen_checkbox() -> void :
    full_screen_checkbox.button_pressed = SettingsManager.is_fullscreen()
    full_screen_checkbox.pressed.connect(_on_full_sceen_checkbox_pressed)
    SettingsManager.fullscreen_toggled.connect(
        func(v: bool) -> void :
            full_screen_checkbox.set_pressed_no_signal(v)
    )


func _handle_highlights_checkbox() -> void :
    var section: String = SettingsManager.Keys.SECTION_GENERAL
    var key: String = SettingsManager.Keys.SETTING_VISIBLE_HIGHLIGHTERS

    if not SettingsManager.has_setting(section, key):

        show_highlights_checkbox.button_pressed = true
    else:
        show_highlights_checkbox.button_pressed = SettingsManager.get_setting(section, key)

    show_highlights_checkbox.pressed.connect(_on_show_highlights_checkbox_pressed)


func _handle_volume_sliders() -> void :
    master_volume_slider.set_value_no_signal(AudioManager.get_master_vol_as_perc())
    master_volume_slider.value_changed.connect(_on_master_volume_slider_value_changed)

    sfx_volume_slider.set_value_no_signal(AudioManager.get_sfx_vol_as_perc())
    sfx_volume_slider.value_changed.connect(_on_sfx_volume_slider_value_changed)

    music_volume_slider.set_value_no_signal(MusicPlayer.get_music_vol_as_perc())
    music_volume_slider.value_changed.connect(_on_music_volume_slider_value_changed)


func _handle_ui_scale_slider() -> void :
    var section: String = SettingsManager.Keys.SECTION_GENERAL
    var key: String = SettingsManager.Keys.SETTING_UI_SCALE
    if not SettingsManager.has_setting(section, key):
        var default_ui_scale: = Vector2(1, 1)
        ui_scale_slider.set_value_no_signal(default_ui_scale.x * 100)
        SettingsManager.set_setting(section, key, default_ui_scale)
    else:
        var ui_scale: Vector2 = SettingsManager.get_setting(section, key)
        ui_scale_slider.set_value_no_signal(ui_scale.x * 100)
    ui_scale_slider.value_changed.connect(on_ui_slider_value_changed)


func _on_master_volume_slider_value_changed(value: float) -> void :
    SettingsManager.set_setting(
        SettingsManager.Keys.SECTION_AUDIO, 
        SettingsManager.Keys.SETTING_VOL_MASTER, 
        value, 
    )


func on_ui_slider_value_changed(value: float) -> void :
    var new_scale: = Vector2(value / 100, value / 100)
    SettingsManager.change_ui_scale(new_scale)


func _on_sfx_volume_slider_value_changed(value: float) -> void :
    SettingsManager.set_setting(
        SettingsManager.Keys.SECTION_AUDIO, 
        SettingsManager.Keys.SETTING_VOL_SFX, 
        value, 
    )


func _on_music_volume_slider_value_changed(value: float) -> void :
    SettingsManager.set_setting(
        SettingsManager.Keys.SECTION_AUDIO, 
        SettingsManager.Keys.SETTING_VOL_MUSIC, 
        value, 
    )


func _on_show_highlights_checkbox_pressed() -> void :
    AudioManager.play(AudioManager.Sound.BUTTON_CLICK)
    SettingsManager.set_setting(
        SettingsManager.Keys.SECTION_GENERAL, 
        SettingsManager.Keys.SETTING_VISIBLE_HIGHLIGHTERS, 
        show_highlights_checkbox.button_pressed, 
    )


func _on_full_sceen_checkbox_pressed() -> void :
    AudioManager.play(AudioManager.Sound.BUTTON_CLICK)
    SettingsManager.toggle_fullscreen()


func _unhandled_input(_event: InputEvent) -> void :
    if not visible:
        return

    if GamepadUtils.back_pressed():
        hide()
        get_viewport().set_input_as_handled()
        return

    if not Input.is_action_just_pressed("ui_cancel"):
        return

    hide()
    get_viewport().set_input_as_handled()


func _on_close_button_pressed() -> void :
    AudioManager.play(AudioManager.Sound.BUTTON_CLICK)
    hide()


func _on_exit_scenario_button_pressed() -> void :
    AudioManager.play(AudioManager.Sound.BUTTON_CLICK)
    hide()
    scenario_exit_pressed.emit()


func _on_visibility_changed() -> void :
    if not visible:
        if is_instance_valid(_prev_focus_owner) and _prev_focus_owner is Control and _prev_focus_owner.focus_mode == Control.FOCUS_ALL:
            _prev_focus_owner.grab_focus()
        return
    var focus_owner: Variant = get_viewport().gui_get_focus_owner()

    if not focus_owner is Control and DialogManager.get_last_exploration_control() is Control:
        focus_owner = DialogManager.get_last_exploration_control()
    _prev_focus_owner = focus_owner

    if is_instance_valid(exit_scenario_button) and exit_scenario_button.visible:
        exit_scenario_button.grab_focus()
    else:
        show_highlights_checkbox.grab_focus()

    DragAndDropManager.drop_dragged_node(DragAndDropManager.DropBehavior.CANCEL)
