## Renders large numbers of agents efficiently via MultiMesh instancing.
## Why: MultiMesh batches identical geometry with per-instance transforms/colors,
##      eliminating per-agent Node overhead and drastically reducing draw calls.
class_name AgentRenderer
extends Node2D

## Maps SEIR states → display colors.
## Why: Centralizes visual logic so state → color mapping is consistent and easy to modify.
static var state_color_map: Dictionary[AgentStateManager.AgentState, Color] = {
	AgentStateManager.AgentState.SUSCEPTIBLE : Color("61AFEF"),   # Healthy baseline
	AgentStateManager.AgentState.EXPOSED     : Color("E5C07B"),   # Incubating
	AgentStateManager.AgentState.INFECTIOUS  : Color("E06C75"),   # Infectious / alert
	AgentStateManager.AgentState.RECOVERED   : Color("5C6370")    # Immune / inactive
}

## Default color used unless overridden by state_color_map.
const agent_default_color: Color = Color("61AFEF")

## Batched instance container for agent geometry and per-agent attributes.
var multimesh: MultiMesh
## Scene node that draws the MultiMesh.
var multimesh_instance: MultiMeshInstance2D
## Circle visual size.
var radius: float
## Circle subdivision count for mesh smoothness.
var segments: int

var _transforms: PackedVector2Array
var _colors: PackedColorArray

var movement: AgentMovementManager
var state: AgentStateManager

## Builds MultiMesh resources and attaches to scene.
## Why: Reserves instance buffers on init to prevent costly runtime resizing.
func _init(manager: AgentManager, radius_: float, segments_: int, agent_count_: int) -> void:
	movement = manager.movement_manager
	state = manager.state_manager

	radius = radius_
	segments = segments_

	multimesh = MultiMesh.new()
	multimesh.mesh = _make_circle_mesh(radius, segments)     # Procedural geometry avoids asset IO.
	multimesh.use_colors = true                              # Allows per-instance color updates.
	multimesh.instance_count = agent_count_                  # Preallocation for all agents.

	multimesh_instance = MultiMeshInstance2D.new()
	multimesh_instance.multimesh = multimesh
	add_child(multimesh_instance)


## Generates triangle fan mesh for a filled circle.
## Why: Avoids dependency on external sprites or textures, keeping renderer self-contained.
func _make_circle_mesh(radius_: float, segments_: int) -> ArrayMesh:
	var mesh: ArrayMesh= ArrayMesh.new()
	var vertices: PackedVector2Array = PackedVector2Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	var indices: PackedInt32Array = PackedInt32Array()

	vertices.append(Vector2.ZERO)                    # Center point for triangle fan
	uvs.append(Vector2(0.5, 0.5))                     # UV at center

	for i: int in range(segments_):
		var angle: float = TAU * float(i) / float(segments_)
		var pos: Vector2 = Vector2(cos(angle), sin(angle)) * radius_
		vertices.append(pos)

		# Map to [0,1] UV space for any potential texture usage.
		var uv: Vector2 = Vector2((cos(angle) * 0.5) + 0.5, (-sin(angle) * 0.5) + 0.5)
		uvs.append(uv)

	# Fan triangles
	for i: int in range(1, segments_):
		indices.append(0); indices.append(i); indices.append(i + 1)
	indices.append(0); indices.append(segments_); indices.append(1)

	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices

	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## Updates transforms and colors from simulation data.
## Why: Keeps rendering and simulation separate, enabling independent optimization.
func update_from_manager(alpha: float, step_seconds: float) -> void:
	if _transforms.size() != movement.agent_count * 3:
		_transforms = PackedVector2Array()
		_transforms.resize(movement.agent_count * 3)
		_colors = PackedColorArray()
		_colors.resize(state.agent_count)
	for i: int in range(movement.agent_count):
		var offset: Vector2 = movement.directions[i] * movement.agent_speed * alpha * step_seconds
		var agent_position: Vector2 = movement.positions[i] + offset
		var base: int = i * 3
		_transforms[base] = Vector2(1.0, 0.0)		# x_axis = (xx, xy)
		_transforms[base + 1] = Vector2(0.0, 1.0)	# y_axis = (yx, yy)
		_transforms[base + 2] = agent_position		# origin = (ox, oy)

		_colors[i] = state_color_map[state.states[i]]
	
	multimesh.transform_2d_array = _transforms
	multimesh.color_array = _colors
