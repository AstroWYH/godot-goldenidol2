extends RefCounted

enum ScrollTextTokenType{
    PLAIN, 
    SMART, 
    BREAK, 
}

const SMART_TOKEN_OPEN: = "["
const SMART_TOKEN_CLOSE: = "]"


var key_value_pattern: = RegEx.new()


func _init() -> void :
    key_value_pattern.compile("([A-Za-z]+)=([A-Za-z0-9_\\s]+),?")



func parse_text(raw_text: String) -> Array[ScrollTextToken]:
    var current: String = ""
    var parsed: Array[ScrollTextToken] = []
    var current_is_plain: bool = true
    var text_length: = len(raw_text)

    for i in range(text_length):
        var c: String = raw_text[i]

        if c == "\n":
            parsed.append(make_plain_token(current))
            parsed.append(make_linebreak_token())
            current = ""
            current_is_plain = true
            continue

        if i == text_length - 1:
            current += c
            if current_is_plain or c != SMART_TOKEN_CLOSE:
                parsed.append(make_plain_token(current))
            else:
                parsed.append(make_smart_token(current))

            break

        if c == " " and current_is_plain:


            var final: = (current + c).strip_edges()

            if not len(final):
                continue

            parsed.append(make_plain_token(final))
            current = ""
            current_is_plain = true
            continue

        if c == SMART_TOKEN_OPEN:
            if current == "":
                current += c
                current_is_plain = false
                continue


            var final: = current.strip_edges()

            if not len(final):
                continue

            parsed.append(make_plain_token(final))
            current = ""
            current_is_plain = false


        if c == SMART_TOKEN_CLOSE and len(current):
            parsed.append(make_smart_token(current + c))
            current_is_plain = true
            current = ""
            continue


        current += c
        continue

    return parsed


func make_plain_token(raw_text: String) -> ScrollTextToken:
    var token: ScrollTextToken = ScrollTextToken.new()
    token.type = ScrollTextTokenType.PLAIN
    token.content = raw_text.strip_edges()
    return token


func make_smart_token(raw_text: String) -> ScrollTextToken:
    var token: ScrollTextToken = ScrollTextToken.new()
    token.type = ScrollTextTokenType.SMART
    token.content = raw_text
    token.data = {}

    var results: = key_value_pattern.search_all(raw_text)

    if not len(results):
        return token

    for result in results:
        var group: = result.strings
        var result_key: String = group[1]
        var result_value: String = group[2]
        token.data[result_key] = result_value

    return token


func make_linebreak_token() -> ScrollTextToken:
    var token: ScrollTextToken = ScrollTextToken.new()
    token.type = ScrollTextTokenType.BREAK
    token.content = "\n"
    return token


class ScrollTextToken:
    var type: ScrollTextTokenType
    var content: String
    var data: Dictionary



    func is_tag(tag: String) -> bool:
        return content == "%s%s%s" % [SMART_TOKEN_OPEN, tag, SMART_TOKEN_CLOSE]



    func _repr() -> String:
        var type_str: String

        match type:
            ScrollTextTokenType.PLAIN:
                type_str = "plain"
            ScrollTextTokenType.SMART:
                type_str = "smart"
            ScrollTextTokenType.BREAK:
                type_str = "break"

        return type_str.to_upper() + "|" + content
