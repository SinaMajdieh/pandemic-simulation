## Class: AgentManager
## Why: Centralized handler for agent positions, directions, and movement rules.
##      Keeps simulation state logic separate from rendering, enabling scalability.

class_name AgentManager

## Number of agents managed; chosen at initialization for fixed memory allocation.
var agent_count: int

## Stores each agent’s position; avoids per-frame object creation.
var positions: PackedVector2Array

## Stores normalized movement direction for each agent.
var directions: PackedVector2Array

## Constant speed multiplier for all agents; simplifies uniform movement updates.
var agent_speed: float

## Simulation space bounds; prevents agents from leaving the visible area.
var bounds: Vector2


## Initializes agents with random positions and directions.
## Why: Ensures varied starting states to avoid synchronized movement patterns
func _init(agent_count_: int, agent_speed_: float, bounds_: Vector2) -> void:
	agent_count = agent_count_
	agent_speed = agent_speed_
	bounds = bounds_

	# Pre-allocate memory for positions and directions to reduce runtime reallocation.
	positions = PackedVector2Array()
	positions.resize(agent_count)

	directions = PackedVector2Array()
	directions.resize(agent_count)

	_randomize_agents()


## Randomizes initial positions and movement directions.
## Why: Introduces diversity into simulation to make motion visually and statistically dynamic.
func _randomize_agents() -> void:
	for i: int in range(agent_count):
		# Place agents randomly within bounds to avoid clustering at specific points.
		positions[i] = Vector2(
			randf() * bounds.x,
			randf() * bounds.y
		)
		# Provide random 2D direction normalized to ensure uniform movement speed.
		directions[i] = Vector2(
			randf() * 2.0 - 1.0,
			randf() * 2.0 - 1.0
		).normalized()


## Inverts agent movement direction upon exceeding bounds.
## Why: Simulates bounce effect to prevent agents from exiting simulation space.
func bound_movement(index: int) -> void:
	var position: Vector2 = positions[index]
	if position.x < 0.0 or position.x > bounds.x:
		directions[index].x = -directions[index].x  # Reverse X movement to stay inside bounds.
	if position.y < 0.0 or position.y > bounds.y:
		directions[index].y = -directions[index].y  # Reverse Y movement similarly.


## Calculates agent's next position based on velocity and delta time.
## Why: Separates motion math from state update for modularity.
func get_agent_new_position(index: int, delta: float) -> Vector2:
	var new_position: Vector2 = positions[index] + directions[index] * agent_speed * delta
	return new_position


## Advances all agents’ positions based on elapsed time.
## Why: Handles frame-by-frame movement while enforcing boundary rules.
func advance(delta: float) -> void:
	for i: int in range(agent_count):
		positions[i] = get_agent_new_position(i, delta)
		bound_movement(i)  # Keeps agent inside bounds after movement calculation.