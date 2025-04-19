@tool
class_name GIItem
extends Resource

enum Gender{
    MASC, 
    FEM, 
    NEUTER, 
    NONE, 
}



enum PhraseType{
    NAME = 0, 
    OBJECT = 1, 
    ACTION = 2, 
    SPECIAL = 3, 
    NUMERAL = 4, 
    LOCAL = 5, 
    C_NAME = 6, 
    C_OBJECT = 7, 
    C_ACTION = 8, 
    C_SPECIAL = 9, 
    C_NUMERAL = 10, 
}

const CHAPTER_TYPES: Array = [
    PhraseType.C_NAME, 
    PhraseType.C_OBJECT, 
    PhraseType.C_ACTION, 
    PhraseType.C_SPECIAL, 
    PhraseType.C_NUMERAL, 
]

enum GIItemType{
    PHRASE, 
}


const PHRASE_TYPE_FLAG_MAP: Dictionary = {
    1: PhraseType.NAME, 
    2: PhraseType.OBJECT, 
    4: PhraseType.ACTION, 
    8: PhraseType.SPECIAL, 
    16: PhraseType.NUMERAL, 
    32: PhraseType.LOCAL, 

    64: PhraseType.C_NAME, 
    128: PhraseType.C_OBJECT, 
    256: PhraseType.C_ACTION, 
    512: PhraseType.C_SPECIAL, 
    1024: PhraseType.C_NUMERAL, 

}

@export var id: int
@export var name: String
@export var type: GIItemType
@export var meta: Dictionary


func is_chapter_phrase() -> bool:
    return meta.type in CHAPTER_TYPES
