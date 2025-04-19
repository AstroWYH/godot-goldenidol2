extends RefCounted



enum GameStateKey{

    SOLVED_PUZZLES = 0, 



    LAST_LOCATIONS = 1, 


    UNLOCKED_SCENARIOS = 2, 



    PUZZLE_STATES = 3, 


    INVENTORIES = 4, 

    DISCOVERED_CHARACTERS = 5, 


    VISITED_HOTSPOTS = 6, 

    UNLOCKED_PUZZLES = 7, 

    BEATEN_SCENARIOS = 8, 


    ARC_INVENTORIES = 9, 

    SAVE_FILE_VERSION = 10, 


    VISITED_SCENARIOS = 11, 

    VISITED_ARCS = 12, 

    DEMO_ENDING_SHOWN = 13, 

    INTERMISSIONS_SHOWN = 14, 

    ARCS_FINISHED = 15, 

    LOCATIONS_VISITED = 16, 

    HINTS_UNLOCKED = 17, 

    ENDING_CREDITS_SHOWN = 18, 

    TUTORIAL_FINISHED = 19, 

    SNIPPETS_VISITED = 20, 
}


enum SegmentedPuzzleKey{
    DATA = 0, 
    SEGMENTS = 1, 
}

enum SaveFileVersion{
    INITIAL = 1, 
}

const CURRENT_SAVE_VERSION: SaveFileVersion = SaveFileVersion.INITIAL
