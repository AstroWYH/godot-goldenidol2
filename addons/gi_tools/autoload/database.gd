@tool
extends Node

const ITEM_DATABASE_PATH: = "res://shared/data/items.tres"
const CHARACTER_DATABASE_PATH: = "res://shared/data/characters.tres"
const ITEM_TR_SEP = "|"
const ITEM_TR = "DB_%d"
const ITEM_TR_PREFIX_ARC = "ARC"
var item_database: GIItemDatabase = preload(ITEM_DATABASE_PATH)
var character_database: GICharacterDatabase = preload(CHARACTER_DATABASE_PATH)



func get_items() -> Array[GIItem]:
    return item_database.data as Array[GIItem]


func get_characters() -> Array[GICharacter]:
    return character_database.data as Array[GICharacter]


func get_item_by_id(item_id: int) -> Variant:
    return item_database.data[item_database.index[item_id]]


func get_character_by_id(item_id: int) -> Variant:
    return character_database.data[character_database.index[item_id]]



func reload_items() -> void :
    item_database = ResourceLoader.load(ITEM_DATABASE_PATH)


func reload_characters() -> void :
    character_database = ResourceLoader.load(CHARACTER_DATABASE_PATH)



func get_translation_id(item: GIItem) -> String:
    return ITEM_TR % item.id


func get_composite_translation_id(scenario_id: int, item: GIItem) -> String:
    return "%d%s%s" % [scenario_id, ITEM_TR_SEP, get_translation_id(item)]


func get_composite_arc_translation_id(arc_id: int, item: GIItem) -> String:
    var prefix: String = "%s%d" % [ITEM_TR_PREFIX_ARC, arc_id]
    return "%s%s%s" % [prefix, ITEM_TR_SEP, get_translation_id(item)]
