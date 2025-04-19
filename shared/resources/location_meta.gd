@icon("res://shared/assets/icons/location.png")
class_name LocationMeta
extends Resource

enum AudioSideEffect{
    NONE = 0, 
    ACCENTED_MUSIC = 1, 
    ACCENTED_AMBIENCE = 2, 
    MUSIC_MIDS_ONLY = 3, 
}




@export_range(1, 255) var location_id: = 1


@export_file("*.tscn") var path: String


@export var background: Texture2D

@export_group("Background Audio")
@export var audio_side_effect: AudioSideEffect = AudioSideEffect.NONE
@export var music_layers: Array[AudioStream]
@export var ambience_layers: Array[AudioStream]
@export var music_layer_ids: Array[int] = [0]
