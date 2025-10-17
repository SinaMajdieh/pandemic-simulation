## Interactive runtime configuration window.
## Why: Centralizes all in‑simulation adjustments to agent, infection, and timing
## parameters so experiments can run dynamically without restarting the simulation.
extends ParameterUpdater
class_name SimulationConfigWindow


## Preloaded packed scene reference for creating configuration UIs when requested.
## Why: Guarantees factory‑consistent instantiation including pre‑wired signals.
const SCENE: PackedScene = preload("res://scenes/simulation_config.tscn")


## Root UI container for sizing and layout control.
## Why: Stores reference to allow dynamic alignment against viewport bounds.
@export var ui_container: Control


@export_category("Simulation Config")

## Total number of agents participating in simulation; locked once simulation starts.
## Why: Controls buffer allocation in AgentManager and cannot change mid‑run.
@export var agent_count_spin: SpinBox

## Slider controlling global movement speed for all agents.
## Why: Direct mapping to SimulationController.set_speed.
@export var agent_speed_spin: SpinBox

## Editable width of world bounds.
## Why: Allows horizontal dimension changes pre‑simulation.
@export var bounds_width_spin: SpinBox

## Editable height of world bounds.
## Why: Allows vertical dimension changes pre‑simulation.
@export var bounds_height_spin: SpinBox


@export_category("Infectious Config")

## Infection spread radius.
## Why: Adjusted for epidemiological experiment variation and spatial density testing.
@export var transmission_radius_spin: SpinBox

## Infection transmission probability (percentage form).
## Why: Presents intuitive unit for UI while SimulationController expects [0–1] float.
@export var transmission_probability_spin: SpinBox

## Toggle visibility of debug spatial infection grid.
## Why: Visual diagnostic tool to observe infection proximity cells.
@export var transmission_grid_button: CheckButton


@export_category("Timers Config")

## Minimum EXPOSED stage duration.
## Why: Lower bound of incubation length variation across agents.
@export var exposed_timer_min: SpinBox

## Maximum EXPOSED stage duration.
## Why: Upper bound defining potential incubation window.
@export var exposed_timer_max: SpinBox

## Minimum INFECTIOUS stage duration.
## Why: Controls contagious phase onset timing.
@export var infectious_timer_min: SpinBox

## Maximum INFECTIOUS stage duration.
## Why: Controls contagious phase duration cap.
@export var infectious_timer_max: SpinBox


@export_category("Initial State Config")

## Starting count of EXPOSED agents.
## Why: Determines initial infection seeding for stochastic testing.
@export var initial_exposed_spin: SpinBox

## Starting count of INFECTIOUS agents.
## Why: Determines immediate viral propagation intensity at launch.
@export var initial_infectious_spin: SpinBox


@export_category("Simulation")

## Toggle button for pause/resume control.
## Why: Mirrors timer.paused, allowing user to halt simulation interactively.
@export var pause_button: CheckButton

## Time dilation multiplier spinbox.
## Why: Allows slow‑motion or fast‑forward of tick updates.
@export var speed_multiplier_spin: SpinBox

## Tick frequency spinbox (seconds per step = 1/value).
## Why: Lets user directly edit logic step granularity visually.
@export var tick_spin: SpinBox

## Button to start simulation manually.
## Why: Single‑point entry for launching core system initialization after changes.
@export var run_simulation_button: Button

## Button to stop simulation.
## Why: Graceful shutdown preserving all subsystem cleanup order.
@export var stop_simulation_button: Button

@export var replay_simulation_button: Button

## CheckBox controlling GPU contact tracing mode.
## Why: Enables runtime benchmarking of CPU vs. GPU infection pipeline.
@export var contact_tracing_on_gpu_button: CheckButton

## Array of nodes disabled during active simulation.
## Why: Prevents unsafe real‑time configuration edits once systems start.
@export var disable_during_simulation: Array[Control]

@export var simulation_parameters_ui: Array[Control]

## Factory method generating pre‑connected configuration window instance.
## Why: Ensures dependency setup and initial parameter synchronization.
static func new_window(simulation_controller_: SimulationController, cfg: SimulationConfig) -> SimulationConfigWindow:
	var window: SimulationConfigWindow = SCENE.instantiate()
	window.simulation_controller = simulation_controller_
	window.config = cfg
	window.update_from_config(cfg)
	window._connect_signals()
	return window


## Initializes bindings and subscriptions to simulation lifecycle signals.
## Why: Keeps runtime editability synchronized with start/stop events.
func _ready() -> void:
	size = ui_container.size
	simulation_controller.started.connect(_on_simulation_started)
	simulation_controller.ended.connect(_on_simulation_stopped)
	simulation_controller.replaying.connect(_on_simulation_replay)


## Synchronizes UI widget values with current configuration resource.
## Why: Guarantees correct reflection of real simulation parameters at open time.
func update_from_config(cfg: SimulationConfig) -> void:
	if not cfg:
		return
	agent_count_spin.value = cfg.agent_count
	agent_speed_spin.value = cfg.agent_speed
	bounds_width_spin.value = cfg.bounds.x
	bounds_height_spin.value = cfg.bounds.y
	contact_tracing_on_gpu_button.button_pressed = cfg.contact_tracing_on_gpu

	transmission_radius_spin.value = cfg.infection_config.transmission_radius
	transmission_probability_spin.value = cfg.infection_config.transmission_probability * 100.0
	transmission_grid_button.button_pressed = simulation_controller.simulation.cell_grid.visible

	exposed_timer_min.value = cfg.stage_durations[AgentStateManager.AgentState.EXPOSED].x
	exposed_timer_max.value = cfg.stage_durations[AgentStateManager.AgentState.EXPOSED].y
	infectious_timer_min.value = cfg.stage_durations[AgentStateManager.AgentState.INFECTIOUS].x
	infectious_timer_max.value = cfg.stage_durations[AgentStateManager.AgentState.INFECTIOUS].y

	initial_exposed_spin.value = cfg.initial_states[AgentStateManager.AgentState.EXPOSED]
	initial_infectious_spin.value = cfg.initial_states[AgentStateManager.AgentState.INFECTIOUS]

	pause_button.button_pressed = simulation_controller.timer.paused
	speed_multiplier_spin.value = simulation_controller.timer.speed_multiplier
	tick_spin.value = 1.0 / simulation_controller.timer.step_seconds


## Connects UI signals to parent controller relay functions.
## Why: Maintains a single communication path between widgets and logic system.
func _connect_signals() -> void:
	_connect_signals_to_controller()
	contact_tracing_on_gpu_button.toggled.connect(_on_contact_tracing_on_gpu_changed)
	agent_count_spin.value_changed.connect(_on_agent_count_changed)
	agent_speed_spin.value_changed.connect(_on_agent_speed_changed)
	bounds_width_spin.value_changed.connect(_on_bounds_width_changed)
	bounds_height_spin.value_changed.connect(_on_bounds_height_changed)
	transmission_radius_spin.value_changed.connect(_on_transmission_radius_changed)
	transmission_probability_spin.value_changed.connect(_on_transmission_probability_changed)
	transmission_grid_button.toggled.connect(_on_transmission_grid_visibility_changed)
	exposed_timer_min.value_changed.connect(_on_exposed_timer_min_changed)
	exposed_timer_max.value_changed.connect(_on_exposed_timer_max_changed)
	infectious_timer_min.value_changed.connect(_on_infectious_timer_min_changed)
	infectious_timer_max.value_changed.connect(_on_infectious_timer_max_changed)
	initial_exposed_spin.value_changed.connect(_on_initial_exposed_changed)
	initial_infectious_spin.value_changed.connect(_on_initial_infectious_changed)
	pause_button.toggled.connect(_on_pause_changed)
	speed_multiplier_spin.value_changed.connect(_on_speed_multiplier_changed)
	tick_spin.value_changed.connect(_on_tick_changed)
	run_simulation_button.pressed.connect(_start_simulation)
	stop_simulation_button.pressed.connect(simulation_controller.end)
	replay_simulation_button.pressed.connect(simulation_controller.replay)


## Handles GPU tracing toggle change.
## Why: Updates config flag without restarting; allows benchmarking switch.
func _on_contact_tracing_on_gpu_changed(contact_tracing_on_gpu: bool) -> void:
	config.contact_tracing_on_gpu = contact_tracing_on_gpu


## Updates bounds after width spin change.
## Why: Constructs full Vector2 for consistent controller propagation.
func _on_bounds_width_changed(width: float) -> void:
	_on_bounds_changed(Vector2(width, bounds_height_spin.value))


## Updates bounds after height spin change.
## Why: Ensures paired horizontal/vertical consistency.
func _on_bounds_height_changed(height: float) -> void:
	_on_bounds_changed(Vector2(bounds_width_spin.value, height))


## Normalizes infection probability before controller dispatch.
## Why: Converts percentage to 0–1 float expected by logic.
func _on_transmission_probability_changed(probability: float) -> void:
	config.infection_config.transmission_probability = probability / 100.0
	transmission_probability_changed.emit(probability / 100.0)


## Updates EXPOSED timer min value range.
## Why: Repackages range vector to relay unified timing pair.
func _on_exposed_timer_min_changed(time: float) -> void:
	_on_exposed_timer_changed(Vector2(time, exposed_timer_max.value))


## Updates EXPOSED timer max value range.
## Why: Keeps timer adjustment atomic and consistent.
func _on_exposed_timer_max_changed(time: float) -> void:
	_on_exposed_timer_changed(Vector2(exposed_timer_min.value, time))


## Updates INFECTIOUS timer min range.
## Why: Enables quick live tuning for disease progression testing.
func _on_infectious_timer_min_changed(time: float) -> void:
	_on_infectious_timer_changed(Vector2(time, infectious_timer_max.value))


## Updates INFECTIOUS timer max range.
## Why: Allows fine control over contagious phase duration.
func _on_infectious_timer_max_changed(time: float) -> void:
	_on_infectious_timer_changed(Vector2(infectious_timer_min.value, time))


## Applies user input for initial exposed count.
## Why: Updates seeding dictionary and propagates to runtime manager.
func _on_initial_exposed_changed(count: float) -> void:
	config.initial_states[AgentStateManager.AgentState.EXPOSED] = int(count)


## Applies user input for initial infectious count.
## Why: Same as exposed; updates seeding dictionary for consistency.
func _on_initial_infectious_changed(count: float) -> void:
	config.initial_states[AgentStateManager.AgentState.INFECTIOUS] = int(count)


## Handles simulation start UI state.
## Why: Disables unsafe edits and swaps visible control buttons.
func _on_simulation_started() -> void:
	for node: Control in disable_during_simulation:
		if node is Button:
			node.disabled = true
		else:
			node.editable = false
	run_simulation_button.hide()
	replay_simulation_button.hide()
	stop_simulation_button.show()


## Handles simulation stop UI state.
## Why: Re‑enables editable components and restores button visibility.
func _on_simulation_stopped() -> void:
	for node: Control in disable_during_simulation:
		if node is Button:
			node.disabled = false
		else:
			node.editable = true
	run_simulation_button.show()
	replay_simulation_button.show()
	stop_simulation_button.hide()
	unlock_simulation_parameters_ui()

func _on_simulation_replay() -> void:
	lock_simulation_parameters_ui()

func lock_simulation_parameters_ui() -> void:
	for node: Control in simulation_parameters_ui:
		if node is Button:
			node.disabled = true
		else:
			node.editable = false 

func unlock_simulation_parameters_ui() -> void:
	for node: Control in simulation_parameters_ui:
		if node is Button:
			node.disabled = false
		else:
			node.editable = true 

## Launches simulation with current configuration.
## Why: Acts as direct delegate to controller.start().
func _start_simulation() -> void:
	simulation_controller.start(config)


## Closes (hides) configuration window while retaining signal connections.
## Why: Avoids overhead
func _on_close() -> void:
	hide()
