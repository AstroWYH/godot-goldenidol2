class_name NounMarker
extends Label



enum NounMarkerType{
    PRONOUN, 
    ARTICLE
}


const ALLOWED_KEYS = [
    "personal_first_person", 
    "personal_third_person", 
    "reflexive", 
    "possessive", 
    "independent_possessive", 
]

@export var marker_type: NounMarkerType

@export var for_id: int

@export var fallback: String


@export var pronoun_key: String:
    set = _set_pronoun_key


func _set_pronoun_key(v: String) -> void :
    pronoun_key = v

    if v not in ALLOWED_KEYS and not Engine.is_editor_hint():
        Logger.write_err("Invalid pronoun_key %s" % v)
