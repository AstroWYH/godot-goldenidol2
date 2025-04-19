extends Node



static func is_valid_bitflag(number: int) -> bool:
    return number > 0 and floor(log(number) / log(2)) == log(number) / log(2)



static func flag_on(state: int, flag: int) -> int:
    return state | flag



static func flag_off(state: int, flag: int) -> int:
    return state & ~ flag



static func flag_state(state: int, flag: int) -> bool:
    return state & flag == flag



static func flag_on_pos(state: int, pos: int) -> int:
    return state | (1 << pos)



static func flag_state_pos(state: int, pos: int) -> bool:
    var flag: int = 1 << pos
    return state & (flag) == flag
