@tool
extends Container

const TOKEN_DATA_GLYPH: String = "glyph"
const TOKEN_CROSSOUT_START: String = "xstart"
const TOKEN_CROSSOUT_END: String = "xend"
const TOKEN_UNDERLINE_START: String = "ulstart"
const TOKEN_UNDERLINE_END: String = "ulend"
const COLOR_UNDERLINE: Color = Color(0.698, 0, 0)
const UNDERLINE_OFFSET: int = 10
const UNDERLINE_HEIGHT: int = 3
const CROSSOUT_CHAR: String = "X"
const DEFAULT_FONT_SIZE: int = 16

const ScrollTextParser: = preload("res://shared/ui/scroll_text/scroll_text_parser.gd")
const GlyphMarkerScene: = preload("res://shared/ui/glyph_container/glyph_marker/glyph_marker.tscn")

@export var label_settings: LabelSettings:
    set = _set_label_settings
@export_multiline var text: String:
    set = _set_text
@export var h_separation: int = 4:
    set = _set_h_separation
@export var v_separation: int = 4:
    set = _set_v_separation

var parser: ScrollTextParser = ScrollTextParser.new()
var _glyphs: Dictionary = {}

var _crossout_pairs: Array[Array] = []
var _crossout_start: GlyphMarker

var _underline_pairs: Array[Array] = []
var _underline_start: GlyphMarker

@onready var flow_container: FlowContainer = % FlowContainer
@onready var overlay: Control = % Overlay


func _ready() -> void :
    _set_glyphs()
    _set_text(text)
    flow_container.set("theme_override_constants/v_separation", v_separation)
    flow_container.set("theme_override_constants/h_separation", h_separation)

    if Engine.is_editor_hint():

        child_entered_tree.connect(
            func(child: Node) -> void :
                if overlay and overlay.is_ancestor_of(child):
                    return

                _set_glyphs()
                _set_text(text)

                var fn: Callable = _on_child_renamed.bind(child)
                if not child.renamed.is_connected(fn):
                    child.renamed.connect(fn)
        )


func _set_glyphs() -> void :
    _glyphs.clear()

    for child in get_children():
        if child == flow_container or child == overlay:
            continue

        if not child is CanvasItem:
            continue

        _glyphs[child.name] = child
        (child as CanvasItem).hide()


func _set_text(value: String) -> void :
    text = tr(value)

    if not flow_container or not overlay:
        return

    var children: Array = flow_container.get_children()
    children.append_array(overlay.get_children())

    for child: Node in children:
        child.queue_free()

    _crossout_pairs.clear()

    var tokens: Array[ScrollTextParser.ScrollTextToken] = parser.parse_text(text)
    var dividers: Array[Control] = []

    for token in tokens:
        match token.type:
            ScrollTextParser.ScrollTextTokenType.PLAIN:
                var label: Label = Label.new()

                if label_settings is LabelSettings:
                    label.label_settings = label_settings

                var content: String = token.content
                label.text = token.content

                flow_container.add_child(label)
            ScrollTextParser.ScrollTextTokenType.SMART:
                if _handle_glyph_token(token):
                    continue
                if _handle_markers(token):
                    continue
            ScrollTextParser.ScrollTextTokenType.BREAK:
                var divider: Control = Control.new()
                divider.mouse_filter = divider.MOUSE_FILTER_IGNORE
                dividers.append(divider)
                flow_container.add_child(divider)

    call_deferred("_size_dividers", dividers, 0)


func _set_label_settings(new_label_settings: LabelSettings) -> void :
    label_settings = new_label_settings
    _set_text(text)


func _size_dividers(dividers: Array[Control], idx: int) -> void :
    if idx > dividers.size() - 1:

        if is_inside_tree():
            await get_tree().process_frame
        _render_crossouts()
        _render_underlines()
        return

    var d: = dividers[idx]
    d.custom_minimum_size = Vector2(
        (flow_container.size.x - d.position.x) as float, 
        1.0, 
    )

    call_deferred("_size_dividers", dividers, idx + 1)


func _on_child_renamed(child: Node) -> void :
    _glyphs[child.name] = child


func _handle_glyph_token(token: ScrollTextParser.ScrollTextToken) -> bool:
    var glyph_id: Variant = token.data.get(TOKEN_DATA_GLYPH)
    if not glyph_id in _glyphs:
        return false

    var child: Node = (_glyphs[glyph_id] as Node).duplicate()
    child.show()
    flow_container.add_child(child)
    return true


func _handle_markers(token: ScrollTextParser.ScrollTextToken) -> bool:
    var crossout_start: bool = token.is_tag(TOKEN_CROSSOUT_START)
    var crossout_end: bool = token.is_tag(TOKEN_CROSSOUT_END)
    var underline_start: bool = token.is_tag(TOKEN_UNDERLINE_START)
    var underline_end: bool = token.is_tag(TOKEN_UNDERLINE_END)

    var is_start: bool = crossout_start or underline_start
    var is_end: bool = crossout_end or underline_end

    if is_start or is_end:
        var marker: GlyphMarker = GlyphMarkerScene.instantiate()
        marker.is_start_marker = is_start

        if not Engine.is_editor_hint():
            marker.color = Color.TRANSPARENT

        flow_container.add_child(marker)

        if is_start:
            if crossout_start:
                _crossout_start = marker
            if underline_start:
                _underline_start = marker

        if is_end:
            if crossout_end:
                _crossout_pairs.append([_crossout_start, marker])
            if underline_end:
                _underline_pairs.append([_underline_start, marker])

        return true

    return false


func _render_crossouts() -> void :
    var font_size: int = DEFAULT_FONT_SIZE
    var label_settings_font: Font
    if label_settings and label_settings.font_size:
        font_size = label_settings.font_size

    if label_settings and label_settings.font:
        label_settings_font = label_settings.font

    for pair: Array in _crossout_pairs:
        var start: GlyphMarker = pair[0]
        var end: GlyphMarker = pair[1]
        var label: Label = Label.new()

        if label_settings:
            label.label_settings = label_settings



        var width: float = end.position.x - start.position.x
        var final_text: String = ""

        var line: TextLine = TextLine.new()
        var default_font: Font = label.get_theme_default_font()
        var final_font: Font = label_settings_font if label_settings_font is Font else default_font

        var char_width_line: TextLine = TextLine.new()
        char_width_line.add_string(CROSSOUT_CHAR, final_font, font_size)
        var char_width: float = char_width_line.get_line_width()

        while line.get_line_width() <= width:
            line = TextLine.new()
            var created: bool = line.add_string(final_text, final_font, font_size)

            if not created:
                break

            var line_width: float = line.get_line_width()
            if line_width >= width:
                if line_width - width >= char_width:
                    final_text = final_text.substr(0, len(final_text) - 1)
                break

            final_text += CROSSOUT_CHAR

        start.item_rect_changed.connect(
            func() -> void :
                _set_label_pos(label, start)
        )

        label.text = final_text
        label.size = Vector2(
            width, 
            font_size, 
        )
        label.text_overrun_behavior = TextServer.OVERRUN_TRIM_CHAR

        call_deferred("_set_label_pos", label, start)
        overlay.add_child(label)


func _render_underlines() -> void :
    var underline_label_settings: LabelSettings
    var underline_font_scale: float = 0.5
    var underline_baseline_shift: float = 1 - underline_font_scale
    var underline_scene: PackedScene = load("res://shared/ui/glyph_container/assets/underline.tscn")
    var font_size: int

    if label_settings:
        underline_label_settings = label_settings.duplicate()
        if label_settings.font_size:
            font_size = int(label_settings.font_size * underline_font_scale)
            underline_label_settings.font_size = font_size
    else:
        underline_label_settings = LabelSettings.new()
        font_size = int(DEFAULT_FONT_SIZE * underline_font_scale)
        underline_label_settings.font_size = font_size

    underline_label_settings.font_color = COLOR_UNDERLINE

    for i: int in len(_underline_pairs):
        var pair: Array = _underline_pairs[i]
        var start: GlyphMarker = pair[0]
        var end: GlyphMarker = pair[1]
        var label: Label = Label.new()

        label.label_settings = underline_label_settings
        label.text = str(i + 1)

        call_deferred("_set_footnote_pos", label, end, underline_baseline_shift)
        overlay.add_child(label)

        var end_index: int = end.get_index()
        for idx: int in range(start.get_index() + 1, end_index):
            var c: Node = flow_container.get_child(idx)
            if not c is Control:
                continue

            var node: Control = c as Control

            var extra_space: float = 0
            var node_width: float = node.size.x
            var node_end: float = node.position.x + node_width
            if idx != end_index - 1:


                var next: Node = flow_container.get_child(idx + 1)
                if next is Control:
                    var next_control: Control = next as Control
                    if next_control.position.y == node.position.y:
                        extra_space = (next as Control).position.x - node_end

            var width: float = node.size.x + extra_space

            var underline_texture: NinePatchRect = underline_scene.instantiate()
            underline_texture.position = Vector2(
                node.position.x, 
                node.position.y + UNDERLINE_OFFSET + font_size + 3
            )
            underline_texture.size = Vector2(width, UNDERLINE_HEIGHT)

            overlay.add_child(underline_texture)


func _set_footnote_pos(label: Label, end_marker: GlyphMarker, baseline_shift: float) -> void :
    var final_position: Vector2 = Vector2(
        end_marker.position.x, 
        end_marker.position.y - baseline_shift, 
    )
    label.position = final_position


func _set_label_pos(label: Label, start_marker: GlyphMarker) -> void :
    label.position = start_marker.position


func _set_v_separation(separation: int) -> void :
    v_separation = separation


func _set_h_separation(separation: int) -> void :
    h_separation = separation
