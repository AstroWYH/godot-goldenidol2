extends Node

const UI_LAYER_INDEX: = 2

const ICON_PHRASES: = preload("res://shared/assets/placeholder_ui/buttons/phrases.png")
const BottomPanelScene = preload("res://shared/ui/thinking_ui/bottom_panel/bottom_panel.tscn")

var LABEL_PHRASES: String = tr("INVENTORY_BUTTON_LABEL")
var host: CanvasItem
var bottom_panel: Control
var _cards: Array[Control] = []
var _thinking_layer: CanvasLayer


func _init(for_host: CanvasItem) -> void :
    host = for_host


func _ready() -> void :
    ContainerDragAndDropManager.container_dropped.connect(func(_x: Control) -> void : _set_available_rect())
    DialogManager.top_changed.connect(_on_dialog_manager_top_changed)


func bootstrap() -> void :
    host.add_child(self)

    _thinking_layer = host.thinking_layer
    _thinking_layer.layer = UI_LAYER_INDEX
    var windows: Array = _thinking_layer.init_windows()

    var bottom_layer: = CanvasLayer.new()
    bottom_layer.layer = UI_LAYER_INDEX
    bottom_panel = BottomPanelScene.instantiate()
    bottom_panel.ready.connect(
        func() -> void : _connect_windows(windows), 
        CONNECT_ONE_SHOT, 
    )

    bottom_layer.add_child(bottom_panel)
    host.add_child(bottom_layer)
    _set_available_rect()



func _connect_windows(windows: Array) -> void :
    var victory_req_puzzle_ids: Array[int] = []

    var has_selected_card: bool = false
    for win: RefCounted in windows:
        var label: String = win.label
        var icon: Texture2D = win.icon


        win.instance.show()


        var is_inventory: bool = not win.puzzles.size()

        if "is_win_condition" in win.instance and win.instance.is_win_condition:
            var ids: Array[int] = []
            for pm: PuzzleMeta in win.puzzles:
                ids.append(pm.puzzle_id)

            victory_req_puzzle_ids.append_array(ids)

        if is_inventory:
            label = LABEL_PHRASES
            icon = ICON_PHRASES

        var card: ThinkingUICard = bottom_panel.add_puzzle_card(win.puzzles, label, icon)
        if is_inventory:
            ProgressManager.inventory_card = card
        card.connect_window(win, is_inventory)
        card.toggled_window.connect(_on_card_toggled_window)
        card.sequence_element_id = win.sequence_element_id
        _cards.append(card)
        if is_inventory and ProgressManager.current_scenario_meta.no_inventory:
            card.hide()
            card.selected = false

        if not has_selected_card and card.selected:
            has_selected_card = true

    if not has_selected_card:

        for card: ThinkingUICard in _cards:
            if card.is_locked():
                continue


            if card.visible:
                card.selected = true
            break

    ProgressManager.win_condition_puzzle_ids = victory_req_puzzle_ids


func _on_card_toggled_window(_opened: bool) -> void :
    _set_available_rect()


func _set_available_rect() -> void :
    var screen: = get_viewport().get_visible_rect()
    var available: = Rect2(screen)
    available.size.y -= available.size.y - (bottom_panel.get_panel_rect() as Rect2).position.y

    var left: = Rect2(available)
    left.size.x = available.size.x / 2
    var right: = Rect2(left)
    right.position.x = left.size.x

    DialogManager.set_available_rect(right)











































func _on_dialog_manager_top_changed(new_id: int) -> void :
    if new_id != 0:
        return

    _set_available_rect()
