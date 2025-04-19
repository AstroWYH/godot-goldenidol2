extends Control


func _ready() -> void :

    if not ProgressManager.is_scenario_beaten(31):
        return

    var neighborhood_screen: ScenarioHubScreen = % NeighbourhoodScreen

    if neighborhood_screen.focus_mode == FOCUS_ALL:
        return

    var spender_letter_snippet: Control = % SpenderLetterSnippet
    var original_spender_right_neighbor: NodePath = spender_letter_snippet.focus_neighbor_right

    var burning_man_screen: Control = % BurningManScreen
    var original_burning_left_neighbor: NodePath = burning_man_screen.focus_neighbor_left

    spender_letter_snippet.focus_neighbor_right = burning_man_screen.get_path()
    burning_man_screen.focus_neighbor_left = spender_letter_snippet.get_path()

    neighborhood_screen.screen_unlocked.connect(
        func() -> void :
            spender_letter_snippet.focus_neighbor_right = original_spender_right_neighbor
            burning_man_screen.focus_neighbor_left = original_burning_left_neighbor
            , 
        CONNECT_ONE_SHOT
    )
