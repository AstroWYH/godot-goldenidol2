extends Node

const UID_LOCAL = Constants.USER_ID_LOCAL
const Achievement: Dictionary = PlatformBase.Achievement


var _platform: PlatformBase


func _ready() -> void :
	if get_child_count() == 0:

		var user_id: String = UID_LOCAL
		PersistenceManager.configure(user_id)
		SettingsManager.configure(user_id)
		return

	_platform = get_child(0)
	_platform.init_done.connect(_on_init_done, CONNECT_ONE_SHOT)
	_platform.init_platform()
	_validate_achievements()


func award_achievement(achievement: PlatformBase.Achievement) -> void :
	if not _platform:
		return

	if not achievement:
		return

	if achievement == PlatformBase.Achievement.NONE:
		return

	_platform.award_achievement(achievement)


func clear_achievements() -> void :
	if not _platform:
		return
	_platform.clear_achievements()


func is_platform_loaded() -> bool:
	return _platform is PlatformBase


func _on_init_done(result: PlatformBase.InitResult) -> void :

	var user_id: String = _platform.get_user_id() if result == PlatformBase.InitResult.SUCCESS else UID_LOCAL
	PersistenceManager.configure(user_id)
	SettingsManager.configure(user_id)



func _validate_achievements() -> void :
	var achievement_keys: Array[int] = []
	achievement_keys.assign((_platform.achievement_map as Dictionary).keys())

	for key: int in Achievement.values():
		if key == Achievement.NONE:
			continue
		if not key in achievement_keys:
			Logger.write_warn("Unmapped achievement %d for platform." % key)
