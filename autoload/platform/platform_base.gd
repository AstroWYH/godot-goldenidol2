class_name PlatformBase
extends Node





signal init_done(result: InitResult)

enum InitResult{
	SUCCESS, 
	FAIL
}


enum Achievement{
	NONE = 0, 


	SCEN_ASYLUM = 1, 
	SCEN_BRIDGE = 2, 
	SCEN_CONSTRUCTION = 3, 
	SCEN_CONFERENCE = 4, 
	CH_INTRODUCTORY = 5, 

	SCEN_RETREAT = 6, 
	SCEN_PRISON = 7, 
	SCEN_DRIVEIN = 8, 
	SCEN_AUCTION = 9, 
	CH_PARTS = 10, 

	SCEN_BURNINGMAN = 11, 
	SCEN_BANNING = 12, 
	SCEN_EVICTION = 13, 
	CH_RECONSTRUCTION = 14, 

	SCEN_AVIARY = 15, 
	SCEN_DANCE = 16, 
	SCEN_TALENTSHOW = 17, 
	SCEN_GIVEANDTAKE = 18, 
	CH_RESEARCH = 19, 

	SCEN_BOARDROOM = 20, 
	SCEN_BEACH = 21, 
	SCEN_MUSEUM = 22, 
	SCEN_WAREHOUSE = 23, 
	SCEN_FINALE = 24, 
	CH_CONCLUSION = 25, 
}



func init_platform() -> void :
	init_done.emit(InitResult.SUCCESS)



func get_user_id() -> String:
	return Constants.USER_ID_LOCAL


func award_achievement(_achievement: Achievement) -> void :
	pass


func clear_achievements() -> void :
	pass
