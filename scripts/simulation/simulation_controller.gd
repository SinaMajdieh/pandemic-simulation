## Primary orchestrator node managing all simulation systems.
## Why: Central entrypoint that binds agent logic, rendering, infection control,
## timing, and configuration into one synchronized runtime environment.
extends Node2D
class_name SimulationController


## Signals emitted at start and end of simulation runtime.
## Why: Used for UI synchronization and event‑based control across external widgets.
signal started()
signal ended()


@export_category("Simulation Properties")

## Central configuration resource controlling simulation parameters.
## Why: Enables runtime swapping of parameter sets without rebuilding internal structures.
@export var simulation_config: SimulationConfig = SimulationConfig.new()

## Optional UI container controlling viewport sizing and world limits.
## Why: Provides dynamic bounds derived from a Control node, allowing adaptive scaling.
@export var ui_container: Control

## Spatial grid reference assisting the ContactTracer system.
## Why: Enables localized proximity search within cells to preserve O(n) efficiency.
@export var cell_grid: GraphGrid

## View navigation controller managing zoom and pan operations.
## Why: Keeps viewport alignment consistent with simulation world coordinates.
@export var zoom_pan: ZoomPan


@export_category("Rendering Properties")

## Visual radius of each agent.
## Why: Tuned for readability; balances density versus clarity of overlapping sprites.
@export var radius: float = 2.0

## Polygon smoothness (segment count) for drawn agents.
## Why: Increasing improves circular fidelity; traded off against CPU overhead.
@export var segments: int = 16


## Core manager in charge of updating agent logic and infection state transitions.
var agent_manager: AgentManager

## Renderer using MultiMesh for efficient per‑frame agent drawing.
var agent_renderer: AgentRenderer

## Fixed‑step timer ensuring deterministic tick progression.
## Why: Keeps logic independent of rendering frame rate fluctuations.
@export var timer: FixedStepTimer

## Runtime configuration window shown for parameter adjustment.
var config_window: SimulationConfigWindow

## Runtime information window shown for simulation parameters.
var info_window: SimulationInfoWindow

## Simulation runtime state flag.
## Why: Maintains external consistency and controls the main update loop triggers.
var running: bool = false:
	get = is_running


## Initializes simulation context and sets up window and connections.
## Why: Waits one frame for valid viewport sizing, constructs subsystems,
## and connects tick timing before automatic launch.
func _ready() -> void:
	randomize()  # Guarantees unique initial conditions per run.
	await get_tree().process_frame  # Stabilizes layout before measurement.
	timer.tick.connect(_on_simulation_tick)

	config_window = SimulationConfigWindow.new_window(self, simulation_config)
	config_window.hide()
	get_tree().root.add_child(config_window)
	start()


## Starts simulation execution and applies configuration values.
## Why: Rebuilds managers with provided parameters to synchronize bounds,
## infection radius, and agent population.
func start(cfg: SimulationConfig = simulation_config) -> void:
	simulation_config = cfg
	zoom_pan.set_sizing(cfg.bounds, _get_bounds())
	cell_grid.custom_minimum_size = cfg.bounds
	cell_grid.set_spacing(
		cfg.infection_config.transmission_radius,
		cfg.infection_config.transmission_radius
	)

	agent_manager = AgentManager.new(cfg)

	if agent_renderer:
		remove_child(agent_renderer)
		agent_renderer.queue_free()

	agent_renderer = AgentRenderer.new(agent_manager, radius, segments, cfg.agent_count)
	add_child(agent_renderer)

	agent_manager.state_manager.seed_stage(
		cfg.initial_states[AgentStateManager.AgentState.EXPOSED] / float(cfg.agent_count),
		AgentStateManager.AgentState.EXPOSED
	)
	agent_manager.state_manager.seed_stage(
		cfg.initial_states[AgentStateManager.AgentState.INFECTIOUS] / float(cfg.agent_count),
		AgentStateManager.AgentState.INFECTIOUS
	)

	running = true
	started.emit()


## Gracefully stops active simulation and hides renderer.
## Why: Maintains system integrity and avoids freeing nodes mid‑loop.
func end() -> void:
	agent_renderer.hide()
	running = false
	ended.emit()


## Pauses or resumes ticking while retaining timing configuration.
## Why: Provides user control to inspect intermediate frames without losing synchronization.
func set_pause(paused: bool) -> void:
	if timer.paused == paused:
		return
	timer.set_paused(paused)


## Returns current spatial world bounds.
## Why: Uses UI container size if present, otherwise defaults to viewport size.
func _get_bounds() -> Vector2:
	if not ui_container:
		return get_viewport_rect().size
	return ui_container.size


## Per‑frame update linking logic tick interpolation to rendering state.
## Why: Keeps smooth temporal blending between discrete simulation steps.
func _process(delta: float) -> void:
	if not is_running():
		return
	timer.update(delta)
	if agent_renderer:
		agent_renderer.update_from_manager(timer.get_alpha(), timer.step_seconds)


## Executes one logic tick triggered by FixedStepTimer.
## Why: Updates state deterministically relative to elapsed simulation time.
func _on_simulation_tick(step: float) -> void:
	if agent_manager:
		agent_manager.advance(step)


## Adjusts baseline movement speed for all agents.
## Why: Used by sliders or UI widgets to change pacing dynamically.
func set_speed(speed: float) -> void:
	agent_manager.set_speed(speed)


## Updates simulation bounds for all dependent systems.
## Why: Propagates to grid, zoom controls, and movement constraints.
func set_bounds(bounds: Vector2) -> void:
	cell_grid.custom_minimum_size = bounds
	zoom_pan.bounds = bounds
	agent_manager.set_bounds(bounds)


## Modifies fixed‑step tick rate multiplier to simulate time dilation.
## Why: Provides smooth slow‑motion or acceleration effects.
func set_speed_multiplier(multiplier: float) -> void:
	timer.speed_multiplier = multiplier


## Sets logical timestep duration directly.
## Why: Adjusts frequency of simulation logic ticks while keeping renderer consistent.
func set_tick(step_seconds: float) -> void:
	timer.step_seconds = step_seconds


## Updates infection radius across logic and grid systems.
## Why: Keeps spatial proximity computations consistent after parameter changes.
func set_transmission_radius(transmission_radius: float) -> void:
	agent_manager.set_transmission_radius(transmission_radius)
	cell_grid.set_spacing(transmission_radius, transmission_radius)


## Adjusts infection transmission probability globally.
## Why: Reapplies contagiousness factor to current infection algorithm.
func set_transmission_probability(probability: float) -> void:
	agent_manager.set_transmission_probability(probability)


## Updates incubation or contagious stage timers in AgentStateManager.
## Why: Allows per‑state, real‑time tuning of duration ranges.
func set_state_timer(state: AgentStateManager.AgentState, state_timer: Vector2) -> void:
	agent_manager.set_state_timer(state, state_timer)


## Opens configuration window for in‑game parameter editing.
## Why: Safely checks existence before revealing UI dialog.
func _open_config_window() -> void:
	if not config_window:
		return
	config_window.show()
	config_window.grab_focus()

## Opens or focuses the simulation information window.
## Why: Provides a centralized read‑only overview of the current
func _open_info_window() -> void:
	if info_window:
		info_window.grab_focus()
		return

	info_window = SimulationInfoWindow.new_info_window(simulation_config.get_description())
	add_child(info_window)



## Reports whether simulation is currently active.
## Why: Ensures external query consistency for UI and scheduling widgets.
func is_running() -> bool:
	return running


## Shows or hides infection grid overlay visualization.
## Why: Toggles between performance mode and diagnostic inspection mode.
func set_grid_visibility(grid_visible: bool) -> void:
	cell_grid.visible = grid_visible
