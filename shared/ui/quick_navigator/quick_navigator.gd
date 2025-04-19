extends ColorRect

const APPEAR_TIME_GAP: float = 0.05
const SCALE_BUTTON_INITIAL: float = 0.7
const SCALE_BUTTON_MIDDLE: float = 1.05
const SCALE_BUTTON_FINAL: float = 1

@onready var row_container: VBoxContainer = % RowContainer


func _ready() -> void :
    gui_input.connect(_on_gui_input)

    var rows: Array = row_container.get_children()
    rows.reverse()

    for row: HBoxContainer in rows:
        for child: Button in row.get_children():
            child.screen_change_called.connect(_screen_change_called)

    for row: HBoxContainer in rows:
        make_elements_appear(row)
        await get_tree().create_timer(APPEAR_TIME_GAP).timeout


func _on_gui_input(event: InputEvent) -> void :
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                queue_free()


func make_elements_appear(element: HBoxContainer) -> void :
    var apply_focus: bool = false
    for child in element.get_children():
        if child.available:
            if not apply_focus:
                play_appear(child, true)
                apply_focus = true
            else:
                play_appear(child, false)
            await get_tree().create_timer(APPEAR_TIME_GAP).timeout


func play_appear(element: Node, focus: bool = false) -> void :
    element.scale = Vector2(SCALE_BUTTON_INITIAL, SCALE_BUTTON_INITIAL)
    element.visible = true
    if focus and element is Control:
        (element as Control).grab_focus()
    var scale_tween: Tween = create_tween()
    scale_tween.tween_property(element, "scale", Vector2(SCALE_BUTTON_MIDDLE, SCALE_BUTTON_MIDDLE), APPEAR_TIME_GAP)
    scale_tween.finished.connect(tween_first_part_finished.bind(element))


func tween_first_part_finished(element: Button) -> void :
    var scale_tween: Tween = create_tween()
    scale_tween.tween_property(element, "scale", Vector2(SCALE_BUTTON_FINAL, SCALE_BUTTON_FINAL), APPEAR_TIME_GAP)


func _screen_change_called() -> void :
    queue_free()
