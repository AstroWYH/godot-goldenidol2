@tool
class_name PhraseSlot
extends HBoxContainer



const PuzzleComponentScene = preload("res://shared/puzzle/puzzle_component/puzzle_component.tscn")
const PuzzleAnswerItemScene = preload("res://shared/puzzle/puzzle_answer_item/puzzle_answer_item.tscn")
const PhraseScene = preload("res://shared/ui/phrase/phrase.tscn")

@export var id: int:
    set = set_id
@export var initial_width: float = 64.0
@export var accepted_types: Array[GIItem.PhraseType] = []:
    set = set_accepted_types

@export var button_focus_neighbor_top: NodePath:
    set(p): call_deferred("_set_button_focus_neighbor_top", p)

@export var button_focus_neighbor_bottom: NodePath:
    set(p): call_deferred("_set_button_focus_neighbor_bottom", p)

@export var button_focus_neighbor_right: NodePath:
    set(p): call_deferred("_set_button_focus_neighbor_right", p)

@export var button_focus_neighbor_left: NodePath:
    set(p): call_deferred("_set_button_focus_neighbor_left", p)


@export var debug_hint: String = "":
    set = set_debug_hint

var slotted_id: int:
    get: return 0 if not drop_receiver else drop_receiver.slotted_id

var puzzle_component: PuzzleComponent
var global_transform_changed: Signal:
    get: return button.global_transform_changed if not Engine.is_editor_hint() else Signal()
var obscured: bool:
    set = set_obscured
var _article_scene: Node
var _mouse_on: bool = false

@onready var button: Button = $Button
@onready var drop_receiver: DropReceiver = $Button / DropReceiver


func _ready() -> void :
    set_id(id)
    set_accepted_types(accepted_types)
    set_debug_hint(debug_hint)
    set_obscured(obscured)
    _reset_button_width()
    pivot_offset = size / 2

    if not Engine.is_editor_hint():
        drop_receiver.draggable_claimed.connect(_on_draggable_claimed)
        button.focus_mode_requested.connect(on_button_focus_mode_requested)
        button.mouse_entered.connect(_on_button_mouse_entered)
        button.mouse_exited.connect(_on_button_mouse_exited)
        button.focus_exited.connect(_on_button_focus_exited)


func _notification(what: int) -> void :
    if what != NOTIFICATION_TRANSFORM_CHANGED:
        return
    global_transform_changed.emit()


func add_obscurer(obscurer: NinePatchRect) -> void :
    button.add_child(obscurer)


func set_obscured(is_obscured: bool) -> void :
    obscured = is_obscured

    var target_focus_mode: FocusMode = FOCUS_NONE if obscured else FOCUS_ALL
    set_button_focus_mode(target_focus_mode)

    if not Engine.is_editor_hint():
        drop_receiver.set_slotted_node_focus_mode(target_focus_mode)


func get_button_focus_mode() -> Control.FocusMode:
    return button.focus_mode


func set_button_focus_mode(new_focus_mode: Control.FocusMode) -> void :
    button.focus_mode = new_focus_mode


func on_button_focus_mode_requested(new_focus_mode: Control.FocusMode) -> void :
    if new_focus_mode == Control.FOCUS_ALL and obscured == true:

        return
    set_button_focus_mode(new_focus_mode)


func request_focus() -> Variant:
    return button


func grab_button_focus() -> void :
    button.grab_focus()


func get_button_path() -> NodePath:
    return button.get_path()


func _set_button_focus_neighbor_top(path: NodePath) -> void :
    button.focus_neighbor_top = path


func _set_button_focus_neighbor_bottom(path: NodePath) -> void :
    button.focus_neighbor_bottom = path


func _set_button_focus_neighbor_left(path: NodePath) -> void :
    button.focus_neighbor_left = path


func _set_button_focus_neighbor_right(path: NodePath) -> void :
    button.focus_neighbor_right = path


func _on_unslotted() -> void :
    if Engine.is_editor_hint():
        button.text = debug_hint
    else:
        button.text = ""




    set_slot_theme(true)
    _reset_button_width()


func _on_draggable_dropped(drag_node: CanvasItem, _draggable: Draggable, action: DragAndDropManager.DropAction) -> void :
    if action == DragAndDropManager.DropAction.NONE:
        return

    elif action == DragAndDropManager.DropAction.GAINED_DRAGGABLE:
        var phrase: Phrase = drag_node as Phrase
        use_phrase(phrase)


func _on_draggable_claimed(host: CanvasItem, _draggable: Draggable) -> void :
    use_phrase(host as Phrase)


func _set_article(v: String) -> void :
    if not v is String:
        return

    if not _article_scene:
        add_child(_article_scene)
        move_child(_article_scene, 0)

    _article_scene.text = v


func _update_font_size() -> void :
    var locale: String = TranslationServer.get_locale()
    var lang: String = locale.substr(0, locale.find("_"))
    var char_count: int = len(tr(button.text))

    if lang in Constants.CJK_LANGS:

        if char_count >= 8:
            button.add_theme_font_size_override("font_size", 12)
        elif char_count >= 7:
            button.add_theme_font_size_override("font_size", 15)
        elif char_count >= 6:
            button.add_theme_font_size_override("font_size", 17)
        else:
            button.remove_theme_font_size_override("font_size")
        return

    if char_count >= 12 and char_count < 14:
        button.add_theme_font_size_override("font_size", 15)
    elif char_count == 14:
        button.add_theme_font_size_override("font_size", 14)
    elif char_count == 15:
        button.add_theme_font_size_override("font_size", 13)
    elif char_count >= 16 and char_count < 18:
        button.add_theme_font_size_override("font_size", 13)
    elif char_count >= 18:
        button.add_theme_font_size_override("font_size", 13)
    else:
        button.remove_theme_font_size_override("font_size")


func set_id(v: int) -> void :
    id = v

    if not drop_receiver:
        return

    drop_receiver.metadata = {"id": id}


func set_accepted_types(v: Array[GIItem.PhraseType]) -> void :
    accepted_types = v
    if drop_receiver:
        var tags: Array[String] = []

        for type in v:
            tags.append(Mappings.tag_map[type])

        drop_receiver.accept_tags = tags

    if button:
        set_slot_theme()


func get_slot_node() -> Button:
    return button


func set_slot_theme(force: bool = false) -> void :
    if not Engine.is_editor_hint() and not force and drop_receiver and drop_receiver.slotted_node is Phrase:

        return

    if len(accepted_types):
        var pt: = GIItem.PhraseType

        if pt.OBJECT in accepted_types and pt.NAME in accepted_types:
            button.theme_type_variation = Constants.VARIATION_SLOT_OBJECT_NAME
        elif pt.OBJECT in accepted_types and pt.SPECIAL in accepted_types:
            button.theme_type_variation = Constants.VARIATION_SLOT_OBJECT_SPECIAL
        elif pt.OBJECT in accepted_types and pt.ACTION in accepted_types:
            button.theme_type_variation = Constants.VARIATION_SLOT_OBJECT_ACTION


        elif pt.C_OBJECT in accepted_types and pt.C_NAME in accepted_types:
            button.theme_type_variation = Constants.VARIATION_SLOT_CHAPTER_OBJECT_NAME
        elif pt.C_OBJECT in accepted_types and pt.C_SPECIAL in accepted_types:
            button.theme_type_variation = Constants.VARIATION_SLOT_CHAPTER_OBJECT_SPECIAL
        elif pt.C_OBJECT in accepted_types and pt.C_ACTION in accepted_types:
            button.theme_type_variation = Constants.VARIATION_SLOT_CHAPTER_OBJECT_ACTION



        else:
            var first_type: = accepted_types[0]
            match first_type:
                pt.NAME:
                    button.theme_type_variation = Constants.VARIATION_SLOT_NAME
                pt.OBJECT:
                    button.theme_type_variation = Constants.VARIATION_SLOT_OBJECT
                pt.ACTION:
                    button.theme_type_variation = Constants.VARIATION_SLOT_ACTION
                pt.SPECIAL:
                    button.theme_type_variation = Constants.VARIATION_SLOT_SPECIAL
                pt.NUMERAL:
                    button.theme_type_variation = Constants.VARIATION_SLOT_NUMERAL
                pt.LOCAL:
                    button.theme_type_variation = Constants.VARIATION_SLOT_LOCAL
                pt.C_NAME:
                    button.theme_type_variation = Constants.VARIATION_SLOT_CHAPTER_NAME
                pt.C_OBJECT:
                    button.theme_type_variation = Constants.VARIATION_SLOT_CHAPTER_OBJECT
                pt.C_ACTION:
                    button.theme_type_variation = Constants.VARIATION_SLOT_CHAPTER_ACTION
                pt.C_SPECIAL:
                    button.theme_type_variation = Constants.VARIATION_SLOT_CHAPTER_SPECIAL
                pt.C_NUMERAL:
                    button.theme_type_variation = Constants.VARIATION_SLOT_CHAPTER_NUMERAL


func set_slot_theme_from_phrase(phrase: Phrase) -> void :
    var pt: = GIItem.PhraseType

    if pt.OBJECT in accepted_types and pt.NAME in accepted_types:
        button.theme_type_variation = Constants.VARIATION_PHRASE_OBJECT_NAME
    elif pt.OBJECT in accepted_types and pt.SPECIAL in accepted_types:
        button.theme_type_variation = Constants.VARIATION_PHRASE_OBJECT_SPECIAL
    elif pt.OBJECT in accepted_types and pt.ACTION in accepted_types:
        button.theme_type_variation = Constants.VARIATION_PHRASE_OBJECT_ACTION

    elif pt.C_OBJECT in accepted_types and pt.C_NAME in accepted_types:
        button.theme_type_variation = Constants.VARIATION_PHRASE_CHAPTER_OBJECT_NAME
    elif pt.C_OBJECT in accepted_types and pt.C_SPECIAL in accepted_types:
        button.theme_type_variation = Constants.VARIATION_PHRASE_CHAPTER_OBJECT_SPECIAL
    elif pt.C_OBJECT in accepted_types and pt.C_ACTION in accepted_types:
        button.theme_type_variation = Constants.VARIATION_PHRASE_CHAPTER_OBJECT_ACTION

    else:
        button.theme_type_variation = Phrase.get_theme_variation(phrase.type)


func set_debug_hint(v: String) -> void :
    debug_hint = v
    if Engine.is_editor_hint() and button:
        button.text = v


func use_phrase(phrase: Phrase) -> void :
    button.text = phrase.text
    set_slot_theme_from_phrase(phrase)
    _update_font_size()


func add_slotted_item(slotted_item_id: int) -> void :
    if slotted_item_id <= 0:
        return

    var phrase: Phrase = PhraseScene.instantiate()
    phrase.ready.connect(

        func() -> void : drop_receiver.claim_draggable(phrase.draggable), 
        CONNECT_ONE_SHOT, 
    )
    var item: GIItem = Database.get_item_by_id(slotted_item_id)
    phrase.set_data_from_item(item)
    button.add_child(phrase)


func set_button_focus_neighbor(side: Side, path: NodePath) -> void :
    button.set_focus_neighbor(side, path)


func into_puzzle_component(puzzle_component_id: int, answer_value: int, slotted_item_id: int, infinite: bool) -> void :
    puzzle_component = PuzzleComponentScene.instantiate()
    puzzle_component.id = puzzle_component_id

    var puzzle_answer_item: PuzzleAnswerItem = PuzzleAnswerItemScene.instantiate()
    puzzle_answer_item.answer_item_ref_id = answer_value

    puzzle_component.add_child(puzzle_answer_item)
    button.add_child(puzzle_component)

    set_dropreceiver_infinite(infinite)
    drop_receiver.keep_copy_on_drop = false
    drop_receiver.swap_on_valid_drop = true
    drop_receiver.duplicate_slotted_draggable_on_drag = false

    add_slotted_item(slotted_item_id)


func set_dropreceiver_infinite(infinite: bool) -> void :
    drop_receiver.set_infinite(infinite)


func free_draggable(emit_unslotted: bool = false, unset_read_only: bool = false) -> void :
    if not drop_receiver:
        return
    drop_receiver.free_draggable(emit_unslotted, unset_read_only)


func raise() -> void :
    button.raise()


func lower() -> void :
    button.lower()


func _reset_button_width() -> void :
    button.custom_minimum_size.x = initial_width


func _on_button_mouse_entered() -> void :
    if button.focus_mode != FOCUS_ALL:
        return

    _mouse_on = true
    button.call_deferred(&"grab_focus")
    raise()


func _on_button_mouse_exited() -> void :
    _mouse_on = false


func _on_button_focus_exited() -> void :
    if not _mouse_on:
        lower()
