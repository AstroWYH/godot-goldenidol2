extends RefCounted


static func is_numeric(value: Variant) -> bool:
    var typeof_value: int = typeof(value)
    return typeof_value == TYPE_INT or typeof_value == TYPE_FLOAT
