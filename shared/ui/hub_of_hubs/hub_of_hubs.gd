extends Control

@export var music_layers: Array[AudioStream]
@export var ambience_layers: Array[AudioStream]


func _ready() -> void :
    ProgressManager.current_arc_id = -1
    AudioManager.stop_all(1.0)
    MusicPlayer.play_bg_audio(music_layers, ambience_layers)
    MusicPlayer.restore_gain()

    var asylum_focus_target: Control = $Asylum / FocusTarget
    asylum_focus_target.grab_focus()

    PersistenceManager.state_loaded.connect(_on_state_load)

    if has_node("%FastForwardButton"):
        % FastForwardButton.fast_forwarded.connect(_on_ff_confirmed.bind(asylum_focus_target))

    _configure_focus_neighbors()


func _configure_focus_neighbors() -> void :
    var back_button: BaseButton = % BackButton
    var trials_button: BaseButton = % Trials
    var machine_button: BaseButton = % Machine
    var pinnacle_button: BaseButton = % Pinnacle
    var finals_button: BaseButton = % Finals
    var ending_intermission: BaseButton = % EndingIntermission
    var asylum_victory: Control = % AsylumVictoryButto
    var asylum_focus_target: Control = $Asylum / FocusTarget
    var asylum_victory_focus_target: Control = $AsylumVictoryButto / FocusTarget
    var curse_button: BaseButton = % Curse
    var curse_focus_target: Control = curse_button.get_node("FocusTarget")

    if asylum_victory.visible:
        asylum_focus_target.focus_neighbor_right = asylum_victory_focus_target.get_path()
        asylum_victory_focus_target.focus_neighbor_left = asylum_focus_target.get_path()

    if ProgressManager.fast_forward_available():

        var ff_button: Button = % FastForwardButton
        var ff_button_path: NodePath = ff_button.get_path()

        asylum_focus_target.focus_neighbor_bottom = ff_button.get_path()
        ff_button.focus_neighbor_top = asylum_focus_target.get_path()

        if asylum_victory.visible:
            asylum_victory_focus_target.focus_neighbor_bottom = ff_button_path
            ff_button.focus_neighbor_top = asylum_victory_focus_target.get_path()

        if curse_button.visible:
            curse_focus_target.focus_neighbor_right = ff_button_path
            ff_button.focus_neighbor_left = curse_focus_target.get_path()
    else:

        curse_focus_target.focus_neighbor_right = NodePath("")

    if not trials_button.visible and not machine_button.visible:


        var pursuit_focus_target: Control = $Pursuit / FocusTarget
        back_button.focus_neighbor_top = pursuit_focus_target.get_path()
        pursuit_focus_target.focus_neighbor_bottom = back_button.get_path()
        return

    if machine_button.visible:


        var hippie_party_intermission_focus_target: Control = $HippiePartyIntermission / FocusTarget
        back_button.focus_neighbor_top = hippie_party_intermission_focus_target.get_path()
        hippie_party_intermission_focus_target.focus_neighbor_bottom = back_button.get_path()

    if trials_button.visible:


        var asylum_path: NodePath = asylum_focus_target.get_path()
        var trials_focus_target: Control = $Trials / FocusTarget
        var eugene_in_charge_focus_target: Control = $EugeneInChargeIntermission / FocusTarget
        asylum_focus_target.focus_neighbor_top = trials_focus_target.get_path()
        asylum_focus_target.focus_neighbor_left = eugene_in_charge_focus_target.get_path()
        trials_focus_target.focus_neighbor_bottom = asylum_path
        eugene_in_charge_focus_target.focus_neighbor_right = asylum_path

    if pinnacle_button.visible and not finals_button.visible:

        var pinnacle_focus_target: Control = $Pinnacle / FocusTarget
        var pinnacle_path: NodePath = pinnacle_focus_target.get_path()
        curse_focus_target.focus_neighbor_bottom = pinnacle_path
        pinnacle_focus_target.focus_neighbor_top = curse_focus_target.get_path()

    if finals_button.visible:
        var finals_focus_target: Control = $Finals / FocusTarget
        asylum_victory_focus_target.focus_neighbor_right = finals_focus_target.get_path()
        finals_focus_target.focus_neighbor_left = asylum_victory_focus_target.get_path()

    if ending_intermission.visible:
        var ending_intermission_focus_target: Control = $EndingIntermission / FocusTarget
        var lazarus_intermission_focus_target: Control = $LazarusIntermission / FocusTarget
        ending_intermission_focus_target.focus_neighbor_left = lazarus_intermission_focus_target.get_path()
        lazarus_intermission_focus_target.focus_neighbor_right = ending_intermission_focus_target.get_path()


func _on_state_load(_new_state: Dictionary) -> void :
    call_deferred("_configure_focus_neighbors")


func _on_ff_confirmed(focus_target: Control) -> void :
    $Asylum.mark_beaten()
    % Curse.mark_beaten()
    focus_target.call_deferred(&"grab_focus")
