@tool
extends Control

@export var answer_item_ref_id: int:
    set = set_answer_item_ref_id


@export_flags(
    "Name:1", 
    "Object:2", 
    "Action:4", 
    "Special:8", 
    "Numeral:16", 
    "Local:32", 
) var override_accepted_types: int = 0:
    set = set_override_accepted_types

var slotted_id: int:
    get: return 0 if not phrase_slot else phrase_slot.slotted_id
var _item_types: Array[GIItem.PhraseType] = []

@onready var phrase_slot: = $PhraseSlot


func _ready() -> void :
    set_answer_item_ref_id(answer_item_ref_id)
    set_override_accepted_types(override_accepted_types)
    mouse_entered.connect(_on_mouse_entered)


func set_answer_item_ref_id(v: int) -> void :
    answer_item_ref_id = v

    if not answer_item_ref_id or not phrase_slot:
        return

    var item: GIItem = Database.get_item_by_id(answer_item_ref_id)
    _item_types = [item.meta.type]

    if not override_accepted_types:
        phrase_slot.accepted_types = _item_types

    phrase_slot.debug_hint = item.name


func set_override_accepted_types(flags: int) -> void :
    override_accepted_types = flags
    var parsed_types: Array[GIItem.PhraseType] = []
    for key: int in GIItem.PHRASE_TYPE_FLAG_MAP:
        if flags & key == key:
            parsed_types.append(GIItem.PHRASE_TYPE_FLAG_MAP[key])

    if not phrase_slot:
        return
    phrase_slot.accepted_types = parsed_types if parsed_types.size() else _item_types if _item_types.size() else []


func add_puzzle_component(puzzle_component_id: int, slotted_item_id: int, infinite: bool) -> void :
    phrase_slot.into_puzzle_component(puzzle_component_id, answer_item_ref_id, slotted_item_id, infinite)


func free_draggable(emit_unslotted: bool = false, unset_read_only: bool = false) -> void :
    phrase_slot.free_draggable(emit_unslotted, unset_read_only)


func get_phrase_slot_button() -> Button:
    return phrase_slot.button


func _on_mouse_entered() -> void :
    if focus_mode != FOCUS_ALL:
        return
    grab_focus()
