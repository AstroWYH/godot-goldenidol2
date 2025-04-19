class_name PuzzleComponentData
extends RefCounted

var component: PuzzleComponent
var answers: Array[Array] = []
var is_valid: = false
var validated: bool = false
var value: int:
    get: return component.value
var id: int:
    get: return component.id



func reset_validity() -> void :
    is_valid = component.valid_by_default
    validated = false



func validate(component_map: Dictionary) -> void :
    if validated:

        return
    validated = true


    var most_valid_idx: int = -1
    var most_valid_count: int = -1
    var valid_component_groups: Array = []

    for i in len(answers):
        var answer_group: Array = answers[i]
        var group_valid: = false
        var valid_components: = []
        var valid_count: int = 0

        for answer: Variant in answer_group:
            if answer is PuzzleAnswerDependencyData:
                var dependent_component_data: PuzzleComponentData = component_map[answer.component_id]
                group_valid = dependent_component_data.value == answer.answer_value
                dependent_component_data.validated = true
                if group_valid:
                    valid_count += 1
                    valid_components.append(dependent_component_data)
            else:
                group_valid = value == answer.answer_value
                if group_valid:
                    valid_count += 1
                    valid_components.append(self)

        valid_component_groups.append(valid_components)

        if valid_count > most_valid_count:
            most_valid_idx = i
            most_valid_count = valid_count

        if valid_count == len(answer_group):




            most_valid_idx = i
            break



    if most_valid_idx > -1:
        for component_data: PuzzleComponentData in valid_component_groups[most_valid_idx]:
            component_data.is_valid = true



func unset_local_value() -> void :
    component.local_value = null
