extends VBoxContainer

const KEY_ENTITY = "entity"

@export var dynamic_puzzle_node: DynamicPuzzleTreeNode:
    set = _set_dynamic_puzzle_node

var owning_entity_id: int

@onready var children_container: = $ChildrenContainer
@onready var line_container: = $LineContainer


func _ready() -> void :
    _set_dynamic_puzzle_node(dynamic_puzzle_node)


func _set_dynamic_puzzle_node(new_node: DynamicPuzzleTreeNode) -> void :
    dynamic_puzzle_node = new_node

    if not children_container:
        return

    if new_node.entity_type == DynamicPuzzleEntity.DynamicPuzzleEntityType.Line:
        var groups: Array[OptionButton] = []
        var option_button: OptionButton

        for i in range(new_node.children.size()):
            var entity: DynamicPuzzleTreeNode = new_node.children[i]
            if i == 0 and entity.entity_type == DynamicPuzzleEntity.DynamicPuzzleEntityType.Choice:
                option_button = _create_option_buttton()
            else:

                var group_option_button: = _create_option_buttton()
                for group_item in entity.children:
                    _add_option(group_option_button, group_item)
                groups.append(group_option_button)
                continue

            if option_button:
                _add_option(option_button, entity)

        if option_button:
            groups.append(option_button)

        var label: = Label.new()
        var label_text: = ""
        var node_content: String = new_node.entity_content
        var options_appended: = false
        var tag_open: = false
        var group_index: = ""

        for i in range(len(node_content)):
            var c: String = node_content[i]
            if c != "{" and c != "}" and not tag_open:
                label_text += c
            elif c == "{":
                label.text = label_text
                line_container.add_child(label)
                label = Label.new()
                label_text = ""
                tag_open = true
            elif c == "}":
                line_container.add_child(groups[int(group_index) if group_index else 0])
                group_index = ""
                options_appended = true
                tag_open = false
            elif tag_open:
                group_index += c

        if not label.is_inside_tree():
            label.text = label_text
            line_container.add_child(label)

        if not options_appended and option_button:
            line_container.add_child(option_button)


func _on_option_selected(idx: int, menu: OptionButton) -> void :
    var option_id: = menu.get_instance_id()

    for child in children_container.get_children():
        if child.owning_entity_id == option_id:
            child.queue_free()

    var meta: Dictionary = menu.get_item_metadata(idx)

    if not meta is Dictionary:
        return

    var entity: Variant = meta[KEY_ENTITY]
    for c: Variant in entity.children:
        var line: = (load(scene_file_path) as PackedScene).instantiate()
        line.dynamic_puzzle_node = c
        line.owning_entity_id = option_id
        children_container.add_child(line)


func _create_option_buttton() -> OptionButton:
    var options: = OptionButton.new()

    options.item_selected.connect(func(index: int) -> void : _on_option_selected(index, options))
    options.add_item("-", 0)

    return options


func _add_option(option_button: OptionButton, dynamic_tree_node: DynamicPuzzleTreeNode) -> void :
    var new_index: = option_button.item_count
    option_button.add_item(dynamic_tree_node.entity_content, new_index)
    option_button.set_item_metadata(new_index, {
        KEY_ENTITY: dynamic_tree_node, 
    })
