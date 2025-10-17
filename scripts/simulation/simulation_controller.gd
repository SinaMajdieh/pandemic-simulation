## Primary orchestrator node managing all simulation systems.
## Why: Central entrypoint that binds agent logic, rendering, infection control,
## timing, and configuration into one synchronized runtime environment.
extends Node2D
class_name SimulationController


## Signals emitted at start and end of simulation runtime.
## Why: Used for UI synchronization and event‑based control across external widgets.
signal started()
signal ended()
signal replaying()


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

@export var simulation: Simulation
var recorder: SimulationRecorder

## Initializes simulation context and sets up window and connections.
## Why: Waits one frame for valid viewport sizing, constructs subsystems,
## and connects tick timing before automatic launch.
func _ready() -> void:
	recorder = SimulationRecorder.new(timer)
	recorder.update_simulation_config.connect(set_simulation_config)

	config_window = SimulationConfigWindow.new_window(self, simulation.config)
	config_window.hide()
	await get_tree().process_frame
	get_tree().root.add_child(config_window)
	start()


## Starts simulation execution and applies configuration values.
## Why: Rebuilds managers with provided parameters to synchronize bounds,
## infection radius, and agent population.
func start(cfg: SimulationConfig = simulation.config, record: bool = true) -> void:
	if simulation.is_running():
		return
	if record:
		recorder.create_recorder(cfg)
		recorder.start_recording()
	simulation.start(cfg)
	started.emit()


## Gracefully stops active simulation and hides renderer.
## Why: Maintains system integrity and avoids freeing nodes mid‑loop.
func end() -> void:
	if not simulation.is_running():
		return
	simulation.end()
	print(recorder.recorder)
	ended.emit()

func replay() -> void:
	replaying.emit()
	recorder.select_recording()
	var cfg: SimulationConfig = SimulationConfig.new()
	cfg.from_dictionary(recorder.recorder.initial_state)
	set_simulation_config(cfg)
	start(cfg, false)


## Pauses or resumes ticking while retaining timing configuration.
## Why: Provides user control to inspect intermediate frames without losing synchronization.
func set_pause(paused: bool) -> void:
	if timer.paused == paused:
		return
	timer.set_paused(paused)


## Adjusts baseline movement speed for all agents.
## Why: Used by sliders or UI widgets to change pacing dynamically.
func set_speed(speed: float) -> void:
	simulation.set_speed(speed)
	recorder.record(timer.get_tick(), ["agent_speed"], speed)


## Updates simulation bounds for all dependent systems.
## Why: Propagates to grid, zoom controls, and movement constraints.
func set_bounds(bounds: Vector2) -> void:
	simulation.set_bounds(bounds)
	recorder.record(timer.get_tick(), ["bounds" ,"x"], bounds.x)
	recorder.record(timer.get_tick(), ["bounds" ,"y"], bounds.y)


## Modifies fixed‑step tick rate multiplier to simulate time dilation.
## Why: Provides smooth slow‑motion or acceleration effects.
func set_speed_multiplier(multiplier: float) -> void:
	simulation.set_speed_multiplier(multiplier)

## Sets logical timestep duration directly.
## Why: Adjusts frequency of simulation logic ticks while keeping renderer consistent.
func set_tick(step_seconds: float) -> void:
	timer.step_seconds = step_seconds


## Updates infection radius across logic and grid systems.
## Why: Keeps spatial proximity computations consistent after parameter changes.
func set_transmission_radius(transmission_radius: float) -> void:
	simulation.set_transmission_radius(transmission_radius)
	recorder.record(timer.get_tick(), ["infection_config", "transmission_radius"], transmission_radius)


## Adjusts infection transmission probability globally.
## Why: Reapplies contagiousness factor to current infection algorithm.
func set_transmission_probability(probability: float) -> void:
	simulation.set_transmission_probability(probability)
	recorder.record(timer.get_tick(), ["infection_config", "transmission_probability"], probability)


## Updates incubation or contagious stage timers in AgentStateManager.
## Why: Allows per‑state, real‑time tuning of duration ranges.
func set_state_timer(state: AgentStateManager.AgentState, state_timer: Vector2) -> void:
	simulation.set_state_timer(state, state_timer)
	recorder.record(timer.get_tick(), ["stage_durations", state, "min"], state_timer.x)
	recorder.record(timer.get_tick(), ["stage_durations", state, "max"], state_timer.y)



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

	info_window = SimulationInfoWindow.new_info_window(ConfigInfo.get_simulation_description(simulation.config))
	simulation.agent_manager.contact_tracer.elapsed_time.connect(info_window.on_contact_tracing_elapsed_time)
	add_child(info_window)



## Reports whether simulation is currently active.
## Why: Ensures external query consistency for UI and scheduling widgets.
func is_running() -> bool:
	return simulation.is_running()


## Shows or hides infection grid overlay visualization.
## Why: Toggles between performance mode and diagnostic inspection mode.
func set_grid_visibility(grid_visible: bool) -> void:
	simulation.set_grid_visibility(grid_visible)

func set_simulation_config(cfg: SimulationConfig) -> void:
	simulation.set_simulation_config(cfg)
	update_config_window_parameters()

func update_config_window_parameters() -> void:
	if config_window:
		config_window.update_from_config(simulation.config)