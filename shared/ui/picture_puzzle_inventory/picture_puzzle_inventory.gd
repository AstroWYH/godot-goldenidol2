extends Control

const DraggableScene = preload("res://shared/ui/draggable/draggable.tscn")
const PuzzlePieceScene = preload("res://shared/puzzle/puzzle_piece/puzzle_piece.tscn")
const FocusIndicatorScene = preload("res://shared/ui/picture_puzzle/focus_indicator.tscn")
const DropReceiverScene = preload("res://shared/ui/drop_receiver/drop_receiver.tscn")


@export var infinite: = true


var inventory_data: = {}

var inventory_data_by_id: = {}


var drop_receiver_by_id: = {}


var tag: String = str(get_instance_id())

var puzzle_piece_container: Control


func _ready() -> void :
    for c in get_children():
        if c is Control:
            puzzle_piece_container = c
            break


    var id: = 0



    var configured_nodes: Array[Array] = []

    for c in puzzle_piece_container.get_children():
        if not c is TextureRect:
            continue
        id += 1

        var img: TextureRect = c
        var data: = PicturePuzzleInventoryEntry.new()
        data.id = id
        data.model_node = img

        inventory_data[img.texture.resource_path] = data
        inventory_data_by_id[id] = data

        var draggable: Draggable = DraggableScene.instantiate()
        draggable.tag = tag


        var puzzle_piece: Node = PuzzlePieceScene.instantiate()
        puzzle_piece.id = id

        var drop_receiver_host: = Control.new()
        drop_receiver_host.focus_mode = FOCUS_ALL
        drop_receiver_host.name = img.name + "I"
        drop_receiver_host.custom_minimum_size = img.size
        drop_receiver_host.position = img.position
        drop_receiver_host.set_script(load("res://shared/ui/picture_puzzle/puzzle_node_handler.gd"))


        drop_receiver_host.mouse_entered.connect(
            func() -> void :
                if drop_receiver_host.focus_mode == Control.FOCUS_ALL:
                    drop_receiver_host.grab_focus()
        )


        var focus_indicator: Control = FocusIndicatorScene.instantiate()
        focus_indicator.hide()
        drop_receiver_host.focus_entered.connect(
            func() -> void :
                focus_indicator.show()
                focus_indicator.move_to_front()
        )
        drop_receiver_host.focus_exited.connect(
            func() -> void :
                focus_indicator.hide()
        )

        var drop_receiver: DropReceiver = DropReceiverScene.instantiate()
        if infinite:
            drop_receiver.read_only = true
            drop_receiver.duplicate_slotted_draggable_on_drag = true
        else:
            drop_receiver.protect_slotted_draggable = true
        drop_receiver.keep_copy_on_drop = false
        drop_receiver.accept_tags = [tag]
        drop_receiver.set_anchors_preset(Control.PRESET_FULL_RECT)
        drop_receiver_by_id[id] = drop_receiver
        drop_receiver_host.add_child(drop_receiver)
        drop_receiver_host.add_child(focus_indicator)

        img.add_child(draggable)
        img.add_child(puzzle_piece)

        configured_nodes.append([draggable, drop_receiver_host, drop_receiver])

    for configuration in configured_nodes:
        var draggable: Draggable = configuration[0]
        var drop_receiver_host: Control = configuration[1]
        var drop_receiver: DropReceiver = configuration[2]

        puzzle_piece_container.add_child(drop_receiver_host)
        drop_receiver.claim_draggable(draggable)


class PicturePuzzleInventoryEntry:

    var id: int

    var model_node: Control
