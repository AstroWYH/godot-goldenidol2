extends Control

const PuzzleComponentScene: = preload("res://shared/puzzle/puzzle_component/puzzle_component.tscn")
const PuzzleAnswerContainerScene: = preload("res://shared/puzzle/puzzle_answer_container/puzzle_answer_container.tscn")
const SimplePuzzleAnswerScene: = preload("res://shared/puzzle/puzzle_answer_simple/puzzle_answer_simple.tscn")
const FocusIndicatorScene = preload("res://shared/ui/picture_puzzle/focus_indicator.tscn")
const DropReceiverScene: = preload("res://shared/ui/drop_receiver/drop_receiver.tscn")

var puzzle_answer_container: Control
var puzzle_id: int

@onready var constants: = preload("res://autoload/dragdrop_manager/constants.gd")


func _ready() -> void :
    puzzle_answer_container = get_child(0)


func build_answer_nodes(inventory_data: Dictionary, inventory_data_by_id: Dictionary, tag: String, 
        infinite_inventory: bool, initial_state: Variant) -> Array[Control]:
    var component_id: = 0
    var control_children: Array[Control] = []
    var target_slots: Array[Control] = []
    for c in puzzle_answer_container.get_children():
        if not c is Control:
            continue
        control_children.append(c)

    var state: Array
    if typeof(initial_state) == TYPE_ARRAY:
        state = initial_state
    else:
        state = control_children.map(func(_ctrl: Control) -> int: return 0)


    for i in range(control_children.size()):
        var control: Control = control_children[i]

        component_id += 1

        var host: = ColorRect.new()
        host.focus_mode = Control.FOCUS_ALL
        host.mouse_filter = host.MOUSE_FILTER_STOP
        host.custom_minimum_size = control.custom_minimum_size
        host.size = control.size
        host.position = control.position
        host.name = control.name + "Answer"
        host.color = Color.TRANSPARENT


        host.mouse_entered.connect(
            func() -> void :
                if host.focus_mode == Control.FOCUS_ALL:
                    host.grab_focus()
        )


        var focus_indicator: Control = FocusIndicatorScene.instantiate()
        focus_indicator.hide()
        host.focus_entered.connect(
            func() -> void :
                focus_indicator.show()
                focus_indicator.move_to_front()
        )
        host.focus_exited.connect(
            func() -> void :
                focus_indicator.hide()
        )
        host.add_child(focus_indicator)

        var drop_receiver: DropReceiver = DropReceiverScene.instantiate()
        drop_receiver.draggable_claimed.connect(
            func(_host: CanvasItem, _d: Draggable) -> void :
                if get_viewport().gui_get_focus_owner() == host:
                    focus_indicator.move_to_front()
        )
        drop_receiver.keep_copy_on_drop = false
        drop_receiver.accept_tags = [tag]
        drop_receiver.swap_on_valid_drop = true
        if infinite_inventory:
            drop_receiver.free_draggable_on_invalid_drop = true
        drop_receiver.set_anchors_preset(Control.PRESET_FULL_RECT)
        host.add_child(drop_receiver)
        host.set_script(load("res://shared/ui/picture_puzzle/puzzle_node_handler.gd"))
        drop_receiver.call_deferred("set_meta_ref")



        var slotted_id: int = state[i]
        if slotted_id != 0:
            var data: RefCounted = inventory_data_by_id[slotted_id]
            var slotted_tile: = DragAndDropManager.duplicate_draggable_host(data.model_node as CanvasItem)

            if not infinite_inventory:

                var draggable: Variant = data.model_node.get_meta(DragAndDropManager.constants.DRAGGABLE_REF)
                if draggable is Draggable:
                    var model_node_drop_receiver: Variant = (draggable as Draggable).owner_drop_receiver
                    if model_node_drop_receiver is DropReceiver:
                        (model_node_drop_receiver as DropReceiver).free_draggable()

                data.model_node.queue_free()
                data.model_node = null

            host.add_child(slotted_tile)
            drop_receiver.ready.connect(
                func() -> void : drop_receiver.claim_draggable(slotted_tile.get_meta(constants.DRAGGABLE_REF) as Draggable), 
                CONNECT_ONE_SHOT, 
            )

        var puzzle_component: PuzzleComponent = PuzzleComponentScene.instantiate()
        puzzle_component.id = component_id
        host.add_child(puzzle_component)
        puzzle_component.call_deferred("set_ref_meta")

        if control is TextureRect:
            var puzzle_answer: PuzzleAnswerSimple = SimplePuzzleAnswerScene.instantiate()
            puzzle_answer.answer_value = inventory_data[(control as TextureRect).texture.resource_path].id
            puzzle_component.add_child(puzzle_answer)
        else:
            for child in control.get_children():


                if not child is TextureRect:
                    continue

                var container: = PuzzleAnswerContainerScene.instantiate()
                var puzzle_answer: PuzzleAnswerSimple = SimplePuzzleAnswerScene.instantiate()
                puzzle_answer.answer_value = inventory_data[
                    (child as TextureRect).texture.resource_path
                ].id
                container.add_child(puzzle_answer)
                puzzle_component.add_child(container)

        target_slots.append(host)


    for i in range(control_children.size()):
        control_children[i].queue_free()
        puzzle_answer_container.add_child(target_slots[i])
    control_children = []

    return target_slots
