extends Camera2D
## Camera2D with mouse-wheel zoom and drag panning.
## Design intent: keep controls simple, smooth, and bounded by dynamic limits.

@export var zoom_scale: float = 1.1
## Why: multiplicative scaling gives consistent zoom increments at all levels.

@export var min_zoom: float = 0.5
## Why: hard limit avoids extreme zoom-in that would break spatial context.

@export var max_zoom: float = 3.0
## Why: hard limit avoids excessive zoom-out where movement precision is lost.

@export var zoom_duration: float = 0.25
## Why: short but noticeable animation improves visual continuity during zoom/pan.

@export var transition_type: Tween.TransitionType = Tween.TRANS_QUAD
## Why: quadratic easing gives a smooth start/stop without abrupt jumps.

@export var ease_type: Tween.EaseType = Tween.EASE_OUT
## Why: ease-out keeps motion fast initially but slows down for precise positioning.

var target_zoom: float
## Holds desired zoom state so tween can interpolate toward it smoothly.

var target_position: Vector2
## Holds desired camera position for smooth panning via tweening.

var zoom_tween: Tween
## Separate tween for zoom — allows independent stopping/starting when user changes zoom rapidly.

var pan_tween: Tween
## Separate tween for panning — same reasoning as zoom_tween.

func _ready() -> void:
	## Why: initial state must reflect actual camera properties to avoid jump on first input.
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	update_camera_limits()
	target_zoom = zoom.x
	target_position = position

func _input(event: InputEvent) -> void:
	## Routes input to zoom or pan handlers.
	## Why not combine? Keeping them separate avoids unnecessary branching in hot paths.
	if event is InputEventMouseButton and event.is_pressed():
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				_zoom(zoom_scale)
			MOUSE_BUTTON_WHEEL_DOWN:
				_zoom(1.0 / zoom_scale)
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_pan(event.relative)

func _pan(relative: Vector2) -> void:
	## Moves target position relative to mouse drag, scaled by current zoom so speed matches visual scale.
	target_position -= relative / target_zoom
	if pan_tween and pan_tween.is_running():
		pan_tween.stop()  # Prevents fight between tweens when user drags again.
	pan_tween = create_tween()
	pan_tween.tween_property(self, "position", target_position, zoom_duration)
	pan_tween.set_trans(transition_type)
	pan_tween.set_ease(ease_type)

func _zoom(scale_factor: float) -> void:
	## Computes new zoom clamped to allowed range.
	var new_zoom: float = clamp(target_zoom * scale_factor, min_zoom, max_zoom)
	if is_equal_approx(new_zoom, target_zoom):
		return  # No visual change, avoid redundant tween.

	target_zoom = new_zoom
	if zoom_tween and zoom_tween.is_running():
		zoom_tween.stop()
	zoom_tween = create_tween()
	zoom_tween.tween_property(self, "zoom", Vector2(target_zoom, target_zoom), zoom_duration)
	zoom_tween.set_trans(transition_type)
	zoom_tween.set_ease(ease_type)

func _on_viewport_size_changed() -> void:
	## Why: camera limits must respond to viewport size otherwise zoom/pan may go out of bounds.
	update_camera_limits()

func update_camera_limits() -> void:
	## Calculates allowable camera range based on current viewport dimensions.
	## Current implementation uses viewport size as limits; in a real simulation 
	## this should be replaced with world_bounds minus zoom-adjusted view size.
	var view_size: Vector2 = get_viewport_rect().size
	limit_right  = int(view_size.x)
	limit_bottom = int(view_size.y)
