extends Node





signal state_loaded(new_state: Dictionary)
signal state_reset

const SAVE_FILENAME: = "game.sav"
const Properties: = preload("res://autoload/persistence_manager/properties.gd")
const PMConstants: = preload("res://autoload/persistence_manager/constants.gd")
const GameStateKey: = PMConstants.GameStateKey
const SegmentedPuzzleKey: = PMConstants.SegmentedPuzzleKey
const SAVE_TIMER_SEC_MAX: int = 1

var save_path: String = ""
var state: Dictionary = {}
var _save_timer: float = 0
var _is_state_changed: bool = false

@onready var store_order: Array[StateProperty] = Properties.store_order


func _process(delta: float) -> void :
	_save_timer = max(0, _save_timer - delta)

	if _save_timer <= 0 and _is_state_changed:
		commit_gamestate()


func _notification(what: int) -> void :
	if not what == NOTIFICATION_WM_CLOSE_REQUEST:
		return
	commit_gamestate()



func flag_status(key: GameStateKey, flag: int) -> bool:
	return FlagsUtils.flag_state(state.get(key, 0) as int, flag)



func flag_on(key: GameStateKey, flag: int) -> void :
	state[key] = FlagsUtils.flag_on(state.get(key, 0) as int, flag)
	mark_state_changed()



func configure(new_user_id: String) -> void :
	var prefix: = "user://%s" % new_user_id
	save_path = "%s/%s" % [prefix, SAVE_FILENAME]

	if not DirAccess.dir_exists_absolute(prefix):
		DirAccess.make_dir_absolute(prefix)

	load_gamestate()


func mark_state_changed() -> void :
	_reset_timer()
	_is_state_changed = true


func commit_gamestate() -> void :
	_is_state_changed = false

	var flags: = FileAccess.WRITE
	var file: = FileAccess.open(save_path, flags)

	if not file:
		_report_file_error(flags)
		return

	state[GameStateKey.SAVE_FILE_VERSION] = PMConstants.CURRENT_SAVE_VERSION

	for prop in store_order:
		prop.store(file, state)

	file.close()


func savestate_exists() -> bool:
	if FileAccess.file_exists(save_path):
		return true
	else:
		return false



func fast_forward() -> void :
	load_gamestate("res://shared/data/state_backup_intro_arc.res")

	for achievement: PlatformBase.Achievement in [
		PlatformBase.Achievement.SCEN_ASYLUM, 
		PlatformBase.Achievement.SCEN_BRIDGE, 
		PlatformBase.Achievement.SCEN_CONSTRUCTION, 
		PlatformBase.Achievement.SCEN_CONFERENCE, 
		PlatformBase.Achievement.CH_INTRODUCTORY, 
	]:
		Platform.award_achievement(achievement)

	mark_state_changed()


func load_gamestate(path: String = save_path) -> void :
	var new_state: = {}

	if not FileAccess.file_exists(path):
		for prop in store_order:
			new_state[prop.key] = _duplicate_value(prop.fallback)
		_post_load(new_state)
		return

	var flags: = FileAccess.READ

	if path.find("res://") == 0:

		var res: StateBackup = ResourceLoader.load(path)
		_post_load(res.state)
		return

	var file: = FileAccess.open(path, flags)

	if not file:
		_report_file_error(flags)
		return

	for prop in store_order:
		var retrieve_result: = prop.retrieve(file)
		var value: Variant = retrieve_result[0]
		var retrieve_success: bool = retrieve_result[1]
		var prop_key: = prop.key

		if not retrieve_success:
			Logger.write_err("Error deserializing save key %s. Setting fallback." % prop_key)
			value = _duplicate_value(prop.fallback)

		new_state[prop_key] = value

	file.close()
	_post_load(new_state)






func remove_save_file() -> void :
	if not FileAccess.file_exists(save_path):
		return

	DirAccess.remove_absolute(save_path)
	load_gamestate()
	state_reset.emit()


func _duplicate_value(v: Variant) -> Variant:
	if v is Array or v is Dictionary:
		return v.duplicate(true)

	if v is String:
		return String(v as String)

	return v


func _report_file_error(access_flags: int) -> void :
	var global_path: = ProjectSettings.globalize_path(save_path)
	Logger.write_err("Error opening save file at %s (flags: %s, code %s)!" % [
		 global_path, 
		 access_flags, 
		 FileAccess.get_open_error(), 
	 ])


func _reset_timer() -> void :
	_save_timer = SAVE_TIMER_SEC_MAX


func _post_load(new_state: Dictionary) -> void :
	state = new_state
	state_loaded.emit(new_state)
