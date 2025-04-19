@icon("res://shared/assets/icons/scenario.png")
class_name ScenarioMeta
extends Resource

const GameStateConstants: = preload("res://autoload/persistence_manager/constants.gd")



@export var arc: ArcMeta


@export_range(0, 4095) var id: int = 0


@export var name: String


@export var description: String


@export_file("*.tscn") var path: String




@export var locations: Array[LocationMeta] = []


@export var required_puzzles: Array[PuzzleMeta] = []


@export var max_spots: int = 999


@export_group("Phrases")
@export var phrases_name: int = 0
@export var phrases_object: int = 0
@export var phrases_action: int = 0
@export var phrases_special: int = 0
@export var phrases_numeral: int = 0
@export var phrases_local: int = 0

@export_group("Victory")
@export_multiline var victory_screen_text: String = ""
@export var victory_picture_path: String = ""
@export var custom_victory_dialog_path: String
@export var custom_hub_victory_dialog_path: String
@export var victory_unlocks_segments: Array[PuzzleSegmentUnlock] = []
@export var victory_unlocks_arc_phrases: Array[PhraseGridItem] = []


@export var achievement_id: PlatformBase.Achievement = PlatformBase.Achievement.NONE
@export var intermission_path_on_victory: String


@export_group("Background Audio")
@export var intro_music: Array[AudioStream]
@export var loop_music: Array[AudioStream]
@export var ambience: Array[AudioStream]
@export var escalation_layer_ids: Array[int]
@export var stop_existing_music_on_escalation: bool
@export var oneshot_layer_ids: Array[int]
@export var sfx_transposition: AudioManager.Transposition = AudioManager.Transposition.DEFAULT

@export_group("Hints")
@export var picture: Texture
@export var hint_meta_list: Array[HintMeta]

@export_group("Customization")
@export var no_inventory: bool = false
