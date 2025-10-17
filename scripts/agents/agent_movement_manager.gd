## Simulates agent movement with normalized direction vectors and bounded area constraints.
## Why: Uses contiguous PackedVector2Array for positions/directions to optimize memory usage
##      and iteration speed when simulating thousands of agents.
class_name AgentMovementManager

## Total number of agents; fixed for buffer allocation.
var agent_count: int
## Current positions in world space.
var positions: PackedVector2Array
## Normalized movement directions; scaled by speed on update.
var directions: PackedVector2Array
## Uniform movement speed for all agents.
var agent_speed: float
## World bounds for movement area.
var bounds: Vector2


## Initializes movement buffers and stores configuration.
## Why: Preallocates arrays to avoid runtime resizing overhead.
func _init(agent_count_: int, bounds_: Vector2, agent_speed_: float) -> void:
	agent_count = agent_count_
	agent_speed = agent_speed_
	bounds = bounds_

	positions = PackedVector2Array()
	positions.resize(agent_count)
	directions = PackedVector2Array()
	directions.resize(agent_count)


## Assigns random start positions and directions for all agents.
## Why: Ensures uniform distribution and unit-length direction vectors for consistent movement speed.
func randomize() -> void:
	for i: int in range(agent_count):
		positions[i] = Vector2(randf() * bounds.x, randf() * bounds.y)
		directions[i] = Vector2(randf() * 2.0 - 1.0, randf() * 2.0 - 1.0).normalized()


## Returns the projected position after movement for a single agent.
## Why: Utility for predictive checks without mutating the main positions array.
func get_agent_new_position(agent_index: int, delta: float) -> Vector2:
	return positions[agent_index] + directions[agent_index] * agent_speed * delta


## Advances all agent positions by their direction × speed × delta, then applies bounds.
## Why: Central loop keeps movement update tight; bound handling prevents loss from scene area.
func advance(delta: float) -> void:
	for i: int in range(agent_count):
		positions[i] = get_agent_new_position(i, delta)
		bound_movement(i)


## Reflects agent direction when exceeding bounds.
## Why: Simple elastic collision off boundaries keeps agents in simulation area without complex physics.
func bound_movement(agent_index: int) -> void:
	var pos: Vector2 = positions[agent_index]
	if pos.x < 0.0 or pos.x > bounds.x:
		directions[agent_index].x = -directions[agent_index].x
		positions[agent_index].x = clamp(pos.x, 0.0, bounds.x)
	if pos.y < 0.0 or pos.y > bounds.y:
		directions[agent_index].y = -directions[agent_index].y
		positions[agent_index].y = clamp(pos.y, 0.0, bounds.y)


func update_config(cfg: SimulationConfig) -> void:
	agent_count = cfg.agent_count
	agent_speed = cfg.agent_speed
	bounds = cfg.bounds