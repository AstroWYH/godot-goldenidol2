class_name DecorativePhrase
extends Button

const STYLEBOX_NAME_NORMAL: StringName = &"normal"
const PROPERTY_HOVERSTYLE: StringName = &"theme_override_styles/hover"



@export var type: Phrase.PhraseType = Phrase.PhraseType.NAME:
    set = _set_type


func _ready() -> void :
    mouse_default_cursor_shape = CursorShape.CURSOR_ARROW
    set(
        PROPERTY_HOVERSTYLE, 
        theme.get_stylebox(STYLEBOX_NAME_NORMAL, Phrase.get_theme_variation(type)), 
    )


func set_data_from_item(item: GIItem) -> void :
    text = Phrase.get_tr_key(item, self)
    type = item.meta.type


func _set_type(v: Phrase.PhraseType) -> void :
    type = v

    theme_type_variation = Phrase.get_theme_variation(v)
