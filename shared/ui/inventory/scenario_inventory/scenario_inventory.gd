extends Control

@export var cells: int = 30
@export var columns: int = 1:
    set = set_columns

@onready var phrase_grid: ColorRect = get_child(0)


func _ready() -> void :
    _set_phrase_grid_items()
    set_columns(columns)
    phrase_grid.reordered.connect(_on_phrase_grid_reordered)
    phrase_grid.protect_slotted_draggable = false
    ProgressManager.items_unlocked.connect(_on_progressmanager_items_unlocked)
    ProgressManager.items_sorted.connect(_sort_phrase_grid_items)
    ProgressManager.scenario_reset.connect(_on_progressmanager_scenario_reset)


func set_columns(column_count: int) -> void :
    columns = column_count

    if phrase_grid:
        phrase_grid.columns = columns


func request_focus(side: Constants.FocusSide) -> void :
    if not phrase_grid:
        return

    var focus_target: Control = phrase_grid.request_focus(side)
    if focus_target is Control:
        focus_target.grab_focus()


func _on_phrase_grid_reordered(new_order: Array[int]) -> void :
    ProgressManager.set_current_scenario_inventory(new_order)


func _on_progressmanager_items_unlocked(_new_item_ids: Array[int]) -> void :
    _set_phrase_grid_items(false)


func _on_progressmanager_scenario_reset(_scenario_id: int) -> void :
    phrase_grid.extra_empty_cells = 0
    phrase_grid.set_phrases([] as Array[PhraseGridItem], true)


func _set_phrase_grid_items(reset: = false) -> void :
    var input: Array[PhraseGridItem] = []
    input.assign(ProgressManager.get_scenario_inventory().map(_to_phrase_grid_item))

    phrase_grid.extra_empty_cells = max(cells - input.size(), 0)
    phrase_grid.set_phrases(input, reset)


func _to_phrase_grid_item(id: int) -> PhraseGridItem:
    var phrase_item: = PhraseGridItem.new()
    phrase_item.linked_item_ref_id = id
    return phrase_item


func _sort_phrase_grid_items() -> void :
    _set_phrase_grid_items(true)
