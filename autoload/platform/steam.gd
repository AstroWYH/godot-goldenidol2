extends PlatformBase

const APP_ID: int = 2716400


const achievement_map: Dictionary = {

	Achievement.SCEN_ASYLUM: "ASYLUM", 
	Achievement.SCEN_BRIDGE: "BRIDGE", 
	Achievement.SCEN_CONSTRUCTION: "YARD", 
	Achievement.SCEN_CONFERENCE: "CONFERENCE", 
	Achievement.CH_INTRODUCTORY: "CHAPTER_1", 

	Achievement.SCEN_RETREAT: "RETREAT", 
	Achievement.SCEN_PRISON: "PRISON", 
	Achievement.SCEN_DRIVEIN: "DRIVE_IN", 
	Achievement.SCEN_AUCTION: "AUCTION", 
	Achievement.CH_PARTS: "CHAPTER_2", 

	Achievement.SCEN_BURNINGMAN: "BURNING_MAN", 
	Achievement.SCEN_BANNING: "NEIGHBOURHOOD", 
	Achievement.SCEN_EVICTION: "EVICTION", 
	Achievement.CH_RECONSTRUCTION: "CHAPTER_3", 

	Achievement.SCEN_AVIARY: "AVIARY", 
	Achievement.SCEN_TALENTSHOW: "TALENT_SHOW", 
	Achievement.SCEN_DANCE: "DANCE", 
	Achievement.SCEN_GIVEANDTAKE: "COMPLEX", 
	Achievement.CH_RESEARCH: "CHAPTER_4", 

	Achievement.SCEN_BEACH: "BEACH", 
	Achievement.SCEN_BOARDROOM: "BOARDROOM", 
	Achievement.SCEN_MUSEUM: "MUSEUM", 
	Achievement.SCEN_WAREHOUSE: "WAREHOUSE", 
	Achievement.SCEN_FINALE: "FINALE", 
	Achievement.CH_CONCLUSION: "CHAPTER_5", 
}


func init_platform() -> void :
	init_done.emit(PlatformBase.InitResult.SUCCESS)
	#var result: Dictionary = Steam.steamInitEx(true, APP_ID)
	#if result.status != 0:
		#Logger.write_warn("There was an issue connecting with Steam: %s " % result)
		#init_done.emit(PlatformBase.InitResult.FAIL)
		#return
	#init_done.emit(PlatformBase.InitResult.SUCCESS)


func get_user_id() -> String:
	return "128"
	#return str(Steam.getSteamID())


func award_achievement(achievement: Achievement) -> void :
	return
	#if not achievement in achievement_map:
		#Logger.write_warn("Achievement %d not mapped for this platform!" % achievement)
		#return
#
	#Steam.setAchievement(achievement_map[achievement] as String)
	#Steam.storeStats()


func clear_achievements() -> void :
	return
	#for achievement: String in achievement_map.values():
		#Steam.clearAchievement(achievement)
	#Steam.storeStats()
