## GPU compute runner specialized for infectious contact spread logic.
## Why: Wraps shader dispatch workflow so infection computation happens in parallel,
## isolating low‑level GPU operations from high‑level simulation logic.
extends ShaderRunner
class_name ContactInfectiousRunner


## Default shader path used if none specified.
## Why: Centralizes shader file location for quick swapping and modular testing.
var DEFAULT_PATH: String = "res://scripts/gpu/shaders/contact_infectious.glsl"

## Compiled GPU shader reference (RID).
var shader: RID

## Compute pipeline used to execute infection dispatch.
var pipeline: RID


## Initializes shader runner and prepares compute pipeline.
## Why: Loads shader file once and constructs pipeline for reuse across multiple frames.
func _init(path: String = DEFAULT_PATH) -> void:
	super()
	shader = _load_shader(path)
	pipeline = rendering_device.compute_pipeline_create(shader)


## Dispatches infection spread computation on GPU using provided buffers.
## Why: Batches all agent position/state data and spatial parameters into uniform/storage sets,
## performs the compute pass, then reads back IDs of newly exposed agents.
func dispatch(
	positions: PackedVector2Array,
	states: PackedInt32Array,
	infectious_cells_flat: PackedInt32Array,
	cell_start: PackedInt32Array,
	cell_count: PackedInt32Array,
	neighbor_offsets: PackedInt32Array,
	exposure_chance: PackedFloat32Array,
	meta_buffer: RID
) -> PackedInt32Array:
	# ----- Buffer Creation -----
	var positions_buffer: RID = create_storage_buffer(positions)
	var states_buffer: RID = create_storage_buffer(states)
	var infectious_cells_buffer: RID = create_storage_buffer(infectious_cells_flat)
	var cell_start_buffer: RID = create_storage_buffer(cell_start)
	var cell_count_buffer: RID = create_storage_buffer(cell_count)
	var neighbor_offsets_buffer: RID = create_storage_buffer(neighbor_offsets)
	var exposure_chance_buffer: RID = create_storage_buffer(exposure_chance)


	# Output buffer initialized to ‑1 (uninfected placeholder).
	var newly_exposed: PackedInt32Array = PackedInt32Array()
	newly_exposed.resize(states.size())
	newly_exposed.fill(-1)
	var newly_exposed_buffer: RID = create_storage_buffer(newly_exposed)

	# ----- Uniform Set Binding -----
	var uniform_set: RID = create_uniform_set([
		create_uniform(meta_buffer, 0, RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER),
		create_uniform(positions_buffer, 1, RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER),
		create_uniform(states_buffer, 2, RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER),
		create_uniform(infectious_cells_buffer, 3, RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER),
		create_uniform(cell_start_buffer, 4, RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER),
		create_uniform(cell_count_buffer, 5, RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER),
		create_uniform(neighbor_offsets_buffer, 6, RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER),
		create_uniform(exposure_chance_buffer, 7, RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER),
		create_uniform(newly_exposed_buffer, 8, RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER),
	], shader)

	# ----- GPU Dispatch -----
	_dispatch_compute(
		pipeline,
		uniform_set,
		states.size()
	)

	# ----- Buffer Cleanup & Return -----
	rendering_device.free_rid(positions_buffer)
	rendering_device.free_rid(states_buffer)
	rendering_device.free_rid(infectious_cells_buffer)
	rendering_device.free_rid(cell_start_buffer)
	rendering_device.free_rid(cell_count_buffer)
	rendering_device.free_rid(neighbor_offsets_buffer)

	newly_exposed = get_buffer_data(newly_exposed_buffer).to_int32_array()
	rendering_device.free_rid(newly_exposed_buffer)
	return newly_exposed


## Packs scalar parameters into a uniform meta buffer for GPU access.
## Why: Bundles constants such as grid size, transmission probability, and radius
## into a compact 32‑byte structure accessible to compute shader kernels.
func create_meta_buffer(
	radius_sq: float,
	transmission_probability: float,
	grid_width: int,
	grid_height: int,
	max_per_cell: int,
	cell_size: float
) -> RID:
	var meta_data: PackedByteArray = PackedByteArray()
	meta_data.resize(32)
	meta_data.encode_float(0, radius_sq)
	meta_data.encode_float(4, transmission_probability)
	meta_data.encode_u32(8, grid_width)
	meta_data.encode_u32(12, grid_height)
	meta_data.encode_u32(16, max_per_cell)
	meta_data.encode_float(20, cell_size)
	return rendering_device.uniform_buffer_create(meta_data.size(), meta_data)
