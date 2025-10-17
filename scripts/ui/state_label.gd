extends Label

## Displays live count of agents per disease state.
## Why: Helps visualize dynamic population distribution by listening to
## Census signals in real time, avoiding unnecessary polling.

## Target agent state which this label represents (e.g. SUSCEPTIBLE, INFECTIOUS).
@export var state: AgentStateManager.AgentState

## External SimulationController reference for lifecycle and Census access.
@export var simulation_controller: SimulationController

## Local cached Census instance, lazily bound on simulation start.
var census: Census


## Receives population updates from Census.
## Why: Filters irrelevant state broadcasts and updates text only for its specific state.
func _on_census_updated(state_: AgentStateManager.AgentState, amount: int) -> void:
	if state_ != state:
		return
	text = "%d" % amount


## Initialization and lifecycle signal wiring.
## Why: Connects to SimulationController start/end signals to manage Census subscription cleanup,
## and applies a color override tied to the state via AgentRenderer for intuitive visual grouping.
func _ready() -> void:
	simulation_controller.ended.connect(_on_simulation_ended)
	simulation_controller.started.connect(_on_simulation_started)
	await get_tree().process_frame
	add_theme_color_override("font_color", AgentRenderer.state_color_map[state])


## Clears label on simulation end to reflect zero population.
func _on_simulation_ended() -> void:
	text = "%d" % 0


## Subscribes to live Census signals on simulation start.
## Why: Avoids null access before Census is initialized, ensuring safe reactive updates.
func _on_simulation_started() -> void:
	census = simulation_controller.simulation.agent_manager.state_manager.census
	census.census_updated.connect(_on_census_updated)
	_on_census_updated(state, census.get_census(state))
