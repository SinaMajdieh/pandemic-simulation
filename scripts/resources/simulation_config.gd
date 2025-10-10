## Resource holding all tunable simulation parameters.
## Why: Centralizes all adjustable properties controlling agents, infection,
## and environment behavior — preventing hardcoding and enabling Inspector editing,
## preset saving, and reusability across multiple simulation scenes.
extends Resource
class_name SimulationConfig


@export_category("Simulation Setup")

## Whether to perform contact tracing computations on GPU instead of CPU.
## Why: Allows rapid switching between CPU and GPU paths for benchmarking and scalability testing.
@export var contact_tracing_on_gpu: bool = true


## Total number of agents in the simulation.
## Why: Used to preallocate buffers and keep sizes consistent across AgentManager,
## ContactTracer, and GPU shaders to ensure deterministic synchronization.
@export var agent_count: int = 10_000


## Uniform movement speed applied to all agents.
## Why: Simplifies collision checks and step timing by guaranteeing simultaneous movement rate.
@export var agent_speed: float = 25.0


## World bounds for agent movement (maximum X and Y coordinates).
## Why: Shared by both MovementManager and ContactTracer to ensure identical spatial limits.
@export var bounds: Vector2 = Vector2(1024, 1024)


@export_category("Infection Parameters")

## Reference to infection configuration resource.
## Why: Exposes nested InfectionConfig for fine‑grained tuning of contagion behavior
## without embedding infection constants directly here.
@export var infection_config: InfectionConfig = InfectionConfig.new()


@export_category("Disease Stage Durations")

## Duration range for each disease stage (Vector2 = min, max seconds).
## Why: Enables stochastic stage length generation using only one variable per state,
## avoiding conditional branching for each agent.
@export var stage_durations: Dictionary[AgentStateManager.AgentState, Vector2] = {
	AgentStateManager.AgentState.SUSCEPTIBLE : Vector2(0.0, 0.0),  ## No timer; static state
	AgentStateManager.AgentState.EXPOSED     : Vector2(2.0, 10.0), ## Incubation before infectiousness
	AgentStateManager.AgentState.INFECTIOUS  : Vector2(3.0, 8.0),  ## Active contagious phase
	AgentStateManager.AgentState.RECOVERED   : Vector2(0.0, 0.0)   ## Immune; no progression
}


## Initial population distribution for each agent state.
## Why: Defines explicit seed counts per state for startup,
## enforcing typed dictionary keys (AgentState enum) for clarity and GPU‑safe integer mapping.
@export var initial_states: Dictionary[AgentStateManager.AgentState, int] = {
	AgentStateManager.AgentState.EXPOSED    : 100,
	AgentStateManager.AgentState.INFECTIOUS : 0,
}

## Builds a structured textual dictionary describing core simulation parameters.
## Why: Enables creation of human-readable summaries for UI display (e.g. SimulationInfoWindow),
## combining controller-level and infection-level configuration data.
func get_description() -> Dictionary[String, String]:
	var description: Dictionary[String, String] = {
		"Running on": ("GPU" if contact_tracing_on_gpu else "CPU"),
		"Population": "%d" % agent_count,
		"Speed": "%.2f" % agent_speed,
		"Size": "%d %s" % [int(bounds.x * bounds.y), bounds]
	}

	description.merge(infection_config.get_description())

	description.merge({
		"Incubation period": "%.2f s - %.2f s" % [
			stage_durations[AgentStateManager.AgentState.EXPOSED].x,
			stage_durations[AgentStateManager.AgentState.EXPOSED].y
		],
		"Contagious period": "%.2f s - %.2f s" % [
			stage_durations[AgentStateManager.AgentState.INFECTIOUS].x,
			stage_durations[AgentStateManager.AgentState.INFECTIOUS].y
		]
	})

	return description


## Produces a formatted text summary of all simulation parameters.
## Why: A diagnostic helper for logs or GUI panels, ensuring real‑time configuration readability.
func _to_string() -> String:
	var description_string: String = ""
	var description: Dictionary[String, String] = get_description()
	for key: String in description.keys():
		description_string += "%s: %s\n" % [key, description[key]]
	return description_string
