extends Node

enum Expansions{
    ROY = 1, 
    LEGACY = 2, 
    SENATE = 4, 
    EXPEDITION = 8, 
}

const FILE_NAMES: Dictionary = {
    Expansions.ROY: "roy", 
    Expansions.LEGACY: "legacy", 
    Expansions.SENATE: "senate", 
    Expansions.EXPEDITION: "expedition", 
}

var _enabled_expansions: int = 0


func _enter_tree() -> void :
    _enable_expansions()


func is_expansion_enabled(expansion: int) -> bool:
    return FlagsUtils.flag_state(_enabled_expansions, expansion)


func _enable_expansions() -> void :
    var sep: String = "/"
    var install_dir: String = sep.join(OS.get_executable_path().split(sep).slice(0, -1)) + sep

    for v: int in Expansions.values():
        var path: String = install_dir + FILE_NAMES[v] as String + ".pck"
        if not FileAccess.file_exists(path):
            continue
        ProjectSettings.load_resource_pack(path)
        _enabled_expansions = FlagsUtils.flag_on(_enabled_expansions, v)
