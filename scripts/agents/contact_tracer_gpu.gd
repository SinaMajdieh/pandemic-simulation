## Tracks and processes agent proximity for infection spread.
## Why: Implements GPU‑backed spatial partitioning (uniform grid) to replace costly O(n²)
## neighbor pair checks with cell‑localized evaluations, greatly increasing throughput.
extends ContactTracer
class_name ContactTracerGPU

var exposure_chance: PackedFloat32Array

## GPU compute runner handling infection dispatch and buffer management.
## Why: Encapsulates all compute shader operations separate from GDScript orchestration.
var runner: ContactInfectiousRunner


## Initializes geometry, buffers, and infection parameters from configuration.
## Why: Prepares grid metrics once at startup to avoid frame‑time allocation or recalculation.
func _init(
	agent_count_: int,
	bounds_: Vector2,
	state_: AgentStateManager,
	cfg: InfectionConfig
) -> void:
	runner = ContactInfectiousRunner.new()
	agent_count = agent_count_
	state = state_
	bounds = bounds_
	transmission_radius = cfg.transmission_radius
	transmission_radius_sq = cfg.transmission_radius_sq
	transmission_probability = cfg.transmission_probability
	max_per_cell = cfg.max_per_cell

	cell_size = transmission_radius  # Aligns grid cells to infection range.

	exposure_chance = PackedFloat32Array()
	exposure_chance.resize(agent_count)

	_calculate_grid()


## Performs main infection spread logic.
## Why: Partitions agents into grid cells (bucketing) before GPU dispatch so each agent
## only interacts with neighbors within surrounding 3×3 cells, maintaining deterministic exposure.
func infect_contacts(positions: PackedVector2Array, states: PackedInt32Array) -> void:
	cell_count.fill(0)

	# Pass 1: Bucket infectious and record cell occupancy for susceptibles.
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
			exposure_chance[agent_id] = randf()

	var start_time: int = Time.get_ticks_usec()
	# Prepare meta buffer for GPU compute pass.
	var meta_buffer: RID = runner.create_meta_buffer(
		transmission_radius_sq,
		transmission_probability,
		grid_width,
		grid_height,
		max_per_cell,
		cell_size
	)

	# Dispatch GPU infection kernel and collect newly exposed IDs.
	var exposed_id: PackedInt32Array = runner.dispatch(
		positions,
		states,
		infectious_cells_flat,
		cell_start,
		cell_count,
		neighbor_offsets,
		exposure_chance,
		meta_buffer
	)

	# Apply exposure results back to agent state manager.
	for i: int in range(exposed_id.size()):
		if exposed_id[i] == -1:
			continue
		state.set_state(exposed_id[i], AgentStateManager.AgentState.EXPOSED)
	elapsed_time.emit(Time.get_ticks_usec() - start_time)
