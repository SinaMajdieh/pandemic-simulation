## Minimal GPU compute helper providing shader and buffer utilities.
## Why: Abstracts raw RenderingDevice operations to prevent repetitive boilerplate
## when composing multiple GPU compute modules in simulation.
class_name ShaderRunner


## Local RenderingDevice used for creating shaders, pipelines, and buffers.
## Why: Runs as a "sandbox" GPU context separate from the main viewport (safer, faster to test).
var rendering_device: RenderingDevice


## Initializes a standalone RenderingDevice for compute usage.
## Why: Enables running GPU commands without requiring a visible rendering surface.
func _init() -> void:
	rendering_device = RenderingServer.create_local_rendering_device()


## Loads and compiles a shader from SPIR‑V file.
## Why: Converts Godot’s RDShaderFile type to SPIR‑V bytes, producing a shader RID
## ready for GPU pipeline attachment.
func _load_shader(path: String) -> RID:
	var shader_file: RDShaderFile = load(path) as RDShaderFile
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	var shader: RID = rendering_device.shader_create_from_spirv(shader_spirv)
	return shader


## Creates a storage buffer from any packed array type.
## Why: Used for GPU read/write data (positions, states, IDs), converting arrays into byte streams.
func create_storage_buffer(data: Variant) -> RID:
	var data_bytes: PackedByteArray = data.to_byte_array()
	return rendering_device.storage_buffer_create(data_bytes.size(), data_bytes)


## Creates a uniform buffer for read‑only constants (e.g., meta parameters).
## Why: Uniform buffers provide fast GPU access for immutable values shared across threads.
func create_uniform_buffer(data: Variant) -> RID:
	var data_bytes: PackedByteArray = data.to_byte_array()
	return rendering_device.uniform_buffer_create(data_bytes.size(), data_bytes)


## Creates an empty storage buffer pre‑initialized with zeros.
## Why: Used to allocate output arrays for GPU kernels (like infection results).
func create_empty_storage_buffer(size_in_floats: int) -> RID:
	var data: PackedFloat32Array = PackedFloat32Array()
	data.resize(size_in_floats)
	data.fill(0.0)
	return create_storage_buffer(data)


## Retrieves buffer contents after GPU execution.
## Why: Allows post‑dispatch readback—used to extract computed data like new infections.
func get_buffer_data(buffer: RID) -> PackedByteArray:
	return rendering_device.buffer_get_data(buffer)


## Builds a uniform wrapper referencing an existing GPU buffer.
## Why: Simplifies binding process for uniform sets (reducing manual boilerplate per compute shader).
func create_uniform(buffer: RID, binding: int, type: RenderingDevice.UniformType) -> RDUniform:
	var uniform: RDUniform = RDUniform.new()
	uniform.uniform_type = type
	uniform.binding = binding
	uniform.add_id(buffer)
	return uniform


## Constructs a full uniform set linking all prepared buffers for compute usage.
## Why: Uniform sets define the data layout for shader execution, binding resources by index.
func create_uniform_set(uniforms: Array[RDUniform], shader: RID) -> RID:
	return rendering_device.uniform_set_create(uniforms, shader, 0)


## Dispatches a compute workload on the GPU.
## Why: Executes shader threads in fixed‑size groups, syncing at the end for deterministic completion.
func _dispatch_compute(
	pipeline: RID,
	uniform_set: RID,
	total_threads: int,
	threads_per_group_x: int = 64
) -> void:
	var compute_list: int = rendering_device.compute_list_begin()
	rendering_device.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rendering_device.compute_list_bind_uniform_set(compute_list, uniform_set, 0)

	var workgroups: int = int(ceil(total_threads / float(threads_per_group_x)))
	rendering_device.compute_list_dispatch(compute_list, workgroups, 1, 1)
	rendering_device.compute_list_end()
	rendering_device.submit()
	rendering_device.sync()
