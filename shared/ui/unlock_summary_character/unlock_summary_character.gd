extends HBoxContainer

@export var character_id: int


func _ready() -> void :
    var texture: Variant = ProgressManager.portrait_overrides.get(character_id)

    if not texture is Texture2D:
        texture = load((Database.get_character_by_id(character_id) as GICharacter).portrait)

    ($Portrait as TextureRect).texture = texture
