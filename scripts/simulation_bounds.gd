## Positions this Node2D relative to another point, typically to center it in a viewport or area.
## Why: Allows dynamic alignment without hardcoding coordinates, making layout responsive to parent or external objects.
extends Node2D

@export var size: Vector2 = Vector2(500, 500) 
## Why: Storing size here avoids repeatedly recalculating from child dimensions or constants.


## Moves this node so its center aligns with a given position.
## Why: The subtraction offsets by half of the node’s size to place its midpoint at the target point.
func center_relative_to(relative_position: Vector2) -> void:
	position = (relative_position - size) / 2
