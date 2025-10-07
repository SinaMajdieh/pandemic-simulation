extends Control
class_name MetricGraph
## Displays a single metric series as a scrolling line graph inside a Control.
## Why Control: Integrates cleanly into Godot UI layouts (sizing, anchors) while still allowing low-level _draw() calls.

class MetricSeries:
	var name: String
	## Placeholder for future multi-series support — currently unused here,
	## but kept to allow per-series metadata expansion later.

# === Constants ===
const DEFAULT_LINE_COLOR: Color = Color("61AFEF")
## Default gentle blue — good contrast on dark UI without feeling visually aggressive.

# === Exported Settings ===
@export var max_points: int = 200
## Cap on stored data points — keeps memory usage predictable and draw calls bounded.

@export var line_color: Color = DEFAULT_LINE_COLOR
@export var line_width: float = 1.0
@export var hover_threshold: float = 6.0
## Pixel tolerance when detecting hover on the curve — larger allows easier selection but may feel 'loose'.

@export var grid: GraphGrid
## Optional overlay grid reference (not used in _draw here).

# === Internal State ===
var values: Array[float] = []
## Raw metric values in order of arrival; oldest first.

var _hover_index: int = -1
## Tracks which point index the mouse is currently over (-1 = none).
## Why store index: Makes tooltip retrieval faster and avoids recalculating nearest point in multiple places.

func _init(
	line_width_: float = 1.0,
	line_color_: Color = DEFAULT_LINE_COLOR,
	max_points_: int = 200
) -> void:
	line_width = line_width_
	line_color = line_color_
	max_points = max_points_

# === Public API ===
func add_metric(value: float) -> void:
	## Append new value, respecting fixed buffer size.
	values.append(value)
	if values.size() > max_points:
		values.pop_front()  ## Drop oldest — ensures scrolling effect.
	queue_redraw()  ## Triggers _draw() next frame.

func clear() -> void:
	values.clear()
	queue_redraw()

# === Drawing ===
func _draw() -> void:
	if values.size() < 2:
		return  ## Need at least 2 points or nothing can connect.

	## Determine vertical scaling based on min/max of current buffer.
	var value_range: float = _get_value_range()

	## Horizontal distance between consecutive points.
	## Formula: panel width / (N - 1) — ensures graph spans full width.
	var step_x: float = size.x / max(values.size() - 1, 1)

	## Build ordered list of connected segment endpoints.
	var segments: Array[Vector2] = _build_segments(step_x, value_range)

	## Single draw call — more efficient than drawing individual lines.
	draw_multiline(segments, line_color, line_width, true)

# === Event Handling ===
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_update_hover_value(event.position)

# === Hover Logic ===
func _update_hover_value(mouse_position: Vector2) -> void:
	if values.is_empty():
		_hover_index = -1
		return

	## Convert X position into a fractional index in the values array (0 … N-1).
	var step_x: float = size.x / max(values.size() - 1, 1)
	var fractional_index: float = clamp(mouse_position.x / step_x, 0.0, float(values.size() - 1))

	## Nearest left/right buffer indices for interpolation.
	var left_index: int = int(floor(fractional_index))
	var right_index: int = min(left_index + 1, values.size() - 1)
	var factor: float = fractional_index - float(left_index)

	## Predicted curve height at mouse X via linear interpolation — 
	## prevents hover gaps between discrete draw points.
	var y_at_cursor: float = _get_interpolated_y(left_index, right_index, factor)

	## Hover only if mouse Y is close to interpolated curve Y.
	_hover_index = left_index if _is_within_vertical_threshold(mouse_position.y, y_at_cursor) else -1

	## In Godot, get_tooltip() won't auto-call here, so this line preps tooltip reads.
	get_tooltip()

func _is_within_vertical_threshold(mouse_y: float, line_y: float) -> bool:
	## Why: Abs diff <= threshold gives a hover hitbox in vertical direction only.
	return abs(mouse_y - line_y) <= hover_threshold

# === Data / Calculation Helpers ===
func _build_segments(step_x: float, value_range: float) -> Array[Vector2]:
	var segments: Array[Vector2] = []
	var min_value: float = values.min()
	var prev_point: Vector2 = Vector2.ZERO

	for i: int in range(values.size()):
		## Map value to local Y:
		## - Normalize: (value - min) / range   → fraction [0..1]
		## - Invert: size.y - fraction*size.y   → put larger values lower in graph space.
		var x: float = step_x * i
		var y: float = size.y - ((values[i] - min_value) / value_range) * size.y
		var current_point: Vector2 = Vector2(x, y)

		## Append pair for draw_multiline — must be in sequence.
		if i > 0:
			segments.append(prev_point)
			segments.append(current_point)

		prev_point = current_point

	return segments

func _get_value_range() -> float:
	var min_value: float = values.min()
	var max_value: float = values.max()
	var value_range: float = max_value - min_value
	if value_range == 0:
		value_range = 1  ## Prevent division by zero — flat line still renders.
	return value_range

func _get_interpolated_y(left_index: int, right_index: int, t: float) -> float:
	var value_range: float = _get_value_range()
	var min_value: float = values.min()

	## Compute actual pixel Y for each endpoint.
	var y_left: float = size.y - ((values[left_index] - min_value) / value_range) * size.y
	var y_right: float = size.y - ((values[right_index] - min_value) / value_range) * size.y

	## Interpolate between them with factor t.
	return lerp(y_left, y_right, t)

# === Tooltip ===
func _get_tooltip(_at_position: Vector2) -> String:
	## Format active hover value as fixed-point string, else return empty.
	if _hover_index >= 0:
		return "%2.4f" % [values[_hover_index]]
	return ""
