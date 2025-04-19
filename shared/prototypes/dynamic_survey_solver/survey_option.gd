extends OptionButton

signal dynamic_lines_required(value: Array)


var dropdown: DropdownData = null



func _ready() -> void :
    item_selected.connect(on_item_selected)


func on_item_selected(id: int) -> void :



    var required_line_list: Array = []
    if not id == 0:
        var adjusted_id: = id - 1
        var choice: Node = dropdown.choice_list[adjusted_id]
        required_line_list = choice.line_list

    dynamic_lines_required.emit(required_line_list)


func _on_pressed() -> void :
    print("Option button pressed")
    pass
