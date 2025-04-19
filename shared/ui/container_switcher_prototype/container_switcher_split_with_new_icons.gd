extends Control

signal container_button_toggled(pressed: bool, id: int)
signal container_button_mouse_entered(puzzle_id: int)
signal container_button_mouse_exited()

@onready var phrase_button1: = % PhraseButton1
@onready var phrase_button2: = % PhraseButton2

@onready var cell_button1: = % CellButton1
@onready var cell_button2: = % CellButton2

@onready var portrait_button1: = % CharacterButton1
@onready var portrait_button2: = % CharacterButton2

@onready var code_button1: = % CodeButton1
@onready var code_button2: = % CodeButton2

@onready var scroll_button1: = % ScrollButton1
@onready var scroll_button2: = % ScrollButton2

var button_list: Array[Node] = []

var phrase_puzzle: Control
var cell_puzzle: Control
var code_puzzle: Control
var portrait_puzzle: Control
var scroll_puzzle: Control

func _ready() -> void :
    button_list = [
        phrase_button1, 
        phrase_button2, 

        cell_button1, 
        cell_button2, 

        portrait_button1, 
        portrait_button2, 

        code_button1, 
        code_button2, 

        scroll_button1, 
        scroll_button2, 
    ]

    for i in range(button_list.size()):
        var button: = button_list[i]
        button.toggled.connect(on_button_toggled.bind(i))
        button.mouse_entered.connect(on_button_mouseover.bind(button))
        button.mouse_exited.connect(on_button_mouse_exit)


func on_button_toggled(pressed: bool, id: int) -> void :
    container_button_toggled.emit(pressed, id)


func on_button_mouseover(button: TextureButton) -> void :
    var button_id: = button_list.find(button)
    if button_id >= 0:
        container_button_mouse_entered.emit(button_id)


func on_button_mouse_exit() -> void :
    container_button_mouse_exited.emit()


func set_button_state(id: int, pressed: bool) -> void :
    var button: = button_list[id]
    button.set_pressed_no_signal(pressed)
