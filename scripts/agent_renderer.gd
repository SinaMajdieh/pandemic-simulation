## Class: AgentRenderer
## Why: Handles efficient rendering of many agents using MultiMesh instancing,
##      avoiding per-agent Node overhead and reducing draw calls.

class_name AgentRenderer
extends Node2D

## Default visual color for agents; chosen as a calm blue for distinguishable visibility.
const agent_default_color: Color = Color("61AFEF")

## MultiMesh resource used for batching agent geometry and transforms.
var multimesh: MultiMesh

## Node wrapper that draws the MultiMesh in the scene.
var multimesh_instance: MultiMeshInstance2D

## Radius of each agent’s circle mesh.
var radius: float

## Number of segments composing each agent circle; more segments → smoother shape.
var segments: int

## Assigned per-agent color; can be overridden for state-driven visuals.
var agent_color: Color


## Initializes a circle-based MultiMesh for agent rendering.
## Why: Uses instancing to scale to thousands of agents with minimal GPU overhead.
func _init(
    radius_: float,
    segments_: int, 
    agent_count_: int, 
    agent_color_: Color = agent_default_color
) -> void:
    radius = radius_
    segments = segments_
    agent_color = agent_color_

    multimesh = MultiMesh.new()
    multimesh.mesh = _make_circle_mesh(radius, segments)  # Procedural circle geometry avoids PNG/material handling.
    multimesh.use_colors = true  # Enables per-instance color without separate meshes.
    multimesh.instance_count = agent_count_  # Reserve buffers up front to avoid resizing at runtime.

    multimesh_instance = MultiMeshInstance2D.new()
    multimesh_instance.multimesh = multimesh
    add_child(multimesh_instance)


## Creates a filled 2D circle mesh using triangles.
## Why: Generates geometry directly in code to avoid asset dependencies.
##      Optimized for use with MultiMeshInstance2D in Godot 4.x.
func _make_circle_mesh(radius_: float, segments_: int) -> ArrayMesh:
    var mesh: ArrayMesh = ArrayMesh.new()
    var vertices: PackedVector2Array = PackedVector2Array()
    var uvs: PackedVector2Array = PackedVector2Array()
    var indices: PackedInt32Array = PackedInt32Array()

    # Start at center to form a fan-like triangle structure.
    vertices.append(Vector2.ZERO)
    uvs.append(Vector2(0.5, 0.5))  # Centered UV coordinates.

    for i: int in range(segments_):
        var angle: float = TAU * float(i) / float(segments_)
        var pos: Vector2 = Vector2(cos(angle), sin(angle)) * radius_
        vertices.append(pos)

        # Map circle points into [0,1] UV space for potential texturing.
        var uv: Vector2 = Vector2((cos(angle) * 0.5) + 0.5, (-sin(angle) * 0.5) + 0.5)
        uvs.append(uv)

    # Link points into triangles to create filled circle mesh.
    for i: int in range(1, segments_):
        indices.append(0)
        indices.append(i)
        indices.append(i + 1)

    # Closing triangle to connect last segment back to first.
    indices.append(0)
    indices.append(segments_)
    indices.append(1)

    var arrays: Array = []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX] = vertices
    arrays[Mesh.ARRAY_TEX_UV] = uvs
    arrays[Mesh.ARRAY_INDEX] = indices

    mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    return mesh


## Updates the transforms and colors of all agents based on the manager state.
## Why: Decouples rendering from simulation logic for cleaner architecture.
func update_from_manager(manager: AgentManager) -> void:
    var agent_transform: Transform2D = Transform2D.IDENTITY
    for i: int in range(manager.agent_count):
        agent_transform.origin = manager.positions[i]
        multimesh.set_instance_transform_2d(i, agent_transform)
        # Placeholder color applied here; enables later state-based rendering without changing geometry.
        multimesh.set_instance_color(i, agent_color)
