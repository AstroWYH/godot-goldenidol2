extends RefCounted

const PhraseType = GIItem.PhraseType
const ROW_WIDTH: int = 5
const INVENTORY_CAPACITY: int = 100


static  var _meta_field_to_type: Dictionary = {
    "phrases_name": PhraseType.NAME, 
    "phrases_object": PhraseType.OBJECT, 
    "phrases_action": PhraseType.ACTION, 
    "phrases_special": PhraseType.SPECIAL, 
    "phrases_numeral": PhraseType.NUMERAL, 
    "phrases_local": PhraseType.LOCAL, 
}


var range_def: Dictionary = {}


func configure(scenario_meta: ScenarioMeta) -> void :
    var last_max: int = 0
    for k: String in _meta_field_to_type.keys():
        var count_value: Variant = scenario_meta.get(k)
        var count: int = count_value if typeof(count_value) == TYPE_INT else 0
        if count == 0:
            continue

        @warning_ignore("static_called_on_instance")
        var upper: int = get_upper_bound(last_max + count) - 1

        range_def[_meta_field_to_type[k]] = InventoryRangeDef.create(
            last_max, 
            upper, 
        )


        last_max = upper + ROW_WIDTH + 1


func set_inventory_item_layout(scenario_inventory: Array[int], new_item_ids: Array[int]) -> void :


    for item_id in new_item_ids:
        var item: GIItem = Database.get_item_by_id(item_id)

        if not item:
            continue

        var absolute_max: int = INVENTORY_CAPACITY - 1
        var bound_min: int = 0
        var bound_max: int = absolute_max

        var bounds: InventoryRangeDef = range_def.get(item.meta.type)
        if bounds:
            bound_min = bounds.idx_min
            bound_max = min(bounds.idx_max, INVENTORY_CAPACITY - 1)

        @warning_ignore("static_called_on_instance")
        var height: int = get_height(bound_max - bound_min)
        var slotted: bool = _slot_item(scenario_inventory, item_id, bound_min, bound_max, height)

        if not slotted:


            _slot_item(
                scenario_inventory, 
                item_id, 
                0, 
                absolute_max, 
                int(INVENTORY_CAPACITY / float(ROW_WIDTH)), 
            )


func sort_inventory(inventory_ids: Array) -> Array[int]:
    var inventory_gitems: Array[GIItem] = []
    var inventory_types: Array[int] = []
    for i in range(inventory_ids.size()):
        var id: int = inventory_ids[i]
        if id == 0:
            inventory_gitems.append(null)
            inventory_types.append(-1)
        else:
            var item: GIItem = Database.get_item_by_id(id)

            inventory_gitems.append(item)
            inventory_types.append(item.meta.type)


    var sorted_gitems: Array = []


    for type in range(GIItem.PhraseType.size()):
        var type_array: Array[GIItem] = []
        for i in range(inventory_gitems.size()):
            if inventory_types[i] == -1:
                continue
            var item: = inventory_gitems[i]
            if inventory_types[i] == type:
                type_array.append(item)

        type_array.sort_custom(

            func(a: GIItem, b: GIItem) -> bool:
                var a_lower: String = get_phrase_translation(a).to_lower()
                var b_lower: String = get_phrase_translation(b).to_lower()


                return a_lower < b_lower
        )
        sorted_gitems.append_array(type_array)


    var scenario_inventory: Array[int] = []
    scenario_inventory.resize(INVENTORY_CAPACITY)
    scenario_inventory.fill(0)

    var sorted_ints: Array[int] = []
    sorted_ints.assign(sorted_gitems.map(
        func(item: GIItem) -> int: return item.id
    ))
    set_inventory_item_layout(scenario_inventory, sorted_ints)

    return scenario_inventory


func get_phrase_translation(phrase: GIItem) -> String:
    var scenario_id: Variant = ProgressManager.current_scenario_id
    var name_translation_id: String = Database.get_composite_translation_id(scenario_id as int, phrase)
    var name_translation: String = tr(name_translation_id)
    if name_translation_id == name_translation:
        return phrase.name
    else:
        return name_translation


func _slot_item(scenario_inventory: Array[int], item_id: int, bound_min: int, bound_max: int, height: int) -> bool:
    var slotted: bool = false
    for i in range(bound_min, bound_max + 1):
        var offset: int = i - bound_min
        var col: int = floor(offset / float(height))
        var idx: int = bound_min + col + ((offset % height) * ROW_WIDTH)

        var slot: int = scenario_inventory[idx]
        if slot == 0:
            scenario_inventory[idx] = item_id
            slotted = true
            break
    return slotted


static func get_height(count: int) -> int:
    return ceil(count / float(ROW_WIDTH))



static func get_upper_bound(count: int) -> int:
    return count if count % ROW_WIDTH == 0 else count + ROW_WIDTH - count % ROW_WIDTH


class InventoryRangeDef:
    var idx_min: int = 0
    var idx_max: int = 0

    static func create(rmin: int = 0, rmax: int = 0) -> InventoryRangeDef:
        var value: InventoryRangeDef = InventoryRangeDef.new()
        value.idx_min = rmin
        value.idx_max = rmax
        return value
