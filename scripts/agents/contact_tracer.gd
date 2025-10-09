## Tracks and processes agent proximity for infection spread.
## Why: Uses a uniform grid spatial partition (fixed-size cells) to replace O(n²)
##      distance checks with localized neighbor evaluations.
class_name ContactTracer


## Infection radius in world units.
var transmission_radius: float:
	set = set_transmission_radius

## Cached squared radius for fast checks without sqrt.
var transmission_radius_sq: float

## Probability of infection per valid contact (1.0 = certain).
var transmission_probability: float:
	set = set_transmission_probability

## Upper agent limit stored per grid cell to prevent overflow.
var max_per_cell: int


## Reference to AgentStateManager for SEIR state updates.
var state: AgentStateManager

## Total number of agents used to size buffers consistently.
var agent_count: int

## World boundary in game units; used for grid scaling.
var bounds: Vector2:
	set = set_bounds


## Side length of each partition cell (derived from infection radius).
var cell_size: float

## Number of cells horizontally and vertically.
var grid_width: int
var grid_height: int


## Flattened storage of infectious agent IDs for all cells.
var infectious_cells_flat: PackedInt32Array

## Starting offset of each cell’s reserved block within the flat array.
var cell_start: PackedInt32Array

## Count of filled infectious entries per cell.
var cell_count: PackedInt32Array


## Temporary list of susceptible agent IDs detected during current frame.
var susceptible_list: PackedInt32Array

## Precomputed neighbor index offsets for visiting 3×3 grid cells around a target cell.
var neighbor_offsets: PackedInt32Array

## Buffer storing all infectious IDs from neighboring cells; reused each frame.
var neighbor_infectious_ids: PackedInt32Array


## Initializes all buffers, geometry, and infection parameters from configuration.
## Why: Ensures all grid data is ready before simulation starts.
func _init(
	agent_count_: int,
	bounds_: Vector2,
	state_: AgentStateManager,
	cfg: InfectionConfig
) -> void:
	agent_count = agent_count_
	state = state_
	bounds = bounds_
	transmission_radius = cfg.transmission_radius
	transmission_radius_sq = cfg.transmission_radius_sq
	transmission_probability = cfg.transmission_probability
	max_per_cell = cfg.max_per_cell

	cell_size = transmission_radius
	neighbor_infectious_ids.resize(9 * max_per_cell)

	_calculate_grid()

	susceptible_list = PackedInt32Array()
	susceptible_list.resize(agent_count)


## Builds grid geometry and preallocates contiguous memory blocks per cell.
## Why: Guarantees deterministic memory layout, avoiding dynamic allocation during runtime.
func _calculate_grid() -> void:
	grid_width = max(1, int(bounds.x / cell_size) + 1)
	grid_height = max(1, int(bounds.y / cell_size) + 1)
	var cell_total: int = grid_width * grid_height

	cell_start = PackedInt32Array(); cell_start.resize(cell_total)
	infectious_cells_flat = PackedInt32Array(); infectious_cells_flat.resize(cell_total * max_per_cell)
	cell_count = PackedInt32Array(); cell_count.resize(cell_total)

	for i: int in range(cell_total):
		cell_start[i] = i * max_per_cell

	var arr: Array[int] = []
	for y: int in range(-1, 2):
		for x: int in range(-1, 2):
			arr.append(y * grid_width + x)
	neighbor_offsets = PackedInt32Array(arr)


## Core infection logic: buckets infectious agents into cells, then tests susceptible agents
## against infectious ones within neighboring cells (3×3 region).
func infect_contacts(positions: PackedVector2Array, states: PackedInt32Array) -> void:
	cell_count.fill(0)
	var sus_count: int = 0

	# Pass 1: bucket infectious and record all susceptibles
	for agent_id: int in range(agent_count):
		var pos: Vector2 = positions[agent_id]
		var cell_x: int = int(pos.x / cell_size)
		var cell_y: int = int(pos.y / cell_size)
		if cell_x < 0 or cell_x >= grid_width or cell_y < 0 or cell_y >= grid_height:
			continue

		var cell_index: int = cell_y * grid_width + cell_x
		if states[agent_id] == AgentStateManager.AgentState.INFECTIOUS:
			var insert_pos: int = cell_start[cell_index] + cell_count[cell_index]
			if insert_pos < cell_start[cell_index] + max_per_cell:
				infectious_cells_flat[insert_pos] = agent_id
				cell_count[cell_index] += 1
		elif states[agent_id] == AgentStateManager.AgentState.SUSCEPTIBLE:
			susceptible_list[sus_count] = agent_id
			sus_count += 1

	# Pass 2: test susceptibles against infectious neighbors
	for i: int in range(sus_count):
		var sus_id: int = susceptible_list[i]
		var sus_pos: Vector2 = positions[sus_id]
		var cell_x: int = int(sus_pos.x / cell_size)
		var cell_y: int = int(sus_pos.y / cell_size)
		if cell_x < 0 or cell_x >= grid_width or cell_y < 0 or cell_y >= grid_height:
			continue

		var base_index: int = cell_y * grid_width + cell_x
		var infectious_contact_count: int = 0

		for offset: int in neighbor_offsets:
			var neighbor_index: int = base_index + offset
			if neighbor_index < 0 or neighbor_index >= grid_width * grid_height:
				continue
			var start: int = cell_start[neighbor_index]
			var count: int = cell_count[neighbor_index]
			for j: int in range(count):
				neighbor_infectious_ids[infectious_contact_count] = infectious_cells_flat[start + j]
				infectious_contact_count += 1

		if infectious_contact_count == 0:
			continue

		# Normalize probability per-contact for stable total frame infection odds.
		var contact_probability: float = 1.0 - pow(
			1.0 - transmission_probability,
			1.0 / float(infectious_contact_count)
		)

		for contact_index: int in range(infectious_contact_count):
			var infectious_id: int = neighbor_infectious_ids[contact_index]
			var dx: float = sus_pos.x - positions[infectious_id].x
			var dy: float = sus_pos.y - positions[infectious_id].y
			if dx * dx + dy * dy <= transmission_radius_sq and randf() < contact_probability:
				state.set_state(sus_id, AgentStateManager.AgentState.EXPOSED)
				break


## Updates grid bounds when simulation limits change.
func set_bounds(new_bounds: Vector2) -> void:
	bounds = new_bounds
	_calculate_grid()


## Adjusts infection radius and rebuilds cell geometry accordingly.
func set_transmission_radius(radius: float) -> void:
	transmission_radius = radius
	transmission_radius_sq = transmission_radius * transmission_radius
	cell_size = transmission_radius
	_calculate_grid()


## Updates probability used for transmission checks.
func set_transmission_probability(probability: float) -> void:
	transmission_probability = probability
