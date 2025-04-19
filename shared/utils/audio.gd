extends RefCounted


static func convert_db_to_perc(db: float) -> float:
    return db_to_linear(db) * 100


static func convert_perc_to_db(perc: float) -> float:
    return linear_to_db(perc / 100)


static func linear_vol_setter(player: Object) -> Callable:
    return func(input: float) -> void : player.volume_db = linear_to_db(input)
