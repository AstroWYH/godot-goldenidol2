class_name ArcMeta
extends Resource

@export_range(0, 255) var id: int = 0
@export_multiline var header_label: String
@export var name: String
@export_multiline var description: String
@export_file("*.tscn") var hub_scene_path: String


@export var achievement_id: PlatformBase.Achievement = PlatformBase.Achievement.NONE

@export var music_layers: Array[AudioStream]
@export var ambience_layers: Array[AudioStream]

@export var picture: Texture
@export var hint_meta_list: Array[HintMeta]

@export var autoload_intermission_path: String
