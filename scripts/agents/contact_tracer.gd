## Tracks and processes agent proximity for infection spread.
## Why: Uses spatial partitioning (uniform grid) to reduce costly O(n²) distance checks
##      into localized cell-based neighbor checks.
class_name ContactTracer

## Infection radius in game units.
var transmition_radius: float
## Squared radius for faster distance checks without sqrt.
var transmition_radius_sq: float
## Probability of infection upon valid contact; 1 means certain transmission.
var transmition_probability: float
## Upper bound for infectious agents stored per cell to prevent overflow.
var max_per_cell: int

## Reference to agent state manager — needed to change SEIR states.
var state: AgentStateManager

## Total agents; used for preallocating fixed-size buffers.
var agent_count: int
## Side length of each grid cell in world units.
var cell_size: float
## Grid dimensions in cells.
var grid_width: int
var grid_height: int
## Flat array storing infectious agent IDs in contiguous cell blocks.
var infectious_cells_flat: PackedInt32Array
## Starting index of each cell’s block in the flat array.
var cell_start: PackedInt32Array
## Count of infectious agents in each cell.
var cell_count: PackedInt32Array
## Temp storage of susceptible agent IDs for targeted contact checks.
var susceptible_list: PackedInt32Array
## Precomputed offsets for visiting all 8 neighbors + self in grid.
var neighbor_offsets: PackedInt32Array
## World bounds for movement.
var bounds: Vector2
## Temporary buffer used to store all infectious agent IDs found in the 3x3 neighbor cells
## Pre‑allocated once to avoid per‑frame allocations or resizes
var neighbor_infectious_ids: PackedInt32Array


## Computes grid size and initializes storage arrays.
## Why: Preallocates contiguous memory so each cell has a reserved slot range,
##      eliminating dynamic inserts and preventing fragmentation.
func _calculate_grid() -> void:
    grid_width = max(1, int(bounds.x / cell_size) + 1)
    grid_height = max(1, int(bounds.y / cell_size) + 1)
    var cell_total: int = grid_width * grid_height

    cell_start = PackedInt32Array(); cell_start.resize(cell_total)
    infectious_cells_flat = PackedInt32Array(); infectious_cells_flat.resize(cell_total * max_per_cell)
    cell_count = PackedInt32Array(); cell_count.resize(cell_total)

    # Assign each cell a fixed contiguous slot in flat array
    for i: int in range(cell_total):
        cell_start[i] = i * max_per_cell

    # Precompute neighbor cell offsets once to reduce per-frame overhead
    var arr: Array[int] = []
    for y: int in range(-1, 2):
        for x: int in range(-1, 2):
            arr.append(y * grid_width + x)
    neighbor_offsets = PackedInt32Array(arr)


## Constructor.
## Why: Sets up spatial grid and buffers before simulation so
##      infection checks are ready for frame processing.
func _init(
    agent_count_: int, 
    bounds_: Vector2,
    state_: AgentStateManager,
    cfg: InfectionConfig
) -> void:
    agent_count = agent_count_
    state = state_
    bounds = bounds_
    transmition_radius = cfg.transmission_radius
    transmition_radius_sq = cfg.transmission_radius_sq
    transmition_probability = cfg.transmission_probability
    max_per_cell = cfg.max_per_cell
    cell_size = transmition_radius
    neighbor_infectious_ids.resize(9 * max_per_cell)
    _calculate_grid()

    susceptible_list = PackedInt32Array(); susceptible_list.resize(agent_count)


## Runs bucket fill for infectious agents, then checks susceptible agents against nearby infectious ones.
## Why: Converts a naive all-pairs check into: bucket infectious → loop over susceptible → check 3×3 cell neighbors.
func infect_contacts(positions: PackedVector2Array, states: PackedInt32Array) -> void:
    cell_count.fill(0)  # Reset infectious count per cell
    var sus_count: int = 0

    # First pass: bucket infectious agents and store susceptible ones
    for agent_id: int in range(agent_count):
        var pos: Vector2 = positions[agent_id]
        var cell_x: int = int(pos.x / cell_size)
        var cell_y: int = int(pos.y / cell_size)
        if cell_x < 0 or cell_x >= grid_width or cell_y < 0 or cell_y >= grid_height:
            continue

        var cell_index: int = cell_y * grid_width + cell_x
        if states[agent_id] == AgentStateManager.AgentState.INFECTIOUS:
            var insert_pos: int = cell_start[cell_index] + cell_count[cell_index]
            # Prevents write past the reserved slot range
            if insert_pos < cell_start[cell_index] + max_per_cell:
                infectious_cells_flat[insert_pos] = agent_id
                cell_count[cell_index] += 1
        elif states[agent_id] == AgentStateManager.AgentState.SUSCEPTIBLE:
            susceptible_list[sus_count] = agent_id
            sus_count += 1

    # Second pass: check each susceptible against infectious in neighboring cells
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
        
        # Adjust per-contact probability so total per-frame infection chance stays stable
        var contact_probability: float = 1.0 - pow(
            1.0 - transmition_probability,
            1.0 / float(infectious_contact_count)
        )

        for contact_index: int in range(infectious_contact_count):
            var infectious_id: int = neighbor_infectious_ids[contact_index]
            var dx: float = sus_pos.x - positions[infectious_id].x
            var dy: float = sus_pos.y - positions[infectious_id].y
            if dx * dx + dy * dy <= transmition_radius_sq and randf() < contact_probability:
                state.set_state(sus_id, AgentStateManager.AgentState.EXPOSED)
                break
