extends RefCounted

const PMConstants: = preload("res://autoload/persistence_manager/constants.gd")




static  var store_order: Array[StateProperty] = [

    StateProperty.as_8(
        PMConstants.GameStateKey.SAVE_FILE_VERSION, 
        PMConstants.CURRENT_SAVE_VERSION, 
    ), 

    StateProperty.as_var(PMConstants.GameStateKey.SOLVED_PUZZLES, []), 
    StateProperty.as_var(PMConstants.GameStateKey.BEATEN_SCENARIOS, []), 
    StateProperty.as_var(PMConstants.GameStateKey.UNLOCKED_SCENARIOS, [11, 12, 21, 31, 41, 52, 61, 71, 81, 91]), 
    StateProperty.as_var(PMConstants.GameStateKey.UNLOCKED_PUZZLES, []), 

    StateProperty.as_var(PMConstants.GameStateKey.PUZZLE_STATES, {}), 
    StateProperty.as_var(PMConstants.GameStateKey.LAST_LOCATIONS, {}), 
    StateProperty.as_var(PMConstants.GameStateKey.INVENTORIES, {}), 
    StateProperty.as_var(PMConstants.GameStateKey.ARC_INVENTORIES, {}), 
    StateProperty.as_var(PMConstants.GameStateKey.DISCOVERED_CHARACTERS, []), 

    StateProperty.as_var(PMConstants.GameStateKey.VISITED_HOTSPOTS, {}), 
    StateProperty.as_var(PMConstants.GameStateKey.VISITED_SCENARIOS, []), 
    StateProperty.as_var(PMConstants.GameStateKey.VISITED_ARCS, []), 
    StateProperty.as_var(PMConstants.GameStateKey.DEMO_ENDING_SHOWN, false), 
    StateProperty.as_var(PMConstants.GameStateKey.INTERMISSIONS_SHOWN, []), 
    StateProperty.as_var(PMConstants.GameStateKey.ARCS_FINISHED, []), 
    StateProperty.as_var(PMConstants.GameStateKey.LOCATIONS_VISITED, {}), 
    StateProperty.as_var(PMConstants.GameStateKey.HINTS_UNLOCKED, []), 
    StateProperty.as_var(PMConstants.GameStateKey.ENDING_CREDITS_SHOWN, false), 
    StateProperty.as_var(PMConstants.GameStateKey.TUTORIAL_FINISHED, false), 
    StateProperty.as_var(PMConstants.GameStateKey.SNIPPETS_VISITED, []), 
]
