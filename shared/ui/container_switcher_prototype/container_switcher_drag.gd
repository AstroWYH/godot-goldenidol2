extends Control

signal container_button_toggled(pressed: bool, id: int)
signal container_button_mouse_entered(puzzle_id: int)
signal container_button_mouse_exited()

var button_list: Array[Node] = []
var phrase_puzzle: Control
var cell_puzzle: Control
var code_puzzle: Control
var portrait_puzzle: Control
var scroll_puzzle: Control
var container_list: Array = []

@onready var phrase_button: = % PhraseButton
@onready var cell_button: = % CellButton
@onready var portrait_button: = % PortraitButton
@onready var code_button: = % CodeButton
@onready var scroll_button: = % ScrollButton


func _ready() -> void :
    button_list = [
        phrase_button, 
        cell_button, 
        portrait_button, 
        code_button, 
        scroll_button, 
    ]

    for i in range(button_list.size()):
        var button: = button_list[i]
        button.toggled.connect(on_button_toggled.bind(button))

    ContainerDragAndDropManager.button_lifted.connect(button_lifted)
    ContainerDragAndDropManager.button_dropped.connect(button_dropped)


func button_dropped(button: Node) -> void :
    button.set_pressed_no_signal(false)


func button_lifted(button: Node) -> void :
    button.set_pressed_no_signal(true)


func set_button_containers(_passed_container_list: Array) -> void :
    container_list = _passed_container_list
    for i in range(button_list.size()):
        var button: = button_list[i]
        button.container = container_list[i]


func on_button_toggled(pressed: bool, button: Control) -> void :
    container_button_toggled.emit(pressed, button)


func on_button_mouseover(button: TextureButton) -> void :
    var button_id: = button_list.find(button)
    if button_id >= 0:
        container_button_mouse_entered.emit(button_id)


func on_button_mouse_exit() -> void :
    container_button_mouse_exited.emit()


func set_button_state(id: int, pressed: bool) -> void :
    var button: = button_list[id]
    button.set_pressed_no_signal(pressed)


func reset_button_positions() -> void :
    for i in range(button_list.size()):
        var button: = button_list[i]
        button.position.x = 470 + i * (20 + button.size.x)
        button.position.y = 33
