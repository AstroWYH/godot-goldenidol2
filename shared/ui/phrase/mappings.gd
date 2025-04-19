@tool
class_name Mappings
extends RefCounted


static  var tag_map: = {
    GIItem.PhraseType.NAME: "name", 
    GIItem.PhraseType.OBJECT: "object", 
    GIItem.PhraseType.ACTION: "action", 
    GIItem.PhraseType.SPECIAL: "special", 
    GIItem.PhraseType.NUMERAL: "numeral", 
    GIItem.PhraseType.LOCAL: "local", 

    GIItem.PhraseType.C_NAME: "c_name", 
    GIItem.PhraseType.C_OBJECT: "c_object", 
    GIItem.PhraseType.C_ACTION: "c_action", 
    GIItem.PhraseType.C_SPECIAL: "c_special", 
    GIItem.PhraseType.C_NUMERAL: "c_numeral", 
}

static  var color_map: = {

    GIItem.PhraseType.NAME: Color8(153, 153, 153), 
    GIItem.PhraseType.OBJECT: Color8(204, 65, 37), 

}
