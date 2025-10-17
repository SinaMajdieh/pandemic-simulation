extends Node2D
class_name ZoomPan

## Controller for smooth zoom and pan over a Node2D target.
## Why: Provides Camera‑like view manipulation without a Camera2D,
## transforming the scene root directly for independent scaling control.


## Target node transformed during zoom/pan (usually scene root or gameplay layer).
@export var target_node: Node2D

## Factor applied per mouse wheel step — constant proportional zoom behavior.
@export var zoom_scale: float = 1.1

## Minimum and maximum zoom limits to prevent extreme distortion.
@export var min_zoom: float = 0.5
@export var max_zoom: float = 3.0

## Common animation time for both zoom and pan; maintains visually uniform pacing.
@export var zoom_duration: float = 0.25

## Linear transition gives predictable positional motion (no acceleration curve).
@export var transition_type: Tween.TransitionType = Tween.TRANS_LINEAR

## Ease‑out provides quick start and gentle stop for comfortable interaction.
@export var ease_type: Tween.EaseType = Tween.EASE_OUT


## Current target zoom level; setter recomputes bounds and emits update signal.
var target_zoom: float:
	set(value):
		target_zoom = value
		_update_limits()
		zoom_changed.emit(target_zoom)
signal zoom_changed(zoom: float)


## Target position the node will animate toward when dragging or anchoring during zoom.
var target_position: Vector2

## Tween objects controlling current zoom and pan animations.
var zoom_tween: Tween
var pan_tween: Tween


## Toggles boundary clamping; enables free movement when disabled.
@export var limits_enabled: bool = false:
	set(value):
		limits_enabled = value
		_limit_position(target_position)


## Local coordinate limits (left, top, right, bottom).
## Why: Recomputed dynamically from bounds and zoom so movement remains inside world area.
var limit_left: float = 0.0
var limit_top: float = 0.0
var limit_right: float = 0.0
var limit_bottom: float = 0.0


## Total world bounds and viewport size used for clamping calculations.
var bounds: Vector2:
	set(value):
		bounds = value
		_update_limits()
var size: Vector2:
	set(value):
		size = value
		_update_limits()


## Sets world bounds and viewport size simultaneously.
func set_sizing(new_bounds: Vector2, new_size: Vector2) -> void:
	bounds = new_bounds
	size = new_size


## Initializes controller references and default positions.
## Why: Ensures both target zoom and positional limits are synchronized before first input.
func _ready() -> void:
	if not target_node:
		push_warning("ZoomPan: No target_node assigned.")
		return
	bounds = get_viewport_rect().size
	_update_limits()
	target_zoom = target_node.scale.x
	target_position = target_node.position


## Input handler managing scroll‑wheel zoom and drag‑based panning.
## Why: Integrates camera‑like behaviour directly using mouse events.
func _input(event: InputEvent) -> void:
	if not target_node:
		return
	if not is_mouse_inside_bounds(event):
		return

	if event is InputEventMouseButton and event.is_pressed():
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				_zoom(zoom_scale)
			MOUSE_BUTTON_WHEEL_DOWN:
				_zoom(1.0 / zoom_scale)
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_pan(event.relative)


## Checks that a mouse event occurs within playable area bounds.
## Why: Prevents zoom/pan from triggering when pointer is outside simulation region.
func is_mouse_inside_bounds(event: InputEvent) -> bool:
	if event is InputEventMouse:
		var local_mouse: Vector2 = to_local(event.position)
		var rect: Rect2 = Rect2(Vector2.ZERO, size)
		return rect.has_point(local_mouse)
	return false


## Handles panning logic (drag movement).
## Why: Divides by zoom to maintain constant pan speed in screen space.
func _pan(relative: Vector2) -> void:
	target_position += relative / target_zoom
	target_position = _limit_position(target_position)

	if pan_tween and pan_tween.is_running():
		pan_tween.stop()
	pan_tween = create_tween()
	pan_tween.tween_property(target_node, "position", target_position, zoom_duration)
	pan_tween.set_trans(transition_type)
	pan_tween.set_ease(ease_type)


## Handles zoom‑in/zoom‑out logic with anchoring at viewport center.
## Why: Combines scale and position transitions in parallel to keep center fixed.
func _zoom(scale_factor: float) -> void:
	var new_zoom: float = clamp(target_zoom * scale_factor, min_zoom, max_zoom)
	if is_equal_approx(new_zoom, target_zoom):
		return

	var zoom_factor: float = new_zoom / target_zoom  # relative zoom multiplier
	target_zoom = new_zoom
	target_position = _predict_position_after_zoom(size * 0.5, zoom_factor)

	if zoom_tween and zoom_tween.is_running():
		zoom_tween.stop()

	zoom_tween = create_tween()
	zoom_tween.tween_property(target_node, "scale", Vector2(target_zoom, target_zoom), zoom_duration)
	zoom_tween.set_trans(transition_type)
	zoom_tween.set_ease(ease_type)
	zoom_tween.parallel()
	zoom_tween.tween_property(target_node, "position", target_position, zoom_duration)
	zoom_tween.set_trans(transition_type)
	zoom_tween.set_ease(ease_type)


## Predicts new target position so chosen zoom anchor (in screen coords) remains fixed.
## Why: Prevents the common “zoom into corner” error by compensating world offset.
func _predict_position_after_zoom(zoom_point: Vector2, zoom_scale_: float) -> Vector2:
	var local_offset: Vector2 = target_position - zoom_point
	local_offset *= zoom_scale_
	return _limit_position(local_offset + zoom_point)


## Recomputes positional limits based on current bounds and zoom.
## Why: Ensures clamping remains correct when zoom level or window size changes.
func _update_limits() -> void:
	limit_left = 0.0
	limit_top = 0.0
	limit_right = bounds.x * (1 - target_zoom) - (bounds.x - size.x)
	limit_bottom = bounds.y * (1 - target_zoom) - (bounds.y - size.y)


## Clamps position to defined boundaries.
## Why: Keeps view inside world limits even after zoom‑based shrinking.
func _limit_position(pos: Vector2) -> Vector2:
	if not limits_enabled:
		return pos
	return Vector2(
		clamp(pos.x, limit_right, limit_left),
		clamp(pos.y, limit_bottom, limit_top)
	)
