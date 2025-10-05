extends Control
class_name GraphGrid

const DEFAULT_GRID_COLOR: Color = Color("848c9880")

@export var spacing_x: float = 50.0:
	set(value):
		spacing_x = value
		queue_redraw()
@export var spacing_y: float = 50.0:
	set(value):
		spacing_y = value
		queue_redraw()
@export var grid_color: Color = DEFAULT_GRID_COLOR:
	set(value):
		grid_color = value
		queue_redraw()

func _draw() -> void:
	# Vertical lines
	for x: float in range(0.0, size.x, spacing_x):
		draw_line(Vector2(x, 0.0), Vector2(x, size.y), grid_color)
	
	# Horizontal lines
	for y: float in range(0.0, size.y, spacing_y):
		draw_line(Vector2(0.0, y), Vector2(size.x, y), grid_color)

func set_spacing(new_spacing_x: float, new_spacing_y: float) -> void:
	spacing_x = new_spacing_x
	spacing_y= new_spacing_y

func set_color(new_color: Color = DEFAULT_GRID_COLOR) -> void:
	grid_color = new_color