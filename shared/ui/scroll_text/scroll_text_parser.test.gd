class_name ScrollTextParserTest
extends GdUnitTestSuite

const __source = "res://shared/ui/scroll_text/scroll_text_parser.gd"
const ScrollTextParser = preload(__source)

var parser: ScrollTextParser


func before() -> void :
    parser = auto_free(ScrollTextParser.new())


func test_make_plain_token() -> void :
    var token: = parser.make_plain_token("Abracadabra!    ")
    var expected: = ScrollTextParser.ScrollTextToken.new()
    expected.type = ScrollTextParser.ScrollTextTokenType.PLAIN
    expected.content = "Abracadabra!"
    assert_object(token).is_equal(expected)


func test_make_smart_token() -> void :
    var content: = "[foo=bar]"
    var token: = parser.make_smart_token(content)
    var expected: = ScrollTextParser.ScrollTextToken.new()
    expected.type = ScrollTextParser.ScrollTextTokenType.SMART
    expected.content = content
    expected.data = {
        "foo": "bar", 
    }

    assert_object(token).is_equal(expected)


func test_make_smart_token_without_data() -> void :
    var content: = "[foo]"
    var token: = parser.make_smart_token(content)
    var expected: = ScrollTextParser.ScrollTextToken.new()
    expected.type = ScrollTextParser.ScrollTextTokenType.SMART
    expected.content = content
    expected.data = {}

    assert_object(token).is_equal(expected)


func test_make_smart_token_num_value() -> void :
    var content: = "[foo=39]"
    var token: = parser.make_smart_token(content)
    var expected: = ScrollTextParser.ScrollTextToken.new()
    expected.type = ScrollTextParser.ScrollTextTokenType.SMART
    expected.content = content
    expected.data = {
        "foo": "39", 
    }

    assert_object(token).is_equal(expected)


func test_make_smart_token_spaced_value() -> void :
    var content: = "[foo=This has spaces in the value]"
    var token: = parser.make_smart_token(content)
    var expected: = ScrollTextParser.ScrollTextToken.new()
    expected.type = ScrollTextParser.ScrollTextTokenType.SMART
    expected.content = content
    expected.data = {
        "foo": "This has spaces in the value", 
    }

    assert_object(token).is_equal(expected)


func test_make_smart_token_multi_values() -> void :
    var content: = "[foo=bar,baz=xyz]"
    var token: = parser.make_smart_token(content)
    var expected: = ScrollTextParser.ScrollTextToken.new()
    expected.type = ScrollTextParser.ScrollTextTokenType.SMART
    expected.content = content
    expected.data = {
        "foo": "bar", 
        "baz": "xyz", 
    }

    assert_object(token).is_equal(expected)


func test_make_linebreak_token() -> void :
    var token: = parser.make_linebreak_token()
    var expected: = ScrollTextParser.ScrollTextToken.new()
    expected.type = ScrollTextParser.ScrollTextTokenType.BREAK
    expected.content = "\n"
    assert_object(token).is_equal(expected)


func test_plain_parse() -> void :
    var result: = parser.parse_text("Hello world!")
    var expected: = [
        parser.make_plain_token("Hello"), 
        parser.make_plain_token("world!")
    ]

    assert_array(result).is_equal(expected)


func test_multiline_parse() -> void :
    var result: = parser.parse_text("Hello\nworld!")
    var expected: = [
        parser.make_plain_token("Hello"), 
        parser.make_linebreak_token(), 
        parser.make_plain_token("world!")
    ]

    assert_array(result).is_equal(expected)


func test_smart_parse() -> void :
    var result: = parser.parse_text("Hello [name=world]!")
    var expected: = [
        parser.make_plain_token("Hello"), 
        parser.make_smart_token("[name=world]"), 
        parser.make_plain_token("!")
    ]

    assert_array(result).is_equal(expected)


func test_smart_parse_with_smart_as_last() -> void :
    var result: = parser.parse_text("Hello [name=world]")
    var expected: = [
        parser.make_plain_token("Hello"), 
        parser.make_smart_token("[name=world]"), 
    ]

    assert_array(result).is_equal(expected)


func test_smart_multiline_parse() -> void :
    var result: = parser.parse_text("Hello  \n[name=world]!")
    var expected: = [
        parser.make_plain_token("Hello"), 
        parser.make_plain_token(""), 
        parser.make_linebreak_token(), 
        parser.make_smart_token("[name=world]"), 
        parser.make_plain_token("!")
    ]

    assert_array(result).is_equal(expected)


func test_trailing_smart_parse() -> void :
    var result: = parser.parse_text("Hello [name=world")
    var expected: = [
        parser.make_plain_token("Hello"), 
        parser.make_plain_token("[name=world"), 
    ]

    assert_array(result).is_equal(expected)


func test_token_is_tag() -> void :
    var content: = "[foo]"
    var token: = parser.make_smart_token(content)

    assert_bool(token.is_tag("foo")).is_true()


func test_token_is_not_tag() -> void :
    var content: = "[foo]"
    var token: = parser.make_smart_token(content)

    assert_bool(token.is_tag("boo")).is_false()


func test_chinese_scrolltext() -> void :
    var result: = parser.parse_text("[id=10]である[id=1]")
    var expected: = [
        parser.make_smart_token("[id=10]"), 
        parser.make_plain_token("である"), 
        parser.make_smart_token("[id=1]"), 
    ]
    assert_array(result).is_equal(expected)
