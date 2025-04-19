extends RefCounted
class_name SoundData

var default_path: String
var transposed_paths: Dictionary

static func create(
    p_default_path: String = "", 
    p_transposed_paths: Dictionary = {}
) -> SoundData:
    var sound_data: = SoundData.new()

    sound_data.default_path = p_default_path
    sound_data.transposed_paths = p_transposed_paths

    return sound_data


func get_audiostream(
    transposition: AudioManager.Transposition = AudioManager.Transposition.DEFAULT
) -> AudioStream:
    var path: String = transposed_paths[transposition] if transposed_paths.keys().has(transposition) else default_path
    var stream: AudioStream = load(path)

    if not stream is AudioStream:
        push_error("No AudioStream at path: " + path)

    return stream
