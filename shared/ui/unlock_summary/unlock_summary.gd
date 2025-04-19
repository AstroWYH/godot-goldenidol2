extends Control

const MARGIN: Vector2 = Vector2(32.0, 32.0)
const PADDING: = 50.0
const DELAY_GAP: float = 0.07

const ANIM_DURATION: float = 0.1
const ANIM_DURATION_HIDE: float = 0.5

const PROP_GPOS: = "global_position"
const PROP_MODULATE: = "modulate"
const PROP_SELF_MODULATE: = "self_modulate"
const PROP_SCALE: = "scale"

const DIVIDER_NAME: = "div"

const COLOR_GHOST: = Color8(255, 255, 255, 125)

const PhraseScene: = preload("res://shared/ui/phrase_decorative/phrase_decorative.tscn")
const CharacterScene: = preload("res://shared/ui/unlock_summary_character/unlock_summary_character.tscn")
const PuzzleScene: = preload("res://shared/ui/unlock_summary_puzzle/unlock_summary_puzzle.tscn")

@export var character_id: int
@export var item_ids: Array[int] = []
@export var hypthetical_item_ids: Array[int] = []
@export var puzzles: Array[PuzzleMeta]
@export var inventory_gpos: Vector2
@export var ghost_mode: bool = true:
    set = set_ghost_mode

var _animating: bool = true

@onready var panel: Panel = $Panel
@onready var container: CenterContainer = $Panel / Container
@onready var vbox_container: VBoxContainer = $Panel / Container / VBoxContainer
@onready var language: String = TranslationServer.get_locale()


func _ready() -> void :
    var delay: = 0.0
    if not ghost_mode:
        panel.self_modulate = Color.TRANSPARENT
        create_tween().tween_callback(func() -> void : _animating = false).set_delay(delay)
    else:
        modulate = COLOR_GHOST

    if character_id:
        var character_container: = CharacterScene.instantiate()
        character_container.character_id = character_id
        vbox_container.add_child(character_container)

        if not ghost_mode:
            character_container.modulate = Color.TRANSPARENT
            create_tween().tween_property(character_container, PROP_MODULATE, Color.WHITE, ANIM_DURATION).set_delay(delay)
        if len(item_ids) or len(puzzles):
            _add_divider()
        delay += DELAY_GAP

    for puzzle_meta in puzzles:
        var puzzle_container: = PuzzleScene.instantiate()
        puzzle_container.puzzle_meta = puzzle_meta
        vbox_container.add_child(puzzle_container)
        delay += DELAY_GAP

    if len(item_ids) and len(puzzles):
        _add_divider()

    for item_id in item_ids:
        var item: GIItem = Database.get_item_by_id(item_id)
        var phrase: DecorativePhrase = PhraseScene.instantiate()
        phrase.set_data_from_item(item)


        if item_id in hypthetical_item_ids:
            if language == "es" or language == "es_MX":
                phrase.text = "¿" + phrase.text + "?"
            else:
                phrase.text += tr("TRAILING_QUESTION_MARK")


        vbox_container.add_child(phrase)
        if not ghost_mode:
            phrase.modulate = Color.TRANSPARENT
            create_tween().tween_property(phrase, PROP_MODULATE, Color.WHITE, ANIM_DURATION).set_delay(delay)
        delay += DELAY_GAP

    if not ghost_mode:
        create_tween().tween_property(panel, PROP_SELF_MODULATE, Color.WHITE, ANIM_DURATION)
        create_tween().tween_callback(func() -> void : move_to_front()).set_delay(ANIM_DURATION)


func set_ghost_mode(v: bool) -> void :
    ghost_mode = v


func _is_valid_mouse_input(event: InputEvent) -> bool:
    if not event is InputEventMouseButton:
        return false

    if not event.is_pressed():
        return false

    if (event as InputEventMouseButton).button_index != MOUSE_BUTTON_LEFT:
        return false

    return true


func _is_valid_gamepad_input() -> bool:
    return GamepadUtils.accept_pressed() or GamepadUtils.back_pressed()


func _input(event: InputEvent) -> void :
    if ghost_mode:
        return

    if _animating:
        return

    if not _is_valid_mouse_input(event) and not _is_valid_gamepad_input():
        return

    var delay: = 0.0
    var child_size: = vbox_container.get_child_count()
    var children: = vbox_container.get_children()

    for i in child_size:
        var child: = children[child_size - 1 - i]

        if DIVIDER_NAME in child.name:
            continue

        var tween: = create_tween()
        tween.set_ease(Tween.EASE_IN)
        tween.set_trans(Tween.TRANS_CUBIC)

        if child is DecorativePhrase:
            tween.tween_property(
                child, 
                PROP_GPOS, 
                inventory_gpos, 
                ANIM_DURATION_HIDE, 
            ).set_delay(delay)

            if i == 0:
                AudioManager.play(AudioManager.Sound.PHRASE_COLLECT_START, SoundParams.new().with_delay(delay).with_pitch_range(Vector2(-0.01, 0.01)))
                tween.tween_callback(func() -> void : AudioManager.play(AudioManager.Sound.PHRASE_COLLECT_END))
            else:
                tween.tween_callback(func() -> void : AudioManager.play(AudioManager.Sound.PHRASE_COLLECT_END_MORE))

        tween.tween_property(
            child, 
            PROP_MODULATE, 
            Color.TRANSPARENT, 
            ANIM_DURATION_HIDE, 
        ).set_delay(delay)

        delay += DELAY_GAP

    create_tween().tween_property(panel, PROP_SELF_MODULATE, Color.TRANSPARENT, ANIM_DURATION_HIDE)
    create_tween().tween_callback(queue_free).set_delay(ANIM_DURATION_HIDE + delay - DELAY_GAP)
    get_viewport().set_input_as_handled()
    _animating = true


func show_summary() -> void :
    show()
    container.reset_size()
    var top: = DialogManager.get_top()

    if not top:
        var target_pos: Vector2 = get_global_mouse_position()
        var screen_size: Vector2 = get_viewport().get_visible_rect().size
        if target_pos.y >= screen_size.y - 135 or GamepadUtils.accept_pressed():


            global_position = screen_size / 2 - vbox_container.size
            return

        global_position = Vector2(
            target_pos.x - vbox_container.size.x / 2, 
            target_pos.y - vbox_container.size.y - PADDING, 
        )
        return

    var container_size: = vbox_container.size
    var dialog_rect: = top.content_rect

    var dialog_end_x: = dialog_rect.end.x
    var gpos_y: float = dialog_rect.position.y + ((dialog_rect.size.y - container_size.y) / 2)

    if get_viewport_rect().size.x - dialog_end_x > container_size.x + PADDING * 2:

        global_position = Vector2(
            dialog_end_x + PADDING, 
            gpos_y, 
        )
    else:
        global_position = Vector2(
            dialog_rect.position.x - PADDING - container_size.x, 
            gpos_y, 
        )


func _on_container_resized() -> void :
    if not panel or not container:
        return
    panel.size = container.size + MARGIN
    container.position.x = MARGIN.x / 2
    container.position.y = MARGIN.y / 2


func _add_divider() -> void :
    var divider: = Control.new()
    divider.custom_minimum_size = MARGIN / 2
    divider.name = DIVIDER_NAME + str(divider.get_instance_id())
    vbox_container.add_child(divider)
