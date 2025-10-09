extends Window
class_name ParameterUpdater

## Runtime bridge between the UI parameter editor and the SimulationController.
## Why: Keeps decoupled communication through signals, allowing UI components to change parameters
## without direct access to the simulation internals.
var simulation_controller: SimulationController

## Runtime simulation configuration resource associated with the window.
## Why: Used to populate all UI controls with current simulation values before display.
var config: SimulationConfig

## Emitted when total agent count is changed from UI.
signal agent_count_changed(agent_count: int)

## Emitted when global agent speed is modified from UI.
signal agent_speed_changed(speed: float)

## Emitted when world bounds are adjusted (e.g., after UI resize).
signal bounds_changed(bounds: Vector2)


## Emitted when infection transmission radius is altered.
signal transmission_radius_changed(radius: float)

## Emitted when infection probability changes.
signal transmission_probability_changed(probability: float)

## Emitted when visibility of the contact grid is toggled.
signal transmission_grid_visibility_changed(grid_visible: bool)


## Emitted when the stage timer of a specific infection state is changed.
signal timer_changed(state: AgentStateManager.AgentState, timer: Vector2)


## Emitted when simulation pause state changes.
signal pause_changed(paused: bool)

## Emitted when time‑speed multiplier (fast/slow motion) updates.
signal speed_multiplier_changed(multiplier: float)

## Emitted when tick duration changes; converted before syncing to controller.
signal tick_changed(step_seconds: float)


## Connects all update signals to matching SimulationController handlers.
## Why: One unified method ensures centralized binding logic,
## avoiding repetitive connections scattered among UI components.
func _connect_signals_to_controller() -> void:
	if not simulation_controller:
		return
	agent_speed_changed.connect(simulation_controller.set_speed)
	bounds_changed.connect(simulation_controller.set_bounds)
	transmission_radius_changed.connect(simulation_controller.set_transmission_radius)
	transmission_probability_changed.connect(simulation_controller.set_transmission_probability)
	transmission_grid_visibility_changed.connect(simulation_controller.set_grid_visibility)
	timer_changed.connect(simulation_controller.set_state_timer)
	pause_changed.connect(simulation_controller.set_pause)
	speed_multiplier_changed.connect(simulation_controller.set_speed_multiplier)
	tick_changed.connect(simulation_controller.set_tick)


## Updates and emits new agent count.
func _on_agent_count_changed(count: int) -> void:
	config.agent_count = count
	agent_count_changed.emit(count)


## Updates and emits agent speed.
func _on_agent_speed_changed(speed: float) -> void:
	config.agent_speed = speed
	agent_speed_changed.emit(speed)


## Emits world boundary modifications.
func _on_bounds_changed(bounds: Vector2) -> void:
	config.bounds = bounds
	bounds_changed.emit(bounds)


## Emits new infection radius setting.
func _on_transmission_radius_changed(radius: float) -> void:
	config.infection_config.transmission_radius = radius
	transmission_radius_changed.emit(radius)


## Emits infection probability change.
func _on_transmission_probability_changed(probability: float) -> void:
	config.infection_config.transmission_probability = probability
	transmission_probability_changed.emit(probability)


## Emits grid visibility toggle.
func _on_transmission_grid_visibility_changed(grid_visible: bool) -> void:
	transmission_grid_visibility_changed.emit(grid_visible)


## Emits timer update for *exposed* stage.
func _on_exposed_timer_changed(timer: Vector2) -> void:
	config.stage_durations[AgentStateManager.AgentState.EXPOSED] = timer
	timer_changed.emit(AgentStateManager.AgentState.EXPOSED, timer)


## Emits timer update for *infectious* stage.
func _on_infectious_timer_changed(timer: Vector2) -> void:
	config.stage_durations[AgentStateManager.AgentState.INFECTIOUS] = timer
	timer_changed.emit(AgentStateManager.AgentState.INFECTIOUS, timer)


## Emits pause toggle.
func _on_pause_changed(paused: bool) -> void:
	pause_changed.emit(paused)


## Emits multiplier for time scaling.
func _on_speed_multiplier_changed(multiplier: float) -> void:
	speed_multiplier_changed.emit(multiplier)


## Converts tick frequency (1 / tick) into step seconds before emitting.
## Why: The controller expects actual timestep duration, not frequency,
## so inversion keeps time progression consistent across UI‑driven changes.
func _on_tick_changed(tick: float) -> void:
	tick_changed.emit(1.0 / tick)
