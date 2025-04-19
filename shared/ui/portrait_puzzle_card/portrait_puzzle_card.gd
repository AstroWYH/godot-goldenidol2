@tool
class_name PortraitPuzzleCard
extends Control

const UNKNOWN_PERSON: Texture2D = preload("res://shared/assets/placeholder_ui/portrait_empty.png")

var discovered: = false:
    set = set_discovered

@export var link_character_ref_id: int:
    set = set_character_ref

@export var custom_portrait: Texture2D:
    set = set_custom_portrait

var first_name_puzzle_component_id: int:
    set = set_first_name_puzzle_component_id

var last_name_puzzle_component_id: int:
    set = set_last_name_puzzle_component_id

var _character: GICharacter

@onready var portrait: TextureRect = get_node("%Portrait")
@onready var first_name_slot: PhraseSlot = get_node("%FirstNamePhraseSlot")
@onready var last_name_slot: PhraseSlot = get_node("%LastNamePhraseSlot")
@onready var first_name_puzzle_component: PuzzleComponent = get_node("%FirstNamePuzzleComponent")
@onready var last_name_puzzle_component: PuzzleComponent = get_node("%LastNamePuzzleComponent")
@onready var first_name_answer: PuzzleAnswerItem = get_node("%FirstNamePuzzleAnswerItem")
@onready var last_name_answer: PuzzleAnswerItem = get_node("%LastNamePuzzleAnswerItem")


func _ready() -> void :
    set_character_ref(link_character_ref_id)
    set_discovered(discovered)

    if not Engine.is_editor_hint():
        first_name_slot.accepted_types = [GIItem.PhraseType.NAME]
        first_name_puzzle_component.connect_drop_receiver(first_name_slot.drop_receiver as DropReceiver)
        first_name_slot.button_focus_neighbor_bottom = last_name_slot.get_button_path()

        last_name_slot.accepted_types = [GIItem.PhraseType.NAME]
        last_name_puzzle_component.connect_drop_receiver(last_name_slot.drop_receiver as DropReceiver)
        last_name_slot.button_focus_neighbor_top = first_name_slot.get_button_path()


func set_discovered(v: bool) -> void :
    discovered = true if Engine.is_editor_hint() else v
    _handle_discovered()


func set_character_ref(v: int) -> void :
    link_character_ref_id = v

    if not portrait:
        return

    if not v:
        _character = null
        _handle_discovered()
        return

    _character = Database.get_character_by_id(v)

    if not _character:
        push_error("character id %d does not exist!" % v)
        return

    first_name_answer.answer_item_ref_id = _character.first_name_phrase_id
    last_name_answer.answer_item_ref_id = _character.last_name_phrase_id

    if Engine.is_editor_hint():
        first_name_slot.debug_hint = Database.get_item_by_id(_character.first_name_phrase_id).name
        last_name_slot.debug_hint = Database.get_item_by_id(_character.last_name_phrase_id).name

    _handle_discovered()


func set_custom_portrait(v: Texture2D) -> void :
    custom_portrait = v
    _handle_discovered()


func set_first_name_puzzle_component_id(v: int) -> void :
    first_name_puzzle_component_id = v
    if first_name_puzzle_component and not Engine.is_editor_hint():
        first_name_puzzle_component.id = v


func add_first_name_item(item_id: int) -> void :
    first_name_slot.add_slotted_item(item_id)
    first_name_puzzle_component.local_value = item_id


func add_last_name_item(item_id: int) -> void :
    last_name_slot.add_slotted_item(item_id)
    last_name_puzzle_component.local_value = item_id


func set_last_name_puzzle_component_id(v: int) -> void :
    last_name_puzzle_component_id = v
    if last_name_puzzle_component and not Engine.is_editor_hint():
        last_name_puzzle_component.id = v


func clear() -> void :

    discovered = false
    first_name_puzzle_component.drop_receiver.free_draggable(true, true)
    last_name_puzzle_component.drop_receiver.free_draggable(true, true)
    ProgressManager.forget_character(link_character_ref_id)


func request_focus(side: Constants.FocusSide) -> Variant:
    var nodes: Array[Node] = [
        first_name_slot.request_focus(), 
        last_name_slot.request_focus(), 
    ]
    return NodeUtils.get_node_for_side(side, nodes)


func set_first_name_slot_focus_neighbor(side: Side, neighbor_path: NodePath) -> void :
    first_name_slot.set_button_focus_neighbor(side, neighbor_path)


func set_last_name_slot_focus_neighbor(side: Side, neighbor_path: NodePath) -> void :
    last_name_slot.set_button_focus_neighbor(side, neighbor_path)


func get_first_name_slot_path() -> NodePath:
    return first_name_slot.get_button_path()


func get_last_name_slot_path() -> NodePath:
    return last_name_slot.get_button_path()


func _handle_discovered() -> void :
    if not _character or not discovered:
        if portrait:
            portrait.texture = UNKNOWN_PERSON
        if first_name_slot:
            first_name_slot.hide()
        if last_name_slot:
            last_name_slot.hide()
    else:
        if portrait:
            portrait.texture = custom_portrait if custom_portrait else load(_character.portrait)
        if first_name_slot:
            first_name_slot.show()
        if last_name_slot:
            last_name_slot.show()
