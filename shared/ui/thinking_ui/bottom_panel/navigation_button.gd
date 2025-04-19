extends BaseButton

const QuickNavigation: = preload("res://shared/ui/quick_navigator/quick_navigator.tscn")

var _window: ColorRect = null
var _prev_focus_owner: Control = null

func _ready() -> void :
    if not ProgressManager.is_scenario_beaten(11):
        visible = false
        return

    pressed.connect(_on_pressed)


func _unhandled_input(_event: InputEvent) -> void :
    if not Input.is_action_just_pressed(GamepadUtils.ACTION_SHOW_QUICK_NAVIGATOR):
        return

    if not visible:
        return

    get_viewport().set_input_as_handled()
    _on_pressed()


func _on_pressed() -> void :
    if _window:
        _window.queue_free()
        _window = null
        if _prev_focus_owner is Control:
            _prev_focus_owner.grab_focus()
        return

    AudioManager.play(AudioManager.Sound.BUTTON_CLICK)
    _prev_focus_owner = get_viewport().gui_get_focus_owner()

    var quick_navigation_scene: ColorRect = QuickNavigation.instantiate()
    _window = quick_navigation_scene
    ProgressManager.dialog_layer.add_child(quick_navigation_scene)
    quick_navigation_scene.tree_exited.connect(
        func() -> void :
            _window = null, 
        CONNECT_ONE_SHOT, 
    )
