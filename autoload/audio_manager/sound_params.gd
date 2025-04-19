class_name SoundParams

var delay: float
var pitch_scale: float
var pitch_range: Vector2
var volume_range: Vector2


func _init(
    p_delay: float = 0, 
    p_pitch_scale: float = 1, 
    p_pitch_range: Vector2 = Vector2(0, 0), 
    p_vol_range: Vector2 = Vector2(0, 0), 
) -> void :
    delay = p_delay
    pitch_scale = p_pitch_scale
    pitch_range = p_pitch_range
    volume_range = p_vol_range


func with_delay(p_delay: float) -> SoundParams:
    delay = p_delay

    return self


func with_pitch_scale(p_pitch_scale: float) -> SoundParams:
    pitch_scale = p_pitch_scale

    return self


func with_pitch_range(p_pitch_range: Vector2) -> SoundParams:
    pitch_range = p_pitch_range

    return self


func with_volume_range(p_vol_range: Vector2) -> SoundParams:
    volume_range = p_vol_range

    return self
