extends GdUnitTestSuite

const __source = "res://shared/utils/node.gd"
const NodeUtils = preload(__source)

var node_utils: NodeUtils


func before() -> void :
    node_utils = auto_free(NodeUtils.new())


func test_collect_nodes_by_substring() -> void :
    var target_name: = "Foo"
    var test_data: = Node.new()


    get_tree().get_root().add_child(test_data)

    var child1: = Node.new()
    child1.name = target_name

    var child2: = Node.new()
    child2.name = "Bar"

    var child3: = Node.new()
    child3.name = target_name + "-extrastuff"

    test_data.add_child(child1)
    test_data.add_child(child2)
    test_data.add_child(child3)

    var grand_child1: = Node.new()
    grand_child1.name = "Baz"
    child1.add_child(grand_child1)

    var grand_child2: = Node.new()
    grand_child2.name = target_name
    child2.add_child(grand_child2)

    var nodes: = node_utils.collect_nodes(
        test_data, 
        func(n: Node) -> bool: return n.name.contains(target_name), 
    )

    assert_array(nodes).has_size(3)
    assert_object(nodes[0]).is_equal(child1)
    assert_object(nodes[1]).is_equal(grand_child2)
    assert_object(nodes[2]).is_equal(child3)


func test_get_node_group() -> void :
    var target_group: = "abracadabra"
    var test_data: = Node.new()
    get_tree().get_root().add_child(test_data)

    var child1: = Node.new()
    test_data.add_child(child1)

    var child2: = Node.new()
    child2.add_to_group(target_group)
    test_data.add_child(child2)

    var child3: = Node.new()
    test_data.add_child(child3)

    var grand_child1: = Node.new()
    grand_child1.add_to_group(target_group)
    child2.add_child(grand_child1)

    var grand_child2: = Node.new()
    child2.add_child(grand_child2)

    var grand_grand_child1: = Node.new()
    grand_child2.add_to_group(target_group)
    grand_child2.add_child(grand_grand_child1)

    var nodes: = node_utils.get_node_group(test_data, target_group)

    assert_array(nodes).has_size(3)
    assert_object(nodes[0]).is_equal(child2)
    assert_object(nodes[1]).is_equal(grand_child1)
    assert_object(nodes[2]).is_equal(grand_grand_child1)


func test_is_more_top_left() -> void :
    var first: Control = Control.new()
    first.global_position = Vector2(0, 0)
    var second: Control = Control.new()
    second.global_position = Vector2(100, 100)

    assert_bool(node_utils.is_more_top_left(second, first)).is_equal(true)

    first.free()
    second.free()


func test_is_more_top_left_same_y() -> void :
    var first: Control = Control.new()
    first.global_position = Vector2(0, 0)
    var second: Control = Control.new()
    second.global_position = Vector2(100, 0)

    assert_bool(node_utils.is_more_top_left(second, first)).is_equal(true)

    first.free()
    second.free()


func test_is_more_top_right() -> void :
    var first: Control = Control.new()
    first.global_position = Vector2(100, 0)
    var second: Control = Control.new()
    second.global_position = Vector2(0, 100)

    assert_bool(node_utils.is_more_top_right(second, first)).is_equal(true)

    first.free()
    second.free()


func test_is_more_top_right_same_y() -> void :
    var first: Control = Control.new()
    first.global_position = Vector2(100, 0)
    var second: Control = Control.new()
    second.global_position = Vector2(0, 0)

    assert_bool(node_utils.is_more_top_right(second, first)).is_equal(true)

    first.free()
    second.free()


func test_get_node_for_side_right() -> void :
    var first: Control = Control.new()
    first.global_position = Vector2(100, 0)
    first.focus_mode = Control.FOCUS_ALL
    var second: Control = Control.new()
    second.global_position = Vector2(0, 100)
    second.focus_mode = Control.FOCUS_ALL
    add_child(first)
    add_child(second)

    assert_object(first).is_equal(node_utils.get_node_for_side(
        Constants.FocusSide.RIGHT, [second, first])
    )


func test_get_node_for_side_left() -> void :
    var first: Control = Control.new()
    first.global_position = Vector2(0, 0)
    first.focus_mode = Control.FOCUS_ALL
    var second: Control = Control.new()
    second.global_position = Vector2(100, 100)
    second.focus_mode = Control.FOCUS_ALL
    add_child(first)
    add_child(second)

    assert_object(first).is_equal(node_utils.get_node_for_side(
        Constants.FocusSide.LEFT, [second, first])
    )
