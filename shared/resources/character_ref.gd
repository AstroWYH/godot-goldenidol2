@tool
class_name GICharacterRef
extends Resource

@export var link_character_ref_id: int:
    set(v):
        if link_character_ref_id != v:
            link_character_ref_id = v
            emit_changed()
