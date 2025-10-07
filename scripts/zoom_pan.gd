extends Node2D
class_name ZoomPan
## Controller for smooth zoom and pan of a target Node2D.
## Why: This mirrors Camera2D behaviour without using an actual camera,
## allowing scalable control by transforming the scene root directly.

@export var target_node: Node2D
## Target Node2D to transform (scene root or game layer).

@export var zoom_scale: float = 1.1
## Multiplicative factor per wheel step — consistent % change regardless of current zoom.

@export var min_zoom: float = 0.5
@export var max_zoom: float = 3.0
## These define allowed visual scale range to prevent extreme zoom distortion.

@export var zoom_duration: float = 0.25
## Shared animation time for zoom/pan — gives uniform motion pacing.

@export var transition_type: Tween.TransitionType = Tween.TRANS_LINEAR
## Linear transition avoids acceleration/deceleration — predictable grid movement.

@export var ease_type: Tween.EaseType = Tween.EASE_OUT
## Ease-out ensures quick start and gentle stop for comfort during zoom/pan.

var target_zoom: float:
	set(value):
		target_zoom = value
		_update_limits()
## Stores where we want to end up zoom-wise; setter recalculates bounds immediately.

var target_position: Vector2
## The “target” position the node will animate toward during panning or zoom anchoring.

var zoom_tween: Tween
var pan_tween: Tween

@export var limits_enabled: bool = false:
	set(value):
		limits_enabled = value
		_limit_position(target_position)
## Toggle positional clamping; useful when free movement is allowed temporarily.

var limit_left: float = 0.0
var limit_top: float = 0.0
var limit_right: float = 0.0
var limit_bottom: float = 0.0
## Camera bounds expressed in local coordinates; recomputed via _update_limits().

var bounds: Vector2:
	set(value):
		bounds = value
		_update_limits()
## World size in pixels; must be set so clamping math works.

func _ready() -> void:
	if not target_node:
		push_warning("ZoomPan: No target_node assigned.")
		return
	
	bounds = get_viewport_rect().size
	_update_limits()
	
	target_zoom = target_node.scale.x
	target_position = target_node.position

func _input(event: InputEvent) -> void:
	if not target_node:
		return
	if event is InputEventMouseButton and event.is_pressed():
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				_zoom(zoom_scale)
			MOUSE_BUTTON_WHEEL_DOWN:
				_zoom(1.0 / zoom_scale)
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_pan(event.relative)

func _pan(relative: Vector2) -> void:
	## Dividing by target_zoom keeps panning speed constant in screen space
	## even when world units are scaled (otherwise pan would feel too fast/slow).
	target_position += relative / target_zoom
	target_position = _limit_position(target_position)
	
	if pan_tween and pan_tween.is_running():
		pan_tween.stop()  # Prevent overlapping animations when dragging fast.
	
	pan_tween = create_tween()
	pan_tween.tween_property(target_node, "position", target_position, zoom_duration)
	pan_tween.set_trans(transition_type)
	pan_tween.set_ease(ease_type)

func _zoom(scale_factor: float) -> void:
	var new_zoom: float = clamp(target_zoom * scale_factor, min_zoom, max_zoom)
	if is_equal_approx(new_zoom, target_zoom):
		return
	
	## zoom_factor is relative change — used to scale positions around anchor.
	var zoom_factor: float = new_zoom / target_zoom
	target_zoom = new_zoom
	
	## Predict camera position after scaling around viewport center.
	## This avoids “zoom into top-left” problem by computing offset that keeps
	## the center of the viewport fixed in world coordinates.
	target_position = _predict_position_after_zoom(bounds * 0.5, zoom_factor)

	if zoom_tween and zoom_tween.is_running():
		zoom_tween.stop()
	
	## Parallel tween for zoom and pan — ensures both finish simultaneously.
	zoom_tween = create_tween()
	zoom_tween.tween_property(target_node, "scale", Vector2(target_zoom, target_zoom), zoom_duration)
	zoom_tween.set_trans(transition_type) 
	zoom_tween.set_ease(ease_type)
	zoom_tween.parallel()
	zoom_tween.tween_property(target_node, "position", target_position, zoom_duration)
	zoom_tween.set_trans(transition_type) 
	zoom_tween.set_ease(ease_type)

func _predict_position_after_zoom(zoom_point: Vector2, zoom_scale_: float) -> Vector2:
	## Why: This math changes target_position so that zoom_point (in screen coords)
	## stays in the same place post-scale — critical for anchored zoom behaviour.
	var local_zoom_point: Vector2 = target_position - zoom_point
	local_zoom_point *= zoom_scale_  # Scale offset from zoom_point.
	return _limit_position(local_zoom_point + zoom_point)

func _update_limits() -> void:
	## Limit edges are computed in local space considering total zoom.
	## At higher zoom, the visible area covers less world space,
	## so bounds shrink accordingly.
	limit_left = 0.0
	limit_top = 0.0
	limit_right = bounds.x * (1 - target_zoom)
	limit_bottom = bounds.y * (1 - target_zoom)

func _limit_position(pos: Vector2) -> Vector2:
	if not limits_enabled:
		return pos
	
	## clamp() ensures pos stays between left/right and top/bottom limits.
	## Note: limit_right/limit_bottom may be negative when zoomed in beyond view size.
	return Vector2(
		clamp(pos.x, limit_right, limit_left),
		clamp(pos.y, limit_bottom, limit_top)
	)
