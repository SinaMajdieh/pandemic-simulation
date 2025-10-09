extends Node2D
class_name SimulationController

## Lifecycle signals used for orchestration and UI synchronization.
signal started()
signal ended()


## Central manager coordinating all simulation subsystems.
## Why: Separates logic (AgentManager) from rendering (AgentRenderer) to enable
## independent optimization or GPU migration later.
@export_category("Simulation Properties")

## Global simulation configuration — passed so runtime swapping of parameters is possible.
@export var simulation_config: SimulationConfig = SimulationConfig.new()

## Optional UI parent controlling layout and sizing; defines simulation world bounds.
@export var ui_container: Control

## Spatial grid assisting ContactTracer by partitioning space for local proximity checks.
## Why: Limits infection lookup to nearby cells, improving O(n) performance.
@export var cell_grid: GraphGrid

## View transformation controller; auto‑synced with simulation bounds for user navigation.
@export var zoom_pan: ZoomPan


@export_category("Rendering Properties")

## Visual radius of agents in world units.
## Why: Balanced to maintain visibility in dense populations without overlap.
@export var radius: float = 2.0

## Polygon smoothness for circular agent meshes — higher values improve presentation but cost CPU.
@export var segments: int = 16


## Logic handler executing movement, infection transition, and state updates.
var agent_manager: AgentManager

## Efficient renderer using MultiMesh for visualizing all agents each frame.
var agent_renderer: AgentRenderer

## Fixed‑step timer maintaining tick consistency regardless of frame rate.
@export var timer: FixedStepTimer

## Active configuration window used for runtime parameter tuning.
var config_window: SimulationConfigWindow

## Simulation running switch; get method ensures external consistency.
var running: bool = false:
	get = is_running


## Initialization entry point.
## Why: Builds subsystems after UI sizing stabilizes, connects timer, and prepares the config window.
func _ready() -> void:
	randomize()  # Ensures unique initial positions per run.
	await get_tree().process_frame  # Wait to obtain valid viewport/container dimensions.
	simulation_config.bounds = _get_bounds()
	timer.tick.connect(_on_simulation_tick)

	config_window = SimulationConfigWindow.new_window(self, simulation_config)
	config_window.hide()
	get_tree().root.add_child(config_window)
	start()


## Launches simulation systems and applications of initial infection state.
## Why: Synchronizes all subsystems with the configuration bounds and infection parameters.
func start(cfg: SimulationConfig = simulation_config) -> void:
	zoom_pan.set_sizing(cfg.bounds, cfg.bounds)
	cell_grid.custom_minimum_size = cfg.bounds
	cell_grid.set_spacing(cfg.infection_config.transmission_radius, cfg.infection_config.transmission_radius)

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


## Gracefully stops the simulation and frees rendering resources.
func end() -> void:
	agent_renderer.hide()
	running = false
	ended.emit()


## Toggles simulation pause state without altering tick rate.
## Why: Keeps logic suspended while preserving time configuration.
func set_pause(paused: bool) -> void:
	if timer.paused == paused:
		return
	timer.set_paused(paused)


## Obtains current world bounds.
## Why: Uses UI container when available, falling back to viewport for autonomous mode.
func _get_bounds() -> Vector2:
	if not ui_container:
		return get_viewport_rect().size
	return ui_container.size


## Frame‑based update bridging logic and renderer using fixed step interpolation.
## Why: Maintains temporal stability and aligns visuals to logic progression.
func _process(delta: float) -> void:
	if not is_running():
		return
	timer.update(delta)
	if agent_renderer:
		agent_renderer.update_from_manager(timer.get_alpha(), timer.step_seconds)


## Executes logic tick per fixed update.
## Why: Keeps changes deterministic regardless of frame fluctuation.
func _on_simulation_tick(step: float) -> void:
	if agent_manager:
		agent_manager.advance(step)
	# agent_renderer.update_from_manager()  # Optional deferred sync


## Adjusts overall movement speed multiplier for agents.
func set_speed(speed: float) -> void:
	agent_manager.set_speed(speed)


## Updates spatial boundaries in all relevant systems.
func set_bounds(bounds: Vector2) -> void:
	cell_grid.custom_minimum_size = bounds
	zoom_pan.bounds = bounds
	agent_manager.set_bounds(bounds)


## Scales tick progression rate for time dilation effects.
func set_speed_multiplier(multiplier: float) -> void:
	timer.speed_multiplier = multiplier


## Changes duration between logic ticks.
func set_tick(step_seconds: float) -> void:
	timer.step_seconds = step_seconds


## Updates infection spread radius across both logical and visual subsystems.
func set_transmission_radius(transmission_radius: float) -> void:
	agent_manager.set_transmission_radius(transmission_radius)
	cell_grid.set_spacing(transmission_radius, transmission_radius)


## Sets probability of infection globally.
func set_transmission_probability(probability: float) -> void:
	agent_manager.set_transmission_probability(probability)


## Updates duration range per SEIR stage in the agent state manager.
func set_state_timer(state: AgentStateManager.AgentState, state_timer: Vector2) -> void:
	agent_manager.set_state_timer(state, state_timer)


## Opens configuration window for runtime parameter editing.
func _open_config_window() -> void:
	if not config_window:
		return
	config_window.show()


## Returns whether simulation is currently active.
func is_running() -> bool:
	return running


## Displays or hides infection grid overlay.
func set_grid_visibility(grid_visible: bool) -> void:
	cell_grid.visible = grid_visible
