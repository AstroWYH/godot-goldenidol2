extends PuzzleComponent

@export_flags(
    "Name:1", 
    "Object:2", 
    "Action:4", 
    "Special:8", 
    "Numeral:16", 
    "Local:32", 
    "ChapterName:64", 
    "ChapterObject:128", 
    "ChapterAction:256", 
    "ChapterSpecial:512", 
    "ChapterNumeral:1024", 
) var accepted_types: int = 0:
    set = set_accepted_types
var _parsed_accepted_types: Array[GIItem.PhraseType]


func integrate() -> void :
    var phrase_slot: Node = get_parent().get_phrase_slot(id)
    if not phrase_slot:
        push_warning("No Phrase slot for puzzle component %d" % id)
        return
    connect_drop_receiver(phrase_slot.drop_receiver as DropReceiver)
    phrase_slot.accepted_types = _parsed_accepted_types


func set_accepted_types(flags: int) -> void :
    accepted_types = flags
    var parsed_types: Array[GIItem.PhraseType] = []
    for key: int in GIItem.PHRASE_TYPE_FLAG_MAP:
        if FlagsUtils.flag_state(flags, key):
            parsed_types.append(GIItem.PHRASE_TYPE_FLAG_MAP[key])
    _parsed_accepted_types = parsed_types
