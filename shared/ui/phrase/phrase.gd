extends Button
class_name Phrase


const Gender = GIItem.Gender
const PhraseType = GIItem.PhraseType

const COLOR_UNUSED = Color.WHITE
const COLOR_USED = Color8(255, 215, 0, 255)
const COLOR_USED_SOLVED = Color8(143, 219, 143, 255)

static  var _gender_data_map: = {
    Gender.MASC: GenderPronounData.create("he", "him", "himself", "his", "his"), 
    Gender.FEM: GenderPronounData.create("she", "her", "herself", "her", "hers"), 
    Gender.NEUTER: GenderPronounData.create("it", "it", "itself", "its", "its"), 
}

@export var id: int:
    set = _set_id


@export var article: = "":
    set = _set_article

@export var gender: Gender = Gender.NONE:
    set = _set_gender

@export var type: PhraseType = PhraseType.NAME:
    set = _set_type

var _pronouns: GenderPronounData
var _mouse_on: bool = false

@onready var draggable: Draggable = $Draggable
@onready var puzzle_piece: = $PuzzlePiece


static func get_tr_key(item: GIItem, o: Object) -> String:
    var scenario_id: Variant = ProgressManager.current_scenario_id
    var name_translation_id: String = ""
    if item.is_chapter_phrase():
        var current_scenario_meta: ScenarioMeta = ProgressManager.current_scenario_meta
        var arc_id: int
        if current_scenario_meta is ScenarioMeta and current_scenario_meta.arc is ArcMeta:
            arc_id = current_scenario_meta.arc.id
        else:
            arc_id = ProgressManager.current_arc_id
        name_translation_id = Database.get_composite_arc_translation_id(arc_id, item)
    else:
        name_translation_id = Database.get_composite_translation_id(scenario_id as int, item)

    var name_translation: String = o.tr(name_translation_id)

    return name_translation if name_translation_id != name_translation else item.name


static func get_theme_variation(phrase_type: Phrase.PhraseType) -> StringName:
    match phrase_type:
        GIItem.PhraseType.NAME:
            return Constants.VARIATION_PHRASE_NAME

        GIItem.PhraseType.OBJECT:
            return Constants.VARIATION_PHRASE_OBJECT

        GIItem.PhraseType.ACTION:
            return Constants.VARIATION_PHRASE_ACTION

        GIItem.PhraseType.SPECIAL:
            return Constants.VARIATION_PHRASE_SPECIAL

        GIItem.PhraseType.NUMERAL:
            return Constants.VARIATION_PHRASE_NUMERAL

        GIItem.PhraseType.LOCAL:
            return Constants.VARIATION_PHRASE_LOCAL

        GIItem.PhraseType.C_NAME:
            return Constants.VARIATION_PHRASE_CHAPTER_NAME

        GIItem.PhraseType.C_OBJECT:
            return Constants.VARIATION_PHRASE_CHAPTER_OBJECT

        GIItem.PhraseType.C_ACTION:
            return Constants.VARIATION_PHRASE_CHAPTER_ACTION

        GIItem.PhraseType.C_SPECIAL:
            return Constants.VARIATION_PHRASE_CHAPTER_SPECIAL

        GIItem.PhraseType.C_NUMERAL:
            return Constants.VARIATION_PHRASE_CHAPTER_NUMERAL

    return Constants.VARIATION_PHRASE_NAME


func _ready() -> void :
    item_rect_changed.connect(_on_item_rect_changed)
    _set_gender(gender)
    _set_article(article)
    _set_id(id)
    _set_type(type)
    _update_font_size()
    mouse_entered.connect(_on_mouse_entered)
    mouse_exited.connect(_on_mouse_exited)
    focus_entered.connect(_on_focus_entered)
    focus_exited.connect(_on_focus_exited)


func set_data_from_item(item: GIItem) -> void :
    id = item.id
    article = item.meta.article
    gender = item.meta.gender
    type = item.meta.type
    text = get_tr_key(item, self)


func raise() -> void :
    z_index = 1 if ThinkingWindow.can_raise(self) else 0


func lower() -> void :
    z_index = 0


func set_usage() -> void :
    _set_usage_to(ProgressManager.get_item_usage(id))


func get_owning_drop_receiver() -> Variant:
    return draggable.owner_drop_receiver


func _set_usage_to(usage: ProgressManager.PuzzleItemUsage) -> void :
    match usage:
        ProgressManager.PuzzleItemUsage.UNUSED:
            add_theme_color_override("font_color", COLOR_UNUSED)
        ProgressManager.PuzzleItemUsage.IN_PUZZLE:
            add_theme_color_override("font_color", COLOR_USED)
        ProgressManager.PuzzleItemUsage.IN_SOLVED_PUZZLE:
            add_theme_color_override("font_color", COLOR_USED_SOLVED)


func _set_gender(g: GIItem.Gender) -> void :
    gender = g
    _pronouns = _gender_data_map.get(g)
    _update_draggable_meta()


func _set_id(new_id: int) -> void :
    id = new_id
    _update_draggable_meta()

    if not puzzle_piece:
        return

    puzzle_piece.id = id


func _set_article(new_article: String) -> void :
    article = new_article
    _update_draggable_meta()


func _set_type(v: PhraseType) -> void :
    type = v

    theme_type_variation = get_theme_variation(type)
    _update_draggable_meta()


    if draggable:
        draggable.tag = Mappings.tag_map[v]


func _update_draggable_meta() -> void :
    if not draggable:
        return

    var meta: Dictionary = draggable.metadata if draggable.metadata else {}
    meta.id = id
    meta.pronouns = _pronouns
    meta.type = type
    meta.article = article
    draggable.metadata = meta


func _on_dragged_node_set() -> void :
    _set_usage_to(ProgressManager.PuzzleItemUsage.UNUSED)


func _update_font_size() -> void :
    var locale: String = TranslationServer.get_locale()
    var lang: String = locale.substr(0, locale.find("_"))
    var char_count: int = len(tr(text))

    if lang in Constants.CJK_LANGS:

        if char_count >= 8:
            add_theme_font_size_override("font_size", 15)
        elif char_count >= 7:
            add_theme_font_size_override("font_size", 17)
        else:
            add_theme_font_size_override("font_size", 19)
        return





    if char_count >= 12 and char_count < 14:
        add_theme_font_size_override("font_size", 19)
    elif char_count >= 14 and char_count < 18:
        add_theme_font_size_override("font_size", 17)
    elif char_count >= 18:
        add_theme_font_size_override("font_size", 14)


func _on_mouse_entered() -> void :
    raise()
    _mouse_on = true
    if focus_mode != FOCUS_ALL:
        return
    grab_focus()


func _on_mouse_exited() -> void :
    _mouse_on = false
    if not has_focus():
        lower()


func _on_focus_entered() -> void :
    if _mouse_on:

        return
    raise()


func _on_focus_exited() -> void :
    if not _mouse_on:
        lower()


func _on_item_rect_changed() -> void :
    if not get_parent():
        return
    if not get_parent() is Control:
        return
    if size.x < get_parent().size.x:
        var new_size: Vector2 = Vector2(get_parent().size.x as float, size.y)
        set_deferred(&"size", new_size)
    _update_font_size()


class GenderPronounData:

    var personal_first_person: = ""


    var personal_third_person: String = ""


    var reflexive: String = ""


    var possessive: String = ""


    var independent_possessive: String = ""


    static func create(pfp: String, ptp: String, ref: String, poss: String, ind_poss: String) -> GenderPronounData:
        var new_instance: = GenderPronounData.new()
        new_instance.personal_first_person = pfp
        new_instance.personal_third_person = ptp
        new_instance.reflexive = ref
        new_instance.possessive = poss
        new_instance.independent_possessive = ind_poss
        return new_instance
