## Main simulation coordinator.
## Why: Separates simulation logic (AgentManager) from rendering (AgentRenderer) to
##      allow independent performance tuning and future GPU integration without breaking visual code.
extends Node2D

@export_category("Simulation Properties")
# Simualtion configuration
@export var simulation_config: SimulationConfig = SimulationConfig.new()
# Simulation bound scale relative to viewport size
@export_range(0.0, 1.0) var bounds_scale: float = 1.0

## Why: Dedicated bounds node simplifies layout control and enforces movement constraints visually and logically.
@export var simulation_bounds: Node2D
@export var cell_grid: GraphGrid


@export_category("Rendering Properties")
@export var radius: float = 2.0 
## Why: Small radius prevents visual overlap at high density while still making agents distinguishable.

@export var segments: int = 16
## Why: Balanced segment count keeps circles moderately smooth without overtaxing mesh generation or GPU batching.


## Simulation state/movement handler.
var agent_manager: AgentManager
## MultiMesh-based renderer for agents.
var agent_renderer: AgentRenderer


## Initializes simulation and rendering systems.
## Why: Creates isolated subsystems so each can be optimized or replaced independently
##      (e.g., GPU compute for logic, shader-based rendering for visuals).
func _ready() -> void:
	randomize()  # Ensures agents start with varied positions/directions for realism.
	var screen_bounds: Vector2 = get_viewport_rect().size
	simulation_config.bounds = screen_bounds * bounds_scale
	simulation_bounds.size = simulation_config.bounds
	cell_grid.custom_minimum_size = simulation_config.bounds
	cell_grid.set_spacing(simulation_config.infection_config.transmission_radius, simulation_config.infection_config.transmission_radius) 
	simulation_bounds.center_relative_to(screen_bounds)
	
	agent_manager = AgentManager.new(simulation_config)
	agent_renderer = AgentRenderer.new(radius, segments, simulation_config.agent_count)
	simulation_bounds.add_child(agent_renderer)
	
	## Why: Kickstarts outbreak dynamics without manual infection events.
	agent_manager.state_manager.seed_stage((1 / float(simulation_config.agent_count)), AgentStateManager.AgentState.EXPOSED) # make only 1 agent exposed


## Runs one simulation tick and refreshes visuals.
## Why: Syncs physics calculations and rendering updates to prevent frame drift or visual desynchronization.
func _process(delta: float) -> void:
	agent_manager.advance(delta)                      
	agent_renderer.update_from_manager(agent_manager)
