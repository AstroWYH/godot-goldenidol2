@tool
extends ColorRect


signal reordered(new_order: Array[int])

const ANIM_REVEAL: = "reveal"
const PhraseScene: = preload("res://shared/ui/phrase/phrase.tscn")
const PhraseGridSlotScene: = preload("res://shared/ui/inventory/phrase_grid_slot/phrase_grid_slot.tscn")

@export var phrases: Array[PhraseGridItem] = []
@export var cell_size: Vector2 = Vector2i(140, 40)
@export var infinite: = true:
    set = set_infinite
@export var extra_empty_cells: int = 0
@export var columns: int = 1:
    set = set_columns
@export var track_item_usage: bool = true
@export var v_separation: int = 4:
    set = set_v_separation
@export var h_separation: int = 4:
    set = set_h_separation
@export var protect_slotted_draggable: bool:
    set = set_protect_slotted_draggable

var id: int = 0
var obscured: bool = false:
    set = set_obscured
var last_focused_phrase: Phrase

var grid_nodes: Array[Node] = []

var _layout_hash: int = 0
var _remove_queue: Array = []
var _last_focused_child_idx: int = 0

@onready var container: GridContainer = % Container
@onready var segment_block: NinePatchRect = % PictureSegmentBlock
@onready var animation_player: AnimationPlayer = % AnimationPlayer


func _ready() -> void :
    reset_phrases()
    set_columns(columns)
    set_obscured(obscured)
    set_v_separation(v_separation)
    set_h_separation(h_separation)

    if not Engine.is_editor_hint():
        DragAndDropManager.state_changed.connect(_on_dragdrop_state_changed)
        DragAndDropManager.dragged_node_released.connect(_on_dragged_node_released)


func set_phrases(new_phrases: Array[PhraseGridItem], reset: = true) -> void :
    phrases = new_phrases

    if not container:
        return

    _last_focused_child_idx = 0

    var phrase_count: int = len(phrases)

    if reset:
        for child in container.get_children():
            if not child is PhraseGridSlot:
                continue
            (child as PhraseGridSlot).free_draggable()

    var max_child_idx: int = container.get_child_count() - 1

    for i in range(phrase_count):
        var phrase_grid_item: PhraseGridItem = phrases[i]

        if not phrase_grid_item:
            continue

        var grid_item_id: int = phrase_grid_item.linked_item_ref_id

        if not grid_item_id or grid_item_id in _remove_queue:
            if i > max_child_idx and not reset:

                _add_empty_slot()
            continue

        var item: GIItem = Database.get_item_by_id(grid_item_id)

        if not item.type == GIItem.GIItemType.PHRASE:
            continue

        var track_last_focused_child: Callable = func() -> void : _last_focused_child_idx = i

        if i <= max_child_idx:
            var child: Node = container.get_child(i)
            if child is PhraseGridSlot:
                var slot: PhraseGridSlot = child as PhraseGridSlot
                if slot.slotted_id == grid_item_id:

                    continue
                elif slot.slotted_id == 0:

                    var new_phrase: Phrase = PhraseScene.instantiate()
                    new_phrase.set_data_from_item(item)
                    new_phrase.size = cell_size
                    slot.add_child(new_phrase)
                    slot.claim_phrase(new_phrase)
                    new_phrase.focus_entered.connect(track_last_focused_child)
                    continue

        var phrase: = PhraseScene.instantiate()
        var phrase_grid_slot: = _create_phrase_grid_slot()

        if not Engine.is_editor_hint():
            phrase.set_data_from_item(item)
            phrase_grid_slot.ready.connect(
                func() -> void : phrase_grid_slot.claim_phrase(phrase), 
                CONNECT_ONE_SHOT, 
            )
        else:
            phrase.text = item.name

        phrase_grid_slot.name = item.name
        phrase_grid_slot.add_child(phrase)
        phrase.size = cell_size
        phrase_grid_slot.focus_entered.connect(track_last_focused_child)
        phrase.focus_entered.connect(track_last_focused_child)

        container.add_child(phrase_grid_slot)

    for i in range(extra_empty_cells):
        _add_empty_slot()

    _remove_queue = []
    _update_focus_neighbors()


func set_obscured(value: bool) -> void :
    obscured = value
    if segment_block:
        segment_block.visible = value

    if container:

        container.mouse_filter = MOUSE_FILTER_STOP if value else MOUSE_FILTER_PASS

    if not Engine.is_editor_hint():
        for child: Node in container.get_children():
            if not child is Control:
                continue
            (child as PhraseGridSlot).obscured = obscured


func set_columns(column_count: int) -> void :
    columns = column_count

    if container:
        container.columns = columns

    if not container:
        return

    _update_focus_neighbors()


func set_infinite(is_infinite: bool) -> void :
    infinite = is_infinite
    if container:
        for c in container.get_children():
            c.keep_copy_on_drop = is_infinite


func set_v_separation(value: int) -> void :
    v_separation = value

    if not container:
        return

    container.add_theme_constant_override(&"v_separation", value)


func set_h_separation(value: int) -> void :
    h_separation = value

    if not container:
        return

    container.add_theme_constant_override(&"h_separation", value)


func set_protect_slotted_draggable(v: bool) -> void :
    protect_slotted_draggable = v

    if not container:
        return

    for c in container.get_children():
        c.protect_slotted_draggable = v


func queue_remove_items(item_ids: Array) -> void :
    if not container:
        _remove_queue = item_ids
        return

    for c in container.get_children():
        var item_idx: int = item_ids.find(c.slotted_id)
        if item_idx == -1:
            continue

        c.free_draggable()
        item_ids.remove_at(item_idx)


func request_focus(side: Constants.FocusSide) -> Variant:
    var all_grid_nodes: Array = grid_nodes.duplicate()
    if DragAndDropManager.dragged_node is Phrase:
        var dragged_node: Node = DragAndDropManager.dragged_node
        var drop_receiver: DropReceiver = dragged_node.get_owning_drop_receiver()



        if dragged_node and dragged_node in grid_nodes and drop_receiver and drop_receiver.host and not drop_receiver.host in grid_nodes:
            all_grid_nodes = grid_nodes.duplicate()
            all_grid_nodes.append(drop_receiver.host)

    match side:
        Constants.FocusSide.ANY:
            var last_focus: Node = container.get_child(_last_focused_child_idx)
            if last_focus is PhraseGridSlot:
                (last_focus as PhraseGridSlot).grab_focus()
                return last_focus
            else:
                return NodeUtils.get_node_for_side(side, all_grid_nodes)
        _:
            return NodeUtils.get_node_for_side(side, all_grid_nodes)


func reveal() -> void :
    if animation_player.is_playing():
        return

    if not obscured:
        obscured = true

    for child: Node in container.get_children():
        if not child is PhraseGridSlot:
            continue
        (child as PhraseGridSlot).obscured = false

    animation_player.play(ANIM_REVEAL)
    animation_player.animation_finished.connect(
        func(_anim: String) -> void :
            segment_block.queue_free()
            segment_block = null, 
        CONNECT_ONE_SHOT, 
    )


func reset_phrases() -> void :
    set_phrases(phrases)
    set_infinite(infinite)


func get_phrase_grid_slots() -> Array[PhraseGridSlot]:
    var slots: Array[PhraseGridSlot] = []
    slots.assign(container.get_children())
    return slots


func _create_phrase_grid_slot() -> Control:
    var phrase_grid_slot: = PhraseGridSlotScene.instantiate()
    if track_item_usage:
        phrase_grid_slot.track_item_usage = true
    phrase_grid_slot.custom_minimum_size = cell_size

    return phrase_grid_slot


func _add_empty_slot() -> void :
    container.add_child(_create_phrase_grid_slot())


func _get_layout() -> Array[int]:
    var layout: Array[int] = []
    for child in container.get_children():
        layout.append(child.slotted_id)

    return layout


func _on_dragdrop_state_changed() -> void :
    var new_layout: Array[int] = _get_layout()
    var new_hash: int = new_layout.hash()

    if _layout_hash == new_hash:
        return

    _layout_hash = new_hash
    reordered.emit(new_layout)


func _set_seg_block_size() -> void :
    var ui_scale: Vector2 = Vector2.ONE
    if not Engine.is_editor_hint():
        ui_scale = SettingsManager.get_setting(SettingsManager.Keys.SECTION_GENERAL, SettingsManager.Keys.SETTING_UI_SCALE)

    var size_offset: int = 56
    segment_block.size = container.size + Vector2(size_offset, size_offset + 8)
    segment_block.global_position = container.global_position - (Vector2(size_offset / 2, size_offset / 2) * ui_scale.x)


func _on_container_resized() -> void :
    if container.size.y == 0 or container.size.x == 0:
        return
    call_deferred("_set_seg_block_size")


func _update_focus_neighbors() -> void :
    if Engine.is_editor_hint():
        return

    grid_nodes = []
    for child in container.get_children():
        if child.is_queued_for_deletion():
            continue
        var slotted_draggable: Node = child.drop_receiver.slotted_node

        if child is Control:
            NodeUtils.reset_focus_neighbors(child as Control)

        if not slotted_draggable is Node:
            grid_nodes.append(child)
            continue

        var phrase: Phrase = slotted_draggable as Phrase
        NodeUtils.reset_focus_neighbors(phrase)
        grid_nodes.append(phrase)

    var grid_node_count: int = len(grid_nodes)

    var row_count: int = ceil(float(grid_node_count) / columns)

    for i in grid_node_count:
        var phrase_or_slot: Node = grid_nodes[i]
        if not phrase_or_slot is Control:
            continue





        var parent_var: Variant = phrase_or_slot.get_parent()
        if not parent_var is Control:
            continue

        var parent: Control = parent_var as Control
        var setup_parent: bool = false
        if phrase_or_slot is Phrase and parent is PhraseGridSlot:
            setup_parent = true

        @warning_ignore("integer_division")
        var row_0idx: int = i / columns

        if i % columns != 0:

            var path: NodePath = (grid_nodes[i - 1]).get_path()
            phrase_or_slot.focus_neighbor_left = path
            if setup_parent:
                parent.focus_neighbor_left = path

        if i != (columns * (row_0idx + 1)) - 1 and i + 1 < grid_node_count:

            var path: NodePath = (grid_nodes[i + 1]).get_path()
            phrase_or_slot.focus_neighbor_right = path
            if setup_parent:
                parent.focus_neighbor_right = path

        if row_0idx != 0:

            var path: NodePath = grid_nodes[i - columns].get_path()
            phrase_or_slot.focus_neighbor_top = path
            if setup_parent:
                parent.focus_neighbor_top = path

        if row_0idx != row_count - 1 and i + columns < grid_node_count:

            var path: NodePath = grid_nodes[i + columns].get_path()
            phrase_or_slot.focus_neighbor_bottom = path
            if setup_parent:
                parent.focus_neighbor_bottom = path


func _on_dragged_node_released() -> void :
    call_deferred("_update_focus_neighbors")
