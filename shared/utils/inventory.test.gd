extends GdUnitTestSuite

const __source = "res://shared/utils/inventory.gd"
const InventoryUtils = preload(__source)

var inv_utils: InventoryUtils


func before() -> void :
    inv_utils = auto_free(InventoryUtils.new())


func test_upper_bound() -> void :
    assert_int(InventoryUtils.get_upper_bound(0)).is_equal(0)
    assert_int(InventoryUtils.get_upper_bound(1)).is_equal(InventoryUtils.ROW_WIDTH)
    assert_int(InventoryUtils.get_upper_bound(5)).is_equal(5)
    assert_int(InventoryUtils.get_upper_bound(6)).is_equal(10)
    assert_int(InventoryUtils.get_upper_bound(11)).is_equal(15)
    assert_int(InventoryUtils.get_upper_bound(16)).is_equal(20)


func test_configure() -> void :
    var scen_meta: ScenarioMeta = ScenarioMeta.new()
    scen_meta.phrases_name = 3
    scen_meta.phrases_object = 5
    scen_meta.phrases_special = 12
    var inv: RefCounted = InventoryUtils.new()
    inv.configure(scen_meta)









    var range1: InventoryUtils.InventoryRangeDef = InventoryUtils.InventoryRangeDef.create(0, 4)
    var range2: InventoryUtils.InventoryRangeDef = InventoryUtils.InventoryRangeDef.create(10, 14)
    var range3: InventoryUtils.InventoryRangeDef = InventoryUtils.InventoryRangeDef.create(20, 34)
    var range_def: Dictionary = inv.range_def

    @warning_ignore("unsafe_call_argument")
    assert_object(range_def[GIItem.PhraseType.NAME]).is_equal(range1)
    @warning_ignore("unsafe_call_argument")
    assert_object(range_def[GIItem.PhraseType.OBJECT]).is_equal(range2)
    @warning_ignore("unsafe_call_argument")
    assert_object(range_def[GIItem.PhraseType.SPECIAL]).is_equal(range3)


func test_set_inventory_item_layout() -> void :
    var scen_meta: ScenarioMeta = ScenarioMeta.new()
    scen_meta.phrases_name = 3
    scen_meta.phrases_object = 4
    scen_meta.phrases_special = 6
    var inv: RefCounted = InventoryUtils.new()
    inv.configure(scen_meta)


    var inv_data: Array[int] = get_empty_inventory(30)

    var new_items: Array[int] = [
        42, 43, 44, 
        11, 12, 13, 14, 
        39, 40, 41, 62, 63, 64
    ]

    inv.set_inventory_item_layout(inv_data, new_items)

    assert_object(inv_data).is_equal([
        42, 43, 44, 0, 0, 
        0, 0, 0, 0, 0, 
        11, 12, 13, 14, 0, 
        0, 0, 0, 0, 0, 
        39, 41, 63, 0, 0, 
        40, 62, 64, 0, 0
    ])


func test_set_inventory_item_layout_occupied_tiles() -> void :
    var scen_meta: ScenarioMeta = ScenarioMeta.new()
    scen_meta.phrases_name = 3
    scen_meta.phrases_object = 5
    scen_meta.phrases_special = 6
    var inv: RefCounted = InventoryUtils.new()
    inv.configure(scen_meta)


    var inv_data: Array[int] = get_empty_inventory(30)



    inv_data[0] = 1
    inv_data[1] = 2
    inv_data[2] = 3
    inv_data[3] = 4
    inv_data[4] = 5

    var new_items: Array[int] = [
        42, 43, 44, 
        11, 12, 13, 14, 
        39, 40, 41, 62, 63, 64
    ]

    inv.set_inventory_item_layout(inv_data, new_items)


    assert_object(inv_data).is_equal([
        1, 2, 3, 4, 5, 
        42, 0, 0, 0, 0, 
        43, 11, 12, 13, 14, 
        44, 0, 0, 0, 0, 
        39, 41, 63, 0, 0, 
        40, 62, 64, 0, 0
    ])


func test_set_inventory_item_layout_bug() -> void :
    var scen_meta: ScenarioMeta = ScenarioMeta.new()
    scen_meta.phrases_name = 16
    scen_meta.phrases_object = 10
    var inv: RefCounted = InventoryUtils.new()
    inv.configure(scen_meta)


    @warning_ignore("static_called_on_instance")
    var inv_data: Array[int] = get_empty_inventory(40)

    var new_items: Array[int] = [
        42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 
        11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 
    ]

    inv.set_inventory_item_layout(inv_data, new_items)

    assert_object(inv_data).is_equal([
        42, 46, 50, 54, 0, 
        43, 47, 51, 55, 0, 
        44, 48, 52, 56, 0, 
        45, 49, 53, 57, 0, 

        0, 0, 0, 0, 0, 

        11, 13, 15, 17, 19, 
        12, 14, 16, 18, 20, 

        0, 0, 0, 0, 0, 
    ])


static func get_empty_inventory(inv_size: int = InventoryUtils.INVENTORY_CAPACITY) -> Array[int]:
    var inv: Array[int] = []
    for i in inv_size:
        inv.append(0)
    return inv



static func inv_printer(inventory: Array[int]) -> void :
    var tmp: Array = []
    for i in inventory.size():
        if i != 0 and i % InventoryUtils.ROW_WIDTH == 0:
            print(tmp)
            tmp = []
        var item: int = inventory[i]
        tmp.append(item)
    print(tmp)
