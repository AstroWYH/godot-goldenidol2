extends GdUnitTestSuite

const __source = "res://shared/utils/flags.gd"
const FlagsUtils = preload(__source)

var flags_utils: FlagsUtils


func before() -> void :
    flags_utils = auto_free(FlagsUtils.new())


func test_flag_on() -> void :
    assert_int(flags_utils.flag_on(0, 1)).is_equal(1)
    assert_int(flags_utils.flag_on(7, 3)).is_equal(7)
    assert_int(flags_utils.flag_on(7, 8)).is_equal(15)


func test_flag_off() -> void :
    assert_int(flags_utils.flag_off(0, 1)).is_equal(0)
    assert_int(flags_utils.flag_off(7, 3)).is_equal(4)
    assert_int(flags_utils.flag_off(7, 4)).is_equal(3)


func test_flag_state() -> void :
    assert_bool(flags_utils.flag_state(0, 1)).is_equal(false)
    assert_bool(flags_utils.flag_state(7, 3)).is_equal(true)
    assert_bool(flags_utils.flag_state(7, 4)).is_equal(true)
    assert_bool(flags_utils.flag_state(8, 2)).is_equal(false)


func test_flag_on_pos() -> void :
    assert_int(flags_utils.flag_on_pos(0, 0)).is_equal(1)
    assert_int(flags_utils.flag_on_pos(0, 2)).is_equal(4)
    assert_int(flags_utils.flag_on_pos(2, 0)).is_equal(3)
    assert_int(flags_utils.flag_on_pos(2, 1)).is_equal(2)
    assert_int(flags_utils.flag_on_pos(5, 1)).is_equal(7)


func test_flag_state_pos() -> void :
    assert_bool(flags_utils.flag_state_pos(8, 3)).is_equal(true)
    assert_bool(flags_utils.flag_state_pos(5, 1)).is_equal(false)
    assert_bool(flags_utils.flag_state_pos(7, 3)).is_equal(false)
