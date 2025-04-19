extends Control

signal container_button_toggled(pressed: bool, id: int)

@onready var phrase_button: = % PhrasesButton
@onready var portrait_button: = % PortraitButton
@onready var cell_button: = % CellButton
@onready var code_button: = % CodeButton
@onready var scroll_button: = % ScrollButton

var button_list: Array[Node] = []

var phrase_puzzle: Control
var cell_puzzle: Control
var code_puzzle: Control
var portrait_puzzle: Control
var scroll_puzzle: Control

func _ready() -> void :
    button_list = [
        phrase_button, 
        scroll_button, 
        portrait_button, 
        cell_button, 
        code_button, 
    ]


func unset_button(id: int) -> void :
    var button: = button_list[id]
    button.set_pressed_no_signal(false)


func _on_phrases_button_toggled(button_pressed: bool) -> void :
    container_button_toggled.emit(button_pressed, 0)


func _on_scroll_button_toggled(button_pressed: bool) -> void :
    container_button_toggled.emit(button_pressed, 1)


func _on_portrait_button_toggled(button_pressed: bool) -> void :
    container_button_toggled.emit(button_pressed, 2)


func _on_cell_button_toggled(button_pressed: bool) -> void :
    container_button_toggled.emit(button_pressed, 3)


func _on_code_button_toggled(button_pressed: bool) -> void :
    container_button_toggled.emit(button_pressed, 4)
