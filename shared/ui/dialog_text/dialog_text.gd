extends Control

var DialogScene: PackedScene
const MARGIN: Vector2 = Vector2(32.0, 32.0)

@export_multiline var text: String:
    set = _set_text

@onready var panel: Panel = $Panel
@onready var container: CenterContainer = $Panel / Container
@onready var label: Label = $Panel / Container / Label
@onready var host: Node = get_parent()


func _ready() -> void :


    DialogScene = load("res://shared/ui/dialog/dialog.tscn")
    _set_text(text)


func show_dialog(trigger: Control) -> void :
    show()



    label.grab_focus()
    DialogManager.set_last_exploration_control(label)

    var dialog: Dialog = DialogScene.instantiate()
    var pos_mode: Dialog.DialogPositioningMode
    if GamepadUtils.accept_pressed():
        pos_mode = Dialog.DialogPositioningMode.TRIGGER_POSITION
    else:
        pos_mode = Dialog.DialogPositioningMode.FOLLOW_MOUSE
    dialog.positioning_mode = pos_mode
    dialog.content_node = panel
    dialog.ready.connect(
        func() -> void : dialog.show_dialog(trigger, false), 
        CONNECT_ONE_SHOT, 
    )
    host.add_child(dialog)
    dialog.dialog_hidden.connect(queue_free)
    dialog.dialog_hide_started.connect(_handle_dialog_hide_started)
    AudioManager.play(AudioManager.Sound.TOOLTIP_OPEN, SoundParams.new().with_pitch_range(Vector2(-0.1, 0.1)))


func get_dialog_instance_id() -> int:
    return get_instance_id()


func _set_text(value: String) -> void :
    text = value

    if not label:
        return

    label.text = value




    container.reset_size()
    call_deferred(&"_on_container_resized")


func _on_container_resized() -> void :
    if not panel or not container:
        return
    panel.size = container.size + MARGIN
    container.position.x = MARGIN.x / 2
    container.position.y = MARGIN.y / 2


func _handle_dialog_hide_started() -> void :
    AudioManager.play(AudioManager.Sound.TOOLTIP_CLOSE, SoundParams.new().with_pitch_range(Vector2(-0.1, 0.1)))
