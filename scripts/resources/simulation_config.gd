## Resource holding all tunable simulation parameters.
## Why: Centralizes all adjustable properties controlling agents, infection,
## and environment behavior — preventing hardcoding and enabling Inspector editing,
## preset saving, and reusability across multiple simulation scenes.
extends Resource
class_name SimulationConfig


@export_category("Simulation Setup")

@export var seed_value: int = 329

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


## Produces a formatted text summary of all simulation parameters.
## Why: A diagnostic helper for logs or GUI panels, ensuring real‑time configuration readability.
func _to_string() -> String:
	var description_string: String = ""
	var description: Dictionary[String, String] = ConfigInfo.get_simulation_description(self)
	for key: String in description.keys():
		description_string += "%s: %s\n" % [key, description[key]]
	return description_string


## Serializes the entire configuration into a dictionary structure.
## Why: Used as intermediate form before writing or converting to JSON.
func to_dictionary() -> Dictionary:
	var results: Dictionary = {}
	results["seed_value"] = seed_value
	results["agent_count"] = agent_count
	results["agent_speed"] = agent_speed
	results["bounds"] = {"x": bounds.x, "y": bounds.y}

	## Nested resource serialization.
	## Why: Keeps infection settings tied to SimulationConfig but modular.
	if infection_config and infection_config.has_method("to_dictionary"):
		results["infection_config"] = infection_config.to_dictionary()
	else:
		push_warning("SimulationConfig.to_dictionary(): No infectious resource")
		results["infection_config"] = null
	
	## Disease stages serialization.
	## Why: Converts Vector2 ranges for JSON readability.
	var stage_durations_dictionary: Dictionary = {}
	for key: AgentStateManager.AgentState in stage_durations.keys():
		var duration: Vector2 = stage_durations[key]
		stage_durations_dictionary[key] = {"min": duration.x, "max": duration.y}
	results["stage_durations"] = stage_durations_dictionary

	## Initial state seed serialization.
	## Why: Encodes counts per state for deterministic startup population.
	var initial_states_dictionary: Dictionary = {}
	for key: AgentStateManager.AgentState in initial_states.keys():
		initial_states_dictionary[key] = initial_states[key]
	results["initial_states"] = initial_states_dictionary

	return results


func from_dictionary(dictionary: Dictionary) -> void:
	## Basic numeric + vector restoration.
	## Why: Reconstructs primary simulation setup values.
	if dictionary.has("seed_value"):
		seed_value = int(dictionary["seed_value"])
	if dictionary.has("agent_count"):
		agent_count = int(dictionary["agent_count"])
	if dictionary.has("agent_speed"):
		agent_speed = float(dictionary["agent_speed"])
	if dictionary.has("bounds"):
		var bounds_dictionary: Dictionary = dictionary["bounds"]
		bounds = Vector2(float(bounds_dictionary["x"]), float(bounds_dictionary["y"]))

	## Nested infection resource reconstruction.
	## Why: Fully reinstates InfectionConfig from serialized JSON.
	if dictionary.has("infection_config") and infection_config and infection_config.has_method("from_dictionary"):
		infection_config.from_dictionary(dictionary["infection_config"])

	## Stage duration reconstruction.
	## Why: Restores per‑stage timing ranges from saved JSON.
	if dictionary.has("stage_durations"):
		var stage_durations_dictionary: Dictionary = dictionary["stage_durations"]
		for key: Variant in stage_durations_dictionary.keys():
			var duration: Dictionary = stage_durations_dictionary[key]
			stage_durations[int(key)] = Vector2(float(duration["min"]), float(duration["max"]))

	## Initial state reconstruction.
	## Why: Restores startup population distribution for deterministic replays.
	if dictionary.has("initial_states"):
		var initial_states_dictionary: Dictionary = dictionary["initial_states"]
		for key: Variant in initial_states_dictionary.keys():
			initial_states[int(key)] = int(initial_states_dictionary[key])

## Converts the simulation parameters dictionary to JSON.
## Why: Prepares a persistent representation for saving/loading presets or replays.
func to_json(pretty: bool = true) -> String:
	var dictionary: Dictionary = to_dictionary()
	var json_string: String = JSON.stringify(dictionary, "\t" if pretty else "", pretty)
	return json_string


## Loads configuration fields from a JSON string.
## Why: Enables restoring a previously exported configuration for deterministic replay.
func from_json(json_string: String) -> void:
	var result: Variant = JSON.parse_string(json_string)
	if result == null:
		push_error("SimulationConfig.from_json(): Invalid JSON format.")
		return

	var dictionary: Dictionary = result

	from_dictionary(dictionary)
