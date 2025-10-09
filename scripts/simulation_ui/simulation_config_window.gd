extends ParameterUpdater
class_name SimulationConfigWindow

## Runtime configuration window used to tune the simulation interactively.
## Why: Provides real‑time param adjustment through bound UI controls and signals,
## enabling adaptive experimentation without restarting the core simulation.


## Preloaded PackedScene reference for spawning the configuration window on demand.
const SCENE: PackedScene = preload("res://scenes/simulation_config.tscn")


## Root container for the UI layout; used for size synchronization in _ready().
@export var ui_container: Control


@export_category("Simulation Config")

## Number of agents allowed in the simulation — locked once simulation has started.
@export var agent_count_spin: SpinBox

## SpinBox controlling agent movement speed.
@export var agent_speed_spin: SpinBox

## World width of the simulation environment.
@export var bounds_width_spin: SpinBox

## World height of the simulation environment.
@export var bounds_height_spin: SpinBox


@export_category("Infectious Config")

## Radius controlling infection spread distance between agents.
@export var transmission_radius_spin: SpinBox

## Probability of infection (0–100); divided by 100 internally for controller logic.
@export var transmission_probability_spin: SpinBox

## Toggles the spatial infection grid visualization for debug purposes.
@export var transmission_grid_button: CheckButton


@export_category("Timers Config")

## Minimum duration for the EXPOSED stage of simulation disease cycle.
@export var exposed_timer_min: SpinBox

## Maximum duration for EXPOSED stage.
@export var exposed_timer_max: SpinBox

## Minimum duration for INFECTIOUS stage.
@export var infectious_timer_min: SpinBox

## Maximum duration for INFECTIOUS stage.
@export var infectious_timer_max: SpinBox


@export_category("Initial State Config")

## SpinBox controlling initial exposed agent count.
@export var initial_exposed_spin: SpinBox

## SpinBox controlling initial infectious agent count.
@export var initial_infectious_spin: SpinBox



@export_category("Simulation")

## Pause/resume toggle — directly mirrors SimulationController.timer.paused.
@export var pause_button: CheckButton

## Multiplicative time‑scale spinbox allowing slowdown or acceleration.
@export var speed_multiplier_spin: SpinBox

## Defines tick frequency; controller expects seconds per step, so value inverted.
@export var tick_spin: SpinBox

## Manual start button for simulation initialization.
@export var run_simulation_button: Button

## Manual stop button for gracefully ending the simulation.
@export var stop_simulation_button: Button

@export var disable_during_simulation: Array[Node]

## Factory constructor creating a new instance of the configuration window.
## Why: Guarantees correct setup of dependency injection (controller + config)
## before any signals emit or user interaction occurs.
static func new_window(simulation_controller_: SimulationController, cfg: SimulationConfig) -> SimulationConfigWindow:
	var window: SimulationConfigWindow = SCENE.instantiate()
	window.simulation_controller = simulation_controller_
	window.config = cfg
	window.update_from_config(cfg)
	window._connect_signals()
	return window


## Performs basic initialization of local size and simulation state bindings.
## Why: Subscribes to SimulationController lifecycle signals to dynamically toggle UI editability.
func _ready() -> void:
	size = ui_container.size
	simulation_controller.started.connect(_on_simulation_started)
	simulation_controller.ended.connect(_on_simulation_stopped)


## Synchronizes all UI widgets with their corresponding current configuration values.
## Why: Ensures that opening or refreshing the window always reflects real simulation parameters.
func update_from_config(cfg: SimulationConfig) -> void:
	agent_count_spin.value = cfg.agent_count
	agent_speed_spin.value = cfg.agent_speed
	bounds_width_spin.value = cfg.bounds.x
	bounds_height_spin.value = cfg.bounds.y

	transmission_radius_spin.value = cfg.infection_config.transmission_radius
	transmission_probability_spin.value = cfg.infection_config.transmission_probability * 100.0
	transmission_grid_button.button_pressed = simulation_controller.cell_grid.visible

	exposed_timer_min.value = cfg.stage_durations[AgentStateManager.AgentState.EXPOSED].x
	exposed_timer_max.value = cfg.stage_durations[AgentStateManager.AgentState.EXPOSED].y

	infectious_timer_min.value = cfg.stage_durations[AgentStateManager.AgentState.INFECTIOUS].x
	infectious_timer_max.value = cfg.stage_durations[AgentStateManager.AgentState.INFECTIOUS].y

	initial_exposed_spin.value = cfg.initial_states[AgentStateManager.AgentState.EXPOSED]
	initial_infectious_spin.value = cfg.initial_states[AgentStateManager.AgentState.INFECTIOUS]

	pause_button.button_pressed = simulation_controller.timer.paused
	speed_multiplier_spin.value = simulation_controller.timer.speed_multiplier
	tick_spin.value = 1.0 / simulation_controller.timer.step_seconds


## Connects UI component signals to inherited ParameterUpdater relay methods.
## Why: Keeps all updates reactive and unified under SimulationController,
## ensuring both visual and logical coherence across systems.
func _connect_signals() -> void:
	_connect_signals_to_controller()
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


## Emits new bounds Vector2 when width spinbox changes.
func _on_bounds_width_changed(width: float) -> void:
	_on_bounds_changed(Vector2(width, bounds_height_spin.value))


## Emits new bounds Vector2 when height spinbox changes.
func _on_bounds_height_changed(height: float) -> void:
	_on_bounds_changed(Vector2(bounds_width_spin.value, height))


## Emits updated infection probability as normalized [0–1] float.
func _on_transmission_probability_changed(probability: float) -> void:
	config.infection_config.transmission_probability = probability / 100.0
	transmission_probability_changed.emit(probability / 100.0)


## Re‑emits EXPOSED timer range (min) to ParameterUpdater relay.
func _on_exposed_timer_min_changed(time: float) -> void:
	_on_exposed_timer_changed(Vector2(time, exposed_timer_max.value))


## Re‑emits EXPOSED timer range (max) to ParameterUpdater relay.
func _on_exposed_timer_max_changed(time: float) -> void:
	_on_exposed_timer_changed(Vector2(exposed_timer_min.value, time))


## Re‑emits INFECTIOUS timer range (min).
func _on_infectious_timer_min_changed(time: float) -> void:
	_on_infectious_timer_changed(Vector2(time, infectious_timer_max.value))


## Re‑emits INFECTIOUS timer range (max).
func _on_infectious_timer_max_changed(time: float) -> void:
	_on_infectious_timer_changed(Vector2(infectious_timer_min.value, time))


## Updates configuration when exposed SpinBox value changes.
func _on_initial_exposed_changed(count: float) -> void:
	config.initial_states[AgentStateManager.AgentState.EXPOSED] = int(count)


## Updates configuration when infectious SpinBox value changes.
func _on_initial_infectious_changed(count: float) -> void:
	config.initial_states[AgentStateManager.AgentState.INFECTIOUS] = int(count)


## Handles simulation start: disables modification of agent count,
## swaps button visibility to “Stop”.
func _on_simulation_started() -> void:
	for node: Control in disable_during_simulation:
		node.editable = false
	run_simulation_button.hide()
	stop_simulation_button.show()


## Handles simulation end: re‑enable agent count editing,
## swaps button visibility back to “Run”.
func _on_simulation_stopped() -> void:
	for node: Control in disable_during_simulation:
		node.editable = true
	run_simulation_button.show()
	stop_simulation_button.hide()


## Invokes SimulationController.start() with preset agent count and config parameters.
## Why: Provides single entry point for launching core simulation logic.
func _start_simulation() -> void:
	simulation_controller.start(config)


## Hides window instead of freeing to preserve signal bindings and internal state.
## Why: Allows fast re‑opening through controller without re‑instantiation overhead.
func _on_close() -> void:
	hide()
