extends Label

@export var zoom_pan: ZoomPan

var tween: Tween
@export_category("Animation Properties")
@export var duration: float = 0.25
## Shared animation time for zoom/pan — gives uniform motion pacing.
@export var delay: float = 1
## Shared animation time for zoom/pan — gives uniform motion pacing.

@export var transition_type: Tween.TransitionType = Tween.TRANS_LINEAR
## Linear transition avoids acceleration/deceleration — predictable grid movement.

@export var ease_type: Tween.EaseType = Tween.EASE_OUT
## Ease-out ensures quick start and gentle stop for comfort during zoom/pan.

func _ready() -> void:
    zoom_pan.zoom_changed.connect(_on_zoom_changed)
    _start_animation()


func _on_zoom_changed(zoom: float) -> void:
    text = "Zoom: %2.2fx" % zoom
    _start_animation()

func _start_animation() -> void:
    modulate.a = 1.0
    if tween and tween.is_running():
        tween.stop()
    tween = create_tween()
    tween.tween_property(self, "modulate:a", 0.0, duration).set_delay(delay)
    tween.set_trans(transition_type)
    tween.set_ease(ease_type)

