extends Control
class_name SurveyPuzzle


var line_dict: = {}
var dropdown_dict: = {}

var line_list: Array = []
var dropdown_list: Array = []
var generated_lines: Array
@onready var line_container: = $ColorRect / VBoxContainer

func _ready() -> void :



    line_dict = {

        "deceased_name": new_line(["The person who has died is ", "*names", "*names"]), 
        "instrument_of_death": new_line(["The cause of death is ", "*instruments"]), 
        "nature_of_death": new_line(["This death was ", "*nature"]), 



        "illness_type": new_line(["The illness was ", "*illness_cause"]), 




        "accident_cause": new_line(["The cause of the accident was ", "*accident_cause"]), 
        "accident_malfunction": new_line(["The thing that malfunctioned was ", "*items"]), 


        "other_illness": new_line(["Which was ", "*other_illness"]), 


        "suicide_motive": new_line(["The suicide was comitted ", "*suicide_cause"]), 
        "suicide_protection_target": new_line(["The victim wanted to protect ", "*names"]), 
        "suicide_romantic_target": new_line(["The victim had strong feelings for ", "*names"]), 


        "killer_name": new_line(["The killer was ", "*names", "*names"]), 
        "killer_motive": new_line(["The victim was killed ", "*killing_motive"]), 


        "killers_jealousy": new_line(["The killers object of jealousy was ", "*names"]), 


        "punishment_reason": new_line(["The victim was punished for ", "*punishment_motive"]), 
        "what_stolen": new_line(["The stolen thing was ", "*items"]), 
        "who_was_killed": new_line(["The killed person was ", "*names", "*names", "*names"]), 
        "task": new_line(["The task was to ", "*prevent_help", "*names", "*names", "*actions", "*items"]), 


        "orderers_name": new_line(["The person who gave the order was ", "*names", "*names"]), 
        "orderers_motivation": new_line(["The person who gave the order did it ", "*killing_motive"]), 


        "wanted_thing": new_line(["The killer wanted to get ", "*items"]), 


        "hid_thing": new_line(["The killer wanted to hide that", "*names", "*names", "*actions", "*items"]), 


        "revenge_line": new_line(["The killer was taking revenge because", "*names", "*names", "*actions", "*items"]), 
    }



    dropdown_dict = {






























        "*actions": new_dropdown([
            new_choice("steal", []), 
            new_choice("escape", []), 
            new_choice("kill", []), 
            new_choice("seduce", []), 
        ]), 

        "*prevent_help": new_dropdown([
            new_choice("prevent", []), 
            new_choice("help", []), 
        ]), 

        "*instruments": new_dropdown([
            new_choice("physical injury.", []), 
            new_choice("electric shock.", []), 
            new_choice("thermal injury.", []), 
            new_choice("ingestion of toxic substance.", []), 
            new_choice("suffocation.", []), 
        ]), 

        "*nature": new_dropdown([
            new_choice("an accident", [line_dict.accident_cause]), 
            new_choice("an illness", [line_dict.illness_type]), 
            new_choice("a suicide", [line_dict.suicide_motive]), 
            new_choice("a killing", [line_dict.killer_name, line_dict.killer_motive]), 
        ]), 

        "*accident_cause": new_dropdown([
            new_choice("technical malfunctioning", [line_dict.accident_malfunction]), 
            new_choice("the victim not knowing crucial information", []), 
            new_choice("the victim just happening to be in the wrong place and time", []), 
        ]), 

        "*illness_cause": new_dropdown([
            new_choice("a heart attack", []), 
            new_choice("a stroke", []), 
            new_choice("a cancer", []), 
            new_choice("a respiratory disease", []), 
            new_choice("diabetes", []), 
        ]), 

        "*other_illness": new_dropdown([
            new_choice("???", []), 
        ]), 

        "*suicide_cause": new_dropdown([
            new_choice("because of a mental disorder", []), 
            new_choice("because of a physical suffering", []), 
            new_choice("to protect someone", [line_dict.suicide_protection_target]), 
            new_choice("because of financial troubles", []), 
            new_choice("because of unfortunate love", [line_dict.suicide_romantic_target]), 
        ]), 

        "*killing_motive": new_dropdown([
            new_choice("out of jealousy", [line_dict.killers_jealousy]), 
            new_choice("as a punishment", [line_dict.punishment_reason]), 
            new_choice("in self-defense", []), 
            new_choice("on orders of someone else", [line_dict.orderers_name, line_dict.orderers_motivation]), 
            new_choice("to get something from the victim", [line_dict.wanted_thing]), 
            new_choice("to hide something", [line_dict.hid_thing]), 
            new_choice("out of revenge", [line_dict.revenge_line]), 
        ]), 

        "*punishment_motive": new_dropdown([
            new_choice("stealing something", [line_dict.what_stolen]), 
            new_choice("killing someone", [line_dict.who_was_killed, line_dict.killer_motive]), 
            new_choice("failing to perform a task", [line_dict.task]), 
        ]), 
    }

    _init()


func _init() -> void :
    generate_line(line_dict.deceased_name)
    generate_line(line_dict.deceased_name)
    generate_line(line_dict.instrument_of_death)
    generate_line(line_dict.nature_of_death)


func new_choice(passed_name: String, passed_line_list: Array = []) -> ChoiceData:
    var choice: = ChoiceData.new()
    choice.choice_name = passed_name
    choice.line_list = passed_line_list
    return choice


func new_dropdown(choice_list: Array) -> DropdownData:
    var dropdown: = DropdownData.new()
    for choice: ChoiceData in choice_list:
        dropdown.choice_list.append(choice)
    return dropdown


func new_line(element_list: Array) -> LineData:
    var line: = LineData.new()
    for element: Variant in element_list:
        line.element_list.append(element)
    return line


func generate_line(required_line: Variant) -> Control:
    var new_line_scene: HBoxContainer = load("res://shared/prototypes/dynamic_survey_solver/survey_line.tscn").instantiate()
    var generated_line: Variant = required_line
    line_container.add_child(new_line_scene)
    new_line_scene.dynamic_line_required.connect(_on_dynamic_line_required)

    for element: Variant in generated_line.element_list:
        if element is String:
            if not element.begins_with("*"):
                var new_label: = Label.new()
                new_label.text = element
                new_line_scene.add_child(new_label)

            else:
                var option_button_scene: OptionButton = load("res://shared/prototypes/dynamic_survey_solver/survey_option.tscn").instantiate()
                var generated_dropdown: Variant = dropdown_dict[element]

                option_button_scene.add_item("---")
                for choice: Variant in generated_dropdown.choice_list:
                    option_button_scene.add_item(choice.choice_name)

                option_button_scene.dropdown = generated_dropdown
                new_line_scene.add_child(option_button_scene)
    new_line_scene.init()
    generated_lines.append(new_line_scene)
    return new_line_scene


func _on_dynamic_line_required(array: Array, line_that_required: Variant) -> void :
    print("dynamic line required call at solver: ", array)
    for ref: Variant in array:
        var generated_line: = generate_line(ref)
        line_that_required.generated_line_list.append(generated_line)
