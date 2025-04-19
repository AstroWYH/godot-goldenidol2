extends Control

var frames: SpriteFrames
var anim_name: String = "default"
var current_frame: int
var frame_count: int
var was_playing: bool = true

@onready var button: Button = % Button
@onready var animated_sprite: AnimatedSprite2D = % AnimatedSprite2D
@onready var slider: HSlider = % HSlider


func _ready() -> void :
    animated_sprite.frame_changed.connect(advance_slider)

    button.toggled.connect(button_pressed)
    button.set_pressed_no_signal(true)
    frames = animated_sprite.sprite_frames
    frame_count = frames.get_frame_count(anim_name)
    slider.max_value = frame_count
    slider.step = 1
    slider.value = 1
    slider.drag_started.connect(start_dragging)
    slider.value_changed.connect(dragged)
    slider.drag_ended.connect(end_dragging)


    button.text = tr("STOP_BUTTON")


func start_dragging() -> void :
    slider.value = animated_sprite.frame
    was_playing = animated_sprite.is_playing()
    animated_sprite.pause()


func dragged(val: float) -> void :
    var val_int: int = int(val)
    animated_sprite.frame = val_int


func end_dragging(_value_changed: bool) -> void :
    if was_playing:
        animated_sprite.play()


func advance_slider() -> void :
    slider.value = animated_sprite.frame


func button_pressed(pressed: bool) -> void :
    if pressed:
        button.text = tr("STOP_BUTTON")
        animated_sprite.play()


    else:
        button.text = tr("PLAY_BUTTON")
        animated_sprite.pause()
