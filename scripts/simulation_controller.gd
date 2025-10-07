extends Node2D
## Main coordinator for the agent-based simulation.
## Purpose: Orchestrates logic (AgentManager) and visuals (AgentRenderer) as independent subsystems
## so each can be tuned, replaced, or moved to GPU without affecting the other.

@export_category("Simulation Properties")
@export var simulation_config: SimulationConfig = SimulationConfig.new()
## Holds all global parameters — injecting this allows simulation settings to be swapped at runtime.

@export var ui_container: Control
## Optional UI overlay container; used to measure its size for simulation world bounds.

@export var cell_grid: GraphGrid
## Grid aiding spatial partitioning for infection calculations — separation keeps the ContactTracer efficient.

@export var zoom_pan: ZoomPan
## Controls user view on simulation bounds; injected here so it can be automatically synced with config.

@export_category("Rendering Properties")
@export var radius: float = 2.0
## Chosen to avoid overlap in dense clusters while keeping agents visually distinct.

@export var segments: int = 16
## Segment count balances circular smoothness against mesh generation overhead.

var agent_manager: AgentManager
## Handles agent physics, movement, infection state transitions — the “simulation brain”.

var agent_renderer: AgentRenderer
## Draws agents using MultiMesh for efficient mass rendering.

func _ready() -> void:
	## randomized() ensures initial positions/directions differ — prevents uniform/unnatural spread at start.
	randomize()

	## process_frame wait: ensures UI and viewport sizes are measured before bounds calculation.
	await get_tree().process_frame

	## Calculate playable bounds — depends on either viewport or containing UI.
	simulation_config.bounds = _get_bounds()
	
	## Sync bounds across panning and spatial grid so view and calculations match.
	zoom_pan.bounds = simulation_config.bounds
	cell_grid.custom_minimum_size = simulation_config.bounds
	
	## Set cell grid spacing to match infection transmission radius
	## — ensures partitioning cells align perfectly with contact detection range.
	cell_grid.set_spacing(
		simulation_config.infection_config.transmission_radius,
		simulation_config.infection_config.transmission_radius
	)

	## Build core handlers — injecting config so both subsystems share identical parameters.
	agent_manager = AgentManager.new(simulation_config)
	agent_renderer = AgentRenderer.new(radius, segments, simulation_config.agent_count)
	add_child(agent_renderer)

	## Auto-seed one exposed agent — avoids a “dead” simulation that needs manual triggering.
	agent_manager.state_manager.seed_stage(
		1.0 / float(simulation_config.agent_count),
		AgentStateManager.AgentState.EXPOSED
	)

func _get_bounds() -> Vector2:
	## Returns simulation size based on actual UI container
	## — fallback to viewport size for full-window simulations.
	if not ui_container:
		return get_viewport_rect().size
	return ui_container.size

func _process(delta: float) -> void:
	## Advance simulation logic before visual update
	## — preserves temporal sync so visuals never “lag” behind simulation state.
	agent_manager.advance(delta)
	agent_renderer.update_from_manager(agent_manager)
