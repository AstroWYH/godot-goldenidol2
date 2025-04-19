extends GdUnitTestSuite

const __source = "res://shared/utils/types.gd"
const TypeUtils = preload(__source)

var type_utils: TypeUtils


func before() -> void :
    type_utils = auto_free(TypeUtils.new())


func test_string() -> void :
    assert_bool(TypeUtils.is_numeric("foo")).is_false()


func test_bool() -> void :
    assert_bool(TypeUtils.is_numeric(true)).is_false()


func test_dictionary() -> void :
    assert_bool(TypeUtils.is_numeric({})).is_false()


func test_obj() -> void :
    var obj: = Object.new()
    assert_bool(TypeUtils.is_numeric(obj)).is_false()
    obj.free()


func test_int() -> void :
    assert_bool(TypeUtils.is_numeric(3)).is_true()


func test_float() -> void :
    assert_bool(TypeUtils.is_numeric(123.123)).is_true()
