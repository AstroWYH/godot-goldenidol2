extends Node

const CJK_LANGS: Array[String] = [
    "ja", "zh", "ko"
]


enum FocusSide{
    LEFT, 
    RIGHT, 
    ANY, 
    NONE, 
}




const VARIATION_SLOT_NAME: StringName = &"slot_name"
const VARIATION_SLOT_OBJECT: StringName = &"slot_object"
const VARIATION_SLOT_ACTION: StringName = &"slot_action"
const VARIATION_SLOT_SPECIAL: StringName = &"slot_special"
const VARIATION_SLOT_NUMERAL: StringName = &"slot_numeral"
const VARIATION_SLOT_LOCAL: StringName = &"slot_local"


const VARIATION_SLOT_OBJECT_NAME: StringName = &"slot_object_name"
const VARIATION_SLOT_OBJECT_SPECIAL: StringName = &"slot_object_special"
const VARIATION_SLOT_OBJECT_ACTION: StringName = &"slot_object_action"


const VARIATION_SLOT_CHAPTER_NAME: StringName = &"slot_c_name"
const VARIATION_SLOT_CHAPTER_OBJECT: StringName = &"slot_c_object"
const VARIATION_SLOT_CHAPTER_ACTION: StringName = &"slot_c_action"
const VARIATION_SLOT_CHAPTER_SPECIAL: StringName = &"slot_c_special"
const VARIATION_SLOT_CHAPTER_NUMERAL: StringName = &"slot_c_numeral"


const VARIATION_SLOT_CHAPTER_OBJECT_NAME: StringName = &"slot_c_object_name"
const VARIATION_SLOT_CHAPTER_OBJECT_SPECIAL: StringName = &"slot_c_object_special"
const VARIATION_SLOT_CHAPTER_OBJECT_ACTION: StringName = &"slot_c_object_action"




const VARIATION_PHRASE_NAME: StringName = &"phrase_name"
const VARIATION_PHRASE_OBJECT: StringName = &"phrase_object"
const VARIATION_PHRASE_ACTION: StringName = &"phrase_action"
const VARIATION_PHRASE_SPECIAL: StringName = &"phrase_special"
const VARIATION_PHRASE_NUMERAL: StringName = &"phrase_numeral"
const VARIATION_PHRASE_LOCAL: StringName = &"phrase_local"


const VARIATION_PHRASE_OBJECT_NAME: StringName = &"phrase_object_name"
const VARIATION_PHRASE_OBJECT_SPECIAL: StringName = &"phrase_object_special"
const VARIATION_PHRASE_OBJECT_ACTION: StringName = &"phrase_object_action"


const VARIATION_PHRASE_CHAPTER_NAME: StringName = &"phrase_c_name"
const VARIATION_PHRASE_CHAPTER_OBJECT: StringName = &"phrase_c_object"
const VARIATION_PHRASE_CHAPTER_ACTION: StringName = &"phrase_c_action"
const VARIATION_PHRASE_CHAPTER_SPECIAL: StringName = &"phrase_c_special"
const VARIATION_PHRASE_CHAPTER_NUMERAL: StringName = &"phrase_c_numeral"


const VARIATION_PHRASE_CHAPTER_OBJECT_NAME: StringName = &"phrase_c_object_name"
const VARIATION_PHRASE_CHAPTER_OBJECT_SPECIAL: StringName = &"phrase_c_object_special"
const VARIATION_PHRASE_CHAPTER_OBJECT_ACTION: StringName = &"phrase_c_object_action"




const BACKGROUND_OFFSET: Vector2i = Vector2i(-210, -180)

const DEFAULT_SEGMENT_OBSCURE_EXTENT: Vector2 = Vector2i(32, 32)

const USER_ID_LOCAL: String = "local"
