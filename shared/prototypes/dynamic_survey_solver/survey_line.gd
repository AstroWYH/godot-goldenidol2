extends HBoxContainer

signal dynamic_line_required(array: Array)

var option_button_list: Array = []
var generated_line_list: Array = []


func init() -> void :
    for child in get_children():
        if child is OptionButton:
            option_button_list.append(child)
            child.dynamic_lines_required.connect(on_dynamic_line_required)


func on_dynamic_line_required(array: Array) -> void :
    remove_spawned_lines()

    dynamic_line_required.emit(array, self)


func remove_spawned_lines() -> void :
    for line: Node in generated_line_list:
        line.remove_spawned_lines()
        line.queue_free()
    generated_line_list.clear()
