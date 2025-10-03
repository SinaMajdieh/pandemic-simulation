## Class: SimulationController
## Why: Coordinates agent simulation and rendering, acting as the main loop entry point.
##      Keeps logic modular by delegating physics to AgentManager and rendering to AgentRenderer.
extends Node2D


@export_category("Simulation Properties")
## Total number of agents in the simulation; high count tests scalability.
@export var population: int = 10_000

## Uniform movement speed for all agents; chosen to maintain visual coherence.
@export var agent_speed: float = 50.0


@export_category("Rendering Properties")
## Radius of each agent’s circle mesh; small for high-density visuals.
@export var radius: float = 2.0

## Segments for circle mesh geometry; higher = smoother but heavier.
@export var segments: int = 16

## Default agent display color; can later be replaced with state-specific (SEIR) colors.
@export var agent_color: Color = Color("61AFEF")


## Manages agent position, direction, and boundary logic.
var agent_manager: AgentManager

## Handles efficient rendering of all agents via MultiMesh.
var agent_renderer: AgentRenderer


## Initializes simulation objects.
## Why: Separates simulation state setup from rendering setup; ensures deterministic start state.
func _ready() -> void:
	randomize()  # Seed RNG to guarantee unique initial positions per run.
	var bounds: Vector2 = get_viewport_rect().size  # Prevent agents from moving outside visible area.
	agent_manager = AgentManager.new(population, agent_speed, bounds)

	agent_renderer = AgentRenderer.new(radius, segments, population, agent_color)
	add_child(agent_renderer)


## Main simulation loop; advances simulation state and updates rendering each frame.
## Why: Keeps physics and graphics in sync without storing duplicate position data.
func _process(delta: float) -> void:
	agent_manager.advance(delta)  # Move agents + apply boundary rules.
	agent_renderer.update_from_manager(agent_manager)  # Render updated positions & colors.
