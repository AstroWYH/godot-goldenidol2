extends Node

enum PlayerGroup{
    MUSIC, 
    AMBIENCE
}

enum FilterType{
    HIGHPASS, 
    LOWPASS, 
}

enum EffectType{
    HIGHPASS = FilterType.HIGHPASS, 
    LOWPASS = FilterType.LOWPASS, 
    GAIN, 
}

const Utils: = preload("res://shared/utils/audio.gd")
const TypeUtils: = preload("res://shared/utils/types.gd")

const BUS_MIX: StringName = "BackgroundMix"
const BUS_MUSIC: StringName = "Music"
const BUS_AMBIENCE: StringName = "Ambience"

const VOL_DEFAULT_PERCENT: float = 100.0

const PROP_VOL: = "volume_db"
const PROP_CUTOFF_HZ: = "cutoff_hz"

const FREQ_LOWER: = 20.0
const FREQ_UPPER: = 20000.0

const TWEEN_DURATION_FILTER: = 1.0
const TWEEN_DURATION_LAYER_FADE: = 1.0

const FX_LPFILTER_IDX: = 0
const FX_HPFILTER_IDX: = 1
const FX_GAIN_IDX: = 2

var _players: = {}
var _stopped_players: Array[PlayerArray]
var _played_oneshot_hashes: Array[int]
var last_pos_map: = {}
var _bus_fx_tweens: = {}


func _ready() -> void :
    _players = {
        PlayerGroup.MUSIC: PlayerArray.create(BUS_MUSIC, self), 
        PlayerGroup.AMBIENCE: PlayerArray.create(BUS_AMBIENCE, self), 
    }
    _bus_fx_tweens = {
        BUS_MUSIC: {
            EffectType.LOWPASS: null, 
            EffectType.HIGHPASS: null, 
            EffectType.GAIN: null, 
        }, 
        BUS_AMBIENCE: {
            EffectType.LOWPASS: null, 
            EffectType.HIGHPASS: null, 
            EffectType.GAIN: null, 
        }, 
        BUS_MIX: {
            EffectType.LOWPASS: null, 
            EffectType.HIGHPASS: null, 
            EffectType.GAIN: null, 
        }, 
    }

    SettingsManager.setting_changed.connect(_on_setting_changed)

    initialize()


func restore_defaults() -> void :
    SettingsManager.set_setting(
        SettingsManager.Keys.SECTION_AUDIO, 
        SettingsManager.Keys.SETTING_VOL_MUSIC, 
        VOL_DEFAULT_PERCENT
    )
    initialize()


func initialize() -> void :
    var initial_music_volume: Variant = SettingsManager.get_setting(
        SettingsManager.Keys.SECTION_AUDIO, 
        SettingsManager.Keys.SETTING_VOL_MUSIC, 
        VOL_DEFAULT_PERCENT, 
    )

    _set_music_volume_perc(
        clamp(initial_music_volume if TypeUtils.is_numeric(initial_music_volume) else VOL_DEFAULT_PERCENT, 0, 100)
    )


func play(layers: Array[LayerData], group: PlayerGroup = PlayerGroup.MUSIC, force_restart: bool = false) -> void :
    if not layers.size():
        return

    layers = remove_played_oneshots(layers)

    var paths_hash: = get_layer_paths_hash(layers)
    var existing_player: = _get_existing_player_array(paths_hash)
    var current: PlayerArray = _players[group]
    var target: PlayerArray = existing_player if existing_player else PlayerArray.create(current.bus, self)

    if paths_hash == current.layer_hash and not force_restart:

        return

    var default_pos: Array[float] = [0.0]
    var stream_pos: Array[float] = _get_stream_pos(layers) if not force_restart else default_pos

    if existing_player and not force_restart:
        target.play(stream_pos)
    else:
        target.play_layers(layers, stream_pos)

    _players[group] = target
    _set_played_oneshots(layers)


func play_stream(stream: AudioStream, group: PlayerGroup = PlayerGroup.MUSIC) -> void :
    play([LayerData.create(stream).set_active_on_start(true)], group)


func stop(group: PlayerGroup = PlayerGroup.MUSIC, fade_time: float = TWEEN_DURATION_LAYER_FADE, reset_positions: bool = false) -> void :
    var current: PlayerArray = _players[group]
    var bus: = BUS_MUSIC if group == PlayerGroup.MUSIC else BUS_AMBIENCE
    if reset_positions:
        _clear_current_player_streampos(group)
    else:
        _store_current_player_streampos(group)
    current.stop(fade_time)
    _players[group] = PlayerArray.create(bus, self)


func crossfade(layers: Array[LayerData], group: PlayerGroup = PlayerGroup.MUSIC, force_restart: bool = false) -> void :
    if not layers.size():
        return

    var paths_hash: = get_layer_paths_hash(layers)
    var current: PlayerArray = _players[group]

    if paths_hash == current.layer_hash and not force_restart:

        return

    current.stop()
    _store_current_player_streampos(group)
    play(layers, group, force_restart)


func set_player_active(is_active: bool, player_index: int, group: PlayerGroup = PlayerGroup.MUSIC) -> void :
    (_players[group] as PlayerArray).set_player_active(player_index, is_active)


func fade_player(fade_in: bool, player_index: int, group: PlayerGroup = PlayerGroup.MUSIC, clean_on_finished: bool = false, fade_time: float = TWEEN_DURATION_LAYER_FADE) -> void :
    (_players[group] as PlayerArray).fade_player(player_index, fade_in, clean_on_finished, fade_time)


func set_on_finished(on_finished: Callable, group: PlayerGroup = PlayerGroup.MUSIC) -> void :
    (_players[group] as PlayerArray).set_on_finished(on_finished)


func attenuate_mix(attenuated_vol_db: int = -10, attack_sec: float = 1.0) -> void :
    var bus: String = "BackgroundMix"
    var bus_idx: int = AudioServer.get_bus_index(BUS_MIX)
    var gain_insert: AudioEffectAmplify = AudioServer.get_bus_effect(
        bus_idx, 
        FX_GAIN_IDX, 
    )

    var cached_tween: Tween = _bus_fx_tweens[bus][EffectType.GAIN]

    if (cached_tween and cached_tween.is_running()):
        cached_tween.kill()

    var tween: = create_tween()
    tween.tween_property(gain_insert, PROP_VOL, attenuated_vol_db, attack_sec)
    _bus_fx_tweens[bus][EffectType.GAIN] = tween


func restore_mix(attack_sec: float = 1.0) -> void :
    var bus: String = "BackgroundMix"
    var bus_idx: int = AudioServer.get_bus_index(BUS_MIX)
    var gain_insert: AudioEffectAmplify = AudioServer.get_bus_effect(
        bus_idx, 
        FX_GAIN_IDX, 
    )

    var cached_tween: Tween = _bus_fx_tweens[bus][EffectType.GAIN]

    if (cached_tween and cached_tween.is_running()):
        cached_tween.kill()

    var tween: = create_tween()
    tween.tween_property(gain_insert, PROP_VOL, 0, attack_sec)
    _bus_fx_tweens[bus][EffectType.GAIN] = tween



func accent(group: PlayerGroup = PlayerGroup.MUSIC, reduction_db: int = -6, attack_sec: float = 1.0) -> void :
    for k: String in PlayerGroup:
        var player_group: PlayerGroup = PlayerGroup[k]
        var target_db: int = 0 if group == player_group else reduction_db
        var current: PlayerArray = _players[player_group]
        var bus: String = current.bus
        var bus_idx: int = AudioServer.get_bus_index(current.bus)
        var gain_insert: AudioEffectAmplify = AudioServer.get_bus_effect(
            bus_idx, 
            FX_GAIN_IDX, 
        )
        var cached_tween: Tween = _bus_fx_tweens[bus][EffectType.GAIN]

        if (cached_tween and cached_tween.is_running()):
            cached_tween.kill()

        var tween: = create_tween()
        tween.tween_property(gain_insert, PROP_VOL, target_db, attack_sec)
        _bus_fx_tweens[bus][EffectType.GAIN] = tween



func restore_gain(attack_sec: float = 1.0) -> void :
    for k: String in PlayerGroup:
        var player_group: PlayerGroup = PlayerGroup[k]
        var bus: String = BUS_MUSIC if player_group == PlayerGroup.MUSIC else BUS_AMBIENCE
        var current: PlayerArray = _players[player_group]
        var bus_idx: int = AudioServer.get_bus_index(current.bus)
        var gain_insert: AudioEffectAmplify = AudioServer.get_bus_effect(
            bus_idx, 
            FX_GAIN_IDX, 
        )

        if gain_insert.volume_db != 0.0:
            var cached_tween: Tween = _bus_fx_tweens[bus][EffectType.GAIN]

            if (cached_tween and cached_tween.is_running()):
                cached_tween.kill()

            var tween: = create_tween()
            tween.tween_property(gain_insert, PROP_VOL, 0.0, attack_sec)
            _bus_fx_tweens[bus][EffectType.GAIN] = tween


func queue(stream: AudioStream, group: PlayerGroup = PlayerGroup.MUSIC) -> void :
    var current: PlayerArray = _players[group]

    if not current.playing or not current.get_stream().bpm:
        play_stream(stream)
        return

    var current_stream: = current.get_stream(0)
    var target: = PlayerArray.create(current.bus, self)
    target.set_stream(stream)
    target.seek(0)
    target.volume_db = 0

    var beat_len_sec: float = 60.0 / current_stream.bpm
    var queue_tween: = create_tween()
    var bar_len_sec: float = beat_len_sec * current_stream.bar_beats
    var beat: = fmod(current.get_playback_position() / beat_len_sec, current_stream.bar_beats as float)

    queue_tween.tween_callback(
        func() -> void :
            target.play()
            current.stop()
            _players[group] = target
    ).set_delay(bar_len_sec - beat * beat_len_sec)

    queue_tween.play()


func enable_filter(type: FilterType, bus: StringName = BUS_MUSIC, cutoff: float = 2000.0, duration_sec: = TWEEN_DURATION_FILTER) -> void :
    var bus_idx: int = AudioServer.get_bus_index(bus)
    var filter_idx: = FX_LPFILTER_IDX if type == FilterType.LOWPASS else FX_HPFILTER_IDX
    var filter: AudioEffect = AudioServer.get_bus_effect(bus_idx, filter_idx)
    var cached_tween: Tween = _bus_fx_tweens[bus][type]

    if (cached_tween and cached_tween.is_running()):
        cached_tween.kill()

    var tween: = create_tween()
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_QUAD)
    tween.tween_property(filter, PROP_CUTOFF_HZ, cutoff, duration_sec)
    _bus_fx_tweens[bus][type] = tween


func disable_filter(type: FilterType, bus: StringName = BUS_MUSIC, duration_sec: = TWEEN_DURATION_FILTER) -> void :
    var bus_idx: int = AudioServer.get_bus_index(bus)
    var filter_idx: = FX_LPFILTER_IDX if type == FilterType.LOWPASS else FX_HPFILTER_IDX
    var filter: AudioEffect = AudioServer.get_bus_effect(bus_idx, filter_idx)
    var end_freq: = FREQ_UPPER if type == FilterType.LOWPASS else FREQ_LOWER
    var cached_tween: Tween = _bus_fx_tweens[bus][type]

    if (cached_tween and cached_tween.is_running()):
        cached_tween.kill()

    var tween: = create_tween()
    tween.set_ease(Tween.EASE_IN)
    tween.set_trans(Tween.TRANS_QUAD)
    tween.tween_property(filter, PROP_CUTOFF_HZ, end_freq, duration_sec)
    _bus_fx_tweens[bus][type] = tween


func get_music_vol_as_perc() -> float:
    return Utils.convert_db_to_perc(AudioServer.get_bus_volume_db(
        AudioServer.get_bus_index(BUS_MUSIC)
    ))


func play_bg_audio(music_layers: Array[AudioStream] = [], ambience_layers: Array[AudioStream] = [], force_restart: bool = false) -> void :
    var layer_data_music: Array[LayerData] = []
    var layer_data_ambience: Array[LayerData] = []

    for i in music_layers.size():
        var stream: AudioStream = music_layers[i]
        layer_data_music.append(LayerData.create(stream).set_active_on_start(i == 0))

    for i in ambience_layers.size():
        var stream: AudioStream = ambience_layers[i]
        layer_data_ambience.append(LayerData.create(stream).set_active_on_start(true))

    if layer_data_music.size():
        crossfade(layer_data_music, PlayerGroup.MUSIC, force_restart)
    else:
        stop()

    var group_amb: = PlayerGroup.AMBIENCE
    if layer_data_ambience.size():
        crossfade(layer_data_ambience, group_amb, force_restart)
    else:
        stop(group_amb)


func _clear_current_player_streampos(group: PlayerGroup) -> void :
    var player_array: PlayerArray = _players[group] as PlayerArray
    for player_index in player_array.players.size():
        last_pos_map[player_array.get_resource_path(player_index)] = 0


func _store_current_player_streampos(group: PlayerGroup) -> void :
    _store_streampos(_players[group] as PlayerArray)


func _store_streampos(player_array: PlayerArray) -> void :
    for player_index in player_array.players.size():
        var pos: = player_array.get_playback_position(player_index)
        if pos > 0:
            last_pos_map[player_array.get_resource_path(player_index)] = pos


func _get_stream_pos(layers: Array[LayerData]) -> Array[float]:
    var positions: Array[float] = []
    var first_layer_pos: float = last_pos_map.get(layers[0].stream.resource_path, 0.0)

    for layer in layers:
        positions.append(last_pos_map.get(layer.stream.resource_path, first_layer_pos))

    return positions


func _get_existing_player_array(layer_hash: int) -> PlayerArray:
    var matching_players: Array[PlayerArray] = _stopped_players.filter(
        func(p: PlayerArray) -> bool:
            return p.layer_hash == layer_hash
    )

    if matching_players.size():
        var player: = matching_players[0]

        if not player.is_safe_to_destroy():
            return player

    return null


func _set_music_volume_perc(value: Variant) -> void :
    @warning_ignore("unsafe_call_argument")
    AudioServer.set_bus_volume_db(
        AudioServer.get_bus_index(BUS_MUSIC), 
        Utils.convert_perc_to_db(value), 
    )


func _on_setting_changed(section: String, key: String, value: Variant) -> void :
    if section != SettingsManager.Keys.SECTION_AUDIO:
        return

    if key == SettingsManager.Keys.SETTING_VOL_MUSIC and TypeUtils.is_numeric(value):
        _set_music_volume_perc(value)
        return


func get_layer_paths_hash(layers: Array[LayerData]) -> int:
    var paths: Array[String] = []
    for layer in layers:
        paths.append(layer.stream.resource_path)
    return paths.hash()


func remove_played_oneshots(layers: Array[LayerData]) -> Array[LayerData]:
    return layers.filter(
        func(layer: LayerData) -> bool:
            return not is_oneshot_played(layer.stream.resource_path)
    )


func is_oneshot_played(path: String) -> bool:
    return _played_oneshot_hashes.has(path.hash())


func _set_played_oneshots(layers: Array[LayerData]) -> void :
    for layer in layers:
        if not layer.is_oneshot:
            continue

        var layer_hash: = layer.stream.resource_path.hash()
        if not _played_oneshot_hashes.has(layer_hash):
            _played_oneshot_hashes.append(layer_hash)


func store_stopped_player(player_array: PlayerArray) -> void :
    _stopped_players.append(player_array)


func remove_stopped_player(player_array: PlayerArray) -> void :
    _stopped_players = _stopped_players.filter(func(p: PlayerArray) -> bool: return p != player_array)


class PlayerArray:
    const VOL_DEACTIVATED: = linear_to_db(0)
    const VOL_ACTIVATED: = linear_to_db(1)

    var players: Array[AudioStreamPlayer] = []
    var player_state: Array[bool] = []
    var bus: StringName
    var owner: Node
    var layer_hash: int
    var volume_db: float:
        set = set_volume_db
    var playing: bool = false
    var _fade_tweens: = {}


    func add_player() -> void :
        var player: = AudioStreamPlayer.new()
        player.bus = bus
        owner.add_child(player)
        players.append(player)
        player_state.append(true)


    func clean_if_possible() -> void :
        if is_safe_to_destroy():
            for player in players:
                player.queue_free()
            MusicPlayer.remove_stopped_player(self)


    func is_safe_to_destroy() -> bool:
        var all_players_inactive: = player_state.all(
            func(state: bool) -> bool:
                return state == false
        )

        return !playing and all_players_inactive


    func set_player_active(player_index: int, is_player_active: bool) -> void :
        if players.size() <= player_index:
            return
        players[player_index].volume_db = volume_db if is_player_active else VOL_DEACTIVATED
        player_state[player_index] = is_player_active


    func fade_player(player_index: int, fade_in: bool, clean_on_finished: bool = false, fade_time: float = TWEEN_DURATION_LAYER_FADE) -> void :
        if players.size() <= player_index:
            return
        if _fade_tweens.keys().has(player_index) and _fade_tweens[player_index].is_running():
            _fade_tweens[player_index].kill()

        var player: AudioStreamPlayer = players[player_index]
        if fade_in:
            player_state[player_index] = true

            if player.volume_db == VOL_ACTIVATED:
                return

            var tween: = owner.create_tween()
            tween.tween_method(
                Utils.linear_vol_setter(player), 
                db_to_linear(player.volume_db), 
                db_to_linear(0), 
                fade_time, 
            )

            _fade_tweens[player_index] = tween
        else:
            if player.volume_db == VOL_DEACTIVATED:
                player_state[player_index] = false
                if clean_on_finished:
                    clean_if_possible()
                return

            var tween: = owner.create_tween()
            tween.tween_method(
                Utils.linear_vol_setter(player), 
                db_to_linear(player.volume_db), 
                db_to_linear(-80), 
                fade_time, 
            )

            tween.finished.connect(
                func() -> void :
                    player_state[player_index] = false
                    if clean_on_finished:
                        clean_if_possible(), 
                CONNECT_ONE_SHOT, 
            )
            _fade_tweens[player_index] = tween


    func get_playback_position(player_index: int = 0) -> float:
        return players[player_index].get_playback_position() if players.size() else 0.0


    func get_resource_path(player_index: int = 0) -> String:
        return (players[player_index] as AudioStreamPlayer).stream.resource_path


    func get_stream(player_index: int = 0) -> AudioStream:
        if players.size() <= player_index:
            return null
        return players[player_index].stream


    func set_stream(stream: AudioStream, player_index: int = 0) -> void :
        if players.size() <= player_index:
            return
        players[player_index].stream = stream


    func set_volume_db(v: float) -> void :
        volume_db = v
        for i in players.size():
            var player: AudioStreamPlayer = players[i]
            if playing and not player_state[i]:

                continue


            player.volume_db = v


    func seek(pos: float) -> void :
        for player in players:
            player.seek(pos)


    func play(pos: Array[float] = [0.0]) -> void :
        MusicPlayer.remove_stopped_player(self)
        playing = true

        for i in players.size():
            var player: AudioStreamPlayer = players[i]
            if player.stream is AudioStream:
                if pos[i] > player.stream.get_length():
                    continue

                if not player.playing:
                    player.volume_db = VOL_DEACTIVATED
                    player.play(pos[i])

                player_state[i] = true
                fade_player(i, true)


    func play_layers(layers: Array[LayerData], pos: Array[float] = [0.0]) -> void :
        var layer_count: int = layers.size()
        ensure_count(layer_count)

        for i in players.size():
            set_player_active(i, false)

        for i in layer_count:
            var layer_data: LayerData = layers[i]
            set_stream(layer_data.stream, i)
            set_player_active(i, layer_data.start_active)

        layer_hash = MusicPlayer.get_layer_paths_hash(layers)
        play(pos)


    func stop(fade_time: float = TWEEN_DURATION_LAYER_FADE) -> void :
        if not playing:
            return

        playing = false
        for i in players.size():
            fade_player(i, false, true, fade_time)

        MusicPlayer.store_stopped_player(self)


    func ensure_count(count: int) -> void :
        var diff: int = count - players.size()
        if diff > 0:
            for i in diff:
                add_player()


    func set_on_finished(on_finished: Callable) -> void :
        if players.size():
            players[0].finished.connect(on_finished)


    static func create(target_bus: StringName, target_owner: Node) -> PlayerArray:
        var array: PlayerArray = PlayerArray.new()
        array.bus = target_bus
        array.owner = target_owner
        return array


class LayerData:
    extends Resource

    var stream: AudioStream
    var start_active: bool
    var is_oneshot: bool


    static func create(audio_stream: AudioStream) -> LayerData:
        var data: LayerData = LayerData.new()
        data.start_active = false
        data.stream = audio_stream
        return data


    func set_active_on_start(active: bool) -> LayerData:
        self.start_active = active
        return self


    func set_is_oneshot(state: bool) -> LayerData:
        self.is_oneshot = state
        return self
