extends Node


signal sequence_element_requested(id: String)

enum ElementState{
    ACTIVE = 0, 
    INACTIVE = 1, 
    UNSEQUENCED = 2, 
    HEAD = 3, 
}

const ID_DELIM: = ":"
const SequenceHead: = GISequence.SequenceHead


var _sequences: Dictionary = {}


var _sequence_elements: Dictionary = {}


func _ready() -> void :
    ProgressManager.scenario_beaten.connect(_on_scenario_beaten)
    PersistenceManager.state_reset.connect(initialize)
    PersistenceManager.state_loaded.connect(func(_state: Dictionary) -> void : initialize())


func initialize() -> void :
    _sequences.clear()
    _sequence_elements.clear()

    for child_node: Node in get_children():
        if not child_node is GISequence:
            continue

        var gi_sequence: GISequence = child_node

        if not gi_sequence.scenario_meta:
            continue

        var id: int = gi_sequence.scenario_meta.id


        if ProgressManager.is_scenario_beaten(id):
            continue


        var data: = GISequenceData.new()
        var head_type: SequenceHead = SequenceHead.SCENARIO
        var seq: Array[String] = gi_sequence.sequence.duplicate()
        var new_id: String = _create_seq_id(head_type, str(id))

        seq.reverse()

        data.id = new_id
        data.head_type = head_type
        data.sequence = seq
        data.current_element = seq[len(seq) - 1]



        data.active = false

        for el: String in seq:
            var existing_refs: Variant = _sequence_elements.get(el)
            if existing_refs is Array:
                existing_refs.append(data)
            else:
                var new_arr: Array[GISequenceData] = [data]
                _sequence_elements[el] = new_arr

        var existing_seq: Variant = _sequences.get(new_id)
        if existing_seq is Array:
            existing_seq.append(data)
        else:
            var new_arr: Array[GISequenceData] = [data]
            _sequences[new_id] = new_arr



func get_element_state(id: String) -> ElementState:
    var data_arr: Variant = _sequence_elements.get(id)

    if not data_arr is Array:



        return ElementState.UNSEQUENCED

    for data: GISequenceData in data_arr:
        if id == data.current_element and data.active:

            return ElementState.HEAD

        if data.active:

            return ElementState.ACTIVE


    return ElementState.INACTIVE




func is_element_active(id: String) -> bool:
    var state: = get_element_state(id)
    return state == ElementState.ACTIVE or state == ElementState.HEAD



func mark_handled(id: String) -> void :
    var element_data_var: Variant = _sequence_elements.get(id)

    if not element_data_var is Array:
        return

    var element_data: Array[GISequenceData] = element_data_var as Array[GISequenceData]

    if len(element_data) <= 1:

        _sequence_elements.erase(id)

    var new_elements: Array[String] = []
    var completed_sequences: Array[String] = []

    for element: GISequenceData in element_data:
        if element.current_element != id or not element.active:


            continue

        var new_elem: Variant = element.sequence.pop_back()

        if new_elem == id:

            new_elem = element.sequence.pop_back()


        if not new_elem is String:

            var seq_id: String = element.id
            _sequences.erase(seq_id)
            completed_sequences.append(seq_id)
            return

        element.current_element = new_elem
        new_elements.append(new_elem)

    if len(completed_sequences):

        _sequence_elements[id] = element_data.filter(
            func(data: GISequenceData) -> bool: return data.id not in completed_sequences
        )

    for new_elem in new_elements:
        sequence_element_requested.emit(new_elem)


func _create_seq_id(type: SequenceHead, id: String) -> String:
    return "%s%s%s" % [type, ID_DELIM, id]


func _on_scenario_beaten(scenario_id: int, _puzzle_meta: PuzzleMeta) -> void :

    var data_arr: Variant = _sequences.get(_create_seq_id(
        SequenceHead.SCENARIO, 
        str(scenario_id)
    ))

    if not data_arr is Array:
        return

    for data: GISequenceData in data_arr:
        data.active = true


class GISequenceData:
    var head_type: GISequence.SequenceHead


    var id: String

    var active: bool = false


    var current_element: String


    var sequence: Array[String] = []
