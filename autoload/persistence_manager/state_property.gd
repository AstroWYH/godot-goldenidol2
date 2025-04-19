class_name StateProperty
extends RefCounted




const GET_8 = "get_8"
const SET_8 = "store_8"
const GET_VAR = "get_var"
const SET_VAR = "store_var"
const PMConstants: = preload("res://autoload/persistence_manager/constants.gd")


var key: PMConstants.GameStateKey


var get_func: String


var set_func: String


var fallback: Variant


func _init(k: PMConstants.GameStateKey, get_fn: String, set_fn: String, default: Variant) -> void :
    key = k
    get_func = get_fn
    set_func = set_fn
    fallback = default


func store(file: FileAccess, state: Dictionary) -> void :
    file.call(set_func, state.get(key, fallback))






func retrieve(file: FileAccess) -> Array:
    var read_value: Variant = file.call(get_func)
    return [
        read_value, 
        typeof(read_value) == typeof(fallback), 
    ]



static func as_8(k: PMConstants.GameStateKey, default: = 0) -> StateProperty:
    return StateProperty.new(k, GET_8, SET_8, default)


static func as_var(k: PMConstants.GameStateKey, default: Variant) -> StateProperty:
    return StateProperty.new(k, GET_VAR, SET_VAR, default)
