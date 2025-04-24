extends Node

const BUS_SFX: StringName = &"SFX"
const MASTER_BUS_IDX: int = 0
const VOL_DEFAULT_PERCENT: float = 100.0
const Constants: = preload("res://autoload/audio_manager/constants.gd")
const Utils: = preload("res://shared/utils/audio.gd")
const TypeUtils: = preload("res://shared/utils/types.gd")
const Sound: = Constants.Sound
const TransitionSound: = Constants.TransitionSound
const SnippetSound: = Constants.SnippetSound
const Transposition: = Constants.Transposition

var current_transposition: Transposition = Transposition.DEFAULT


const PUZZLE_UNLOCK_LOOP_POLYPHONY: int = 1
var puzzle_unlock_loop_instances: Array[int] = []


func _ready() -> void :
	SettingsManager.setting_changed.connect(_on_setting_changed)
	initialize()


func restore_defaults() -> void :
	SettingsManager.set_setting(
		SettingsManager.Keys.SECTION_AUDIO, 
		SettingsManager.Keys.SETTING_VOL_MASTER, 
		VOL_DEFAULT_PERCENT
	)

	SettingsManager.set_setting(
		SettingsManager.Keys.SECTION_AUDIO, 
		SettingsManager.Keys.SETTING_VOL_SFX, 
		VOL_DEFAULT_PERCENT
	)

	initialize()


func initialize() -> void :
	var initial_master_volume: Variant = SettingsManager.get_setting(
		SettingsManager.Keys.SECTION_AUDIO, 
		SettingsManager.Keys.SETTING_VOL_MASTER, 
		VOL_DEFAULT_PERCENT, 
	)

	_set_master_volume_perc(
		clamp(initial_master_volume if TypeUtils.is_numeric(initial_master_volume) else VOL_DEFAULT_PERCENT, 0, 100)
	)

	var initial_sfx_volume: Variant = SettingsManager.get_setting(
		SettingsManager.Keys.SECTION_AUDIO, 
		SettingsManager.Keys.SETTING_VOL_SFX, 
		VOL_DEFAULT_PERCENT, 
	)

	_set_sfx_volume_perc(
		clamp(initial_sfx_volume if TypeUtils.is_numeric(initial_sfx_volume) else VOL_DEFAULT_PERCENT, 0, 100)
	)


func create_player() -> AudioStreamPlayer:
	var player: = AudioStreamPlayer.new()
	player.bus = BUS_SFX

	return player


func play(sound: Sound, params: SoundParams = SoundParams.new()) -> int:
	if (sound == Sound.NONE):
		return 0

	var entry: SoundData = Constants.sound_map[sound]
	var player: = create_player()

	player.name = get_sound_name(sound)
	player.stream = entry.get_audiostream(current_transposition)

	if params.delay > 0:
		await get_tree().create_timer(params.delay).timeout

	player.pitch_scale = params.pitch_scale
	player.pitch_scale += randf_range(params.pitch_range.x, params.pitch_range.y)
	player.volume_db += randf_range(params.volume_range.x, params.volume_range.y)

	add_child(player)

	player.play()
	player.finished.connect(_on_player_finished.bind(player), CONNECT_ONE_SHOT)

	return player.get_instance_id()


func play_transition(sound: TransitionSound, params: SoundParams = SoundParams.new()) -> int:
	return await play(sound as Sound, params)


func play_snippet(sound: SnippetSound, params: SoundParams = SoundParams.new()) -> int:
	return await play(sound as Sound, params)


func play_typewriter(
	character: String, 
	params: SoundParams = SoundParams.new().with_pitch_range(Vector2(-0.05, 0.05)).with_volume_range(Vector2(-2, 2))
	) -> int:
	var sound: Sound

	if character == " ":
		sound = Sound.TYPEWRITER_SPACE
	else:
		sound = Sound.TYPEWRITER_LETTER

	return await play(sound, params)


func play_puzzle_unlock_loop(instance_id: int, params: SoundParams = SoundParams.new()) -> void :
	if puzzle_unlock_loop_instances.has(instance_id):
		return

	if puzzle_unlock_loop_instances.size() < PUZZLE_UNLOCK_LOOP_POLYPHONY:
		play(Sound.PUZZLE_UNLOCK_LOOP, params)

	puzzle_unlock_loop_instances.append(instance_id)


func stop_puzzle_unlock_loop(instance_id: int, fade_out: float = 3.0) -> void :
	puzzle_unlock_loop_instances.erase(instance_id)

	if puzzle_unlock_loop_instances.size() == 0:
		stop_sound(Sound.PUZZLE_UNLOCK_LOOP, fade_out)


func stop(player_id: int, fade_out_time: float = 0.0) -> void :
	for child in get_children():
		if child.get_instance_id() == player_id and child is AudioStreamPlayer:

			child.name = "Stopped"

			var tween: = create_tween()
			tween.finished.connect(child.queue_free)
			tween.set_ease(Tween.EASE_IN)
			tween.set_trans(Tween.TRANS_QUAD)
			tween.tween_property(child, "volume_db", -80, fade_out_time)
			child.tree_exited.connect(tween.kill)


func stop_sound(sound: Sound, fade_out_time: float = 0.0) -> void :
	if not is_playing_sound(sound):
		return

	var players: Array[Node] = get_children().filter(
		func(child: Node) -> bool:
			return child.name == get_sound_name(sound)
	)

	for player in players:
		if player is AudioStreamPlayer:
			stop(player.get_instance_id(), fade_out_time)


func stop_all(fade_out_time: float = 0.0) -> void :
	for child in get_children():
		if child is AudioStreamPlayer:
			stop(child.get_instance_id(), fade_out_time)


func is_playing(player_id: int) -> bool:
	return get_children().any(
		func(child: Node) -> bool:
			return child.get_instance_id() == player_id
	)

func is_playing_sound(sound: Sound) -> bool:
	return get_children().any(
		func(child: Node) -> bool:
			return child.name == get_sound_name(sound)
	)

func get_master_vol_as_perc() -> float:
	return Utils.convert_db_to_perc(AudioServer.get_bus_volume_db(MASTER_BUS_IDX))


func get_sfx_vol_as_perc() -> float:
	return Utils.convert_db_to_perc(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(BUS_SFX)))


func set_transposition(transposition: Transposition) -> void :
	current_transposition = transposition


func _set_master_volume_perc(value: Variant) -> void :
	@warning_ignore("unsafe_call_argument")
	AudioServer.set_bus_volume_db(
		MASTER_BUS_IDX, 
		Utils.convert_perc_to_db(value), 
	)


func _set_sfx_volume_perc(value: Variant) -> void :
	var idx: int = AudioServer.get_bus_index(BUS_SFX)

	@warning_ignore("unsafe_call_argument")
	AudioServer.set_bus_volume_db(
		idx, 
		Utils.convert_perc_to_db(value), 
	)


func _on_setting_changed(section: String, key: String, value: Variant) -> void :
	if section != SettingsManager.Keys.SECTION_AUDIO:
		return

	if key == SettingsManager.Keys.SETTING_VOL_MASTER and TypeUtils.is_numeric(value):
		_set_master_volume_perc(value)
		return

	if key == SettingsManager.Keys.SETTING_VOL_SFX and TypeUtils.is_numeric(value):
		_set_sfx_volume_perc(value)
		return


func _on_player_finished(player: AudioStreamPlayer) -> void :
	player.queue_free()


func get_sound_name(sound: Sound) -> String:
	return Sound.keys()[sound + 1]
