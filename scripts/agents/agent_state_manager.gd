## Manages SEIR stage logic and timing for all agents.
## Why: Centralizes state transitions and stage timers,
##      enabling both CPU and potential GPU implementations to use a consistent state source.
class_name AgentStateManager

## Encodes SEIR stages as integers for compact storage and fast comparisons.
## Why: Integer enums integrate directly with PackedInt32Array for large-scale efficiency.
enum AgentState {
	SUSCEPTIBLE = 0,    # Healthy, vulnerable to infection
	EXPOSED     = 1,    # Infected but not yet infectious
	INFECTIOUS  = 2,    # Can transmit to others
	RECOVERED   = 3     # Immune, no longer participating in spread
}

## Duration ranges for each stage (Vector2 = min, max in seconds).
## Why: Allows randomized stage lengths without branching, storing both bounds in one value.
var state_timer_map: Dictionary[AgentState, Vector2] = {
	AgentState.SUSCEPTIBLE : Vector2(0.0, 0.0),
	AgentState.EXPOSED     : Vector2(2.0, 10.0),
	AgentState.INFECTIOUS  : Vector2(3.0, 8.0),
	AgentState.RECOVERED   : Vector2(0.0, 0.0),
}

## Agent count for buffer allocation.
var agent_count: int
## SEIR stage per agent.
var states: PackedInt32Array
## Remaining time for current stage for each agent.
var stage_timer: PackedFloat32Array
## Index list for agents with active stage timers to minimize per-frame checks.
var active_timers: PackedInt32Array


## Initializes state arrays with all agents starting as SUSCEPTIBLE.
## Why: Preallocates fixed-size arrays to avoid dynamic resizing during simulation.
func _init(agent_count_: int) -> void:
	agent_count = agent_count_

	states = PackedInt32Array()
	states.resize(agent_count)
	states.fill(AgentState.SUSCEPTIBLE)

	stage_timer = PackedFloat32Array()
	stage_timer.resize(agent_count)
	stage_timer.fill(0.0)

	active_timers = PackedInt32Array()


## Sets the state for a single agent and its timer if applicable.
## Why: Ensures stage timers are aligned with the chosen state and active_timers list reflects current needs.
func set_state(agent_index: int, new_state: AgentState) -> void:
	states[agent_index] = new_state
	var timer_min: float = state_timer_map[new_state].x
	var timer_max: float = state_timer_map[new_state].y
	var timer_value: float = randf_range(timer_min, timer_max)
	stage_timer[agent_index] = timer_value

	var idx: int = active_timers.find(agent_index)
	if timer_value > 0.0:
		if idx == -1:
			active_timers.append(agent_index)
	elif idx != -1:
		active_timers.remove_at(idx)


## Updates timers for agents in active_timers until they expire, then advances stage.
## Why: Iterates only over agents with timers to reduce per-frame workload.
func advance_timers(delta: float) -> void:
	var i: int = 0
	while i < active_timers.size():
		var idx: int = active_timers[i]
		stage_timer[idx] -= delta
		if stage_timer[idx] <= 0.0:
			active_timers.remove_at(i)       # Avoids skipping next element thanks to while-loop.
			transition_agent(idx)
		else:
			i += 1


## Moves an agent to its next SEIR stage once timer expires.
## Why: Encodes stage progression logic in one place for easy modification.
func transition_agent(agent_index: int) -> void:
	match states[agent_index]:
		AgentState.EXPOSED:
			set_state(agent_index, AgentState.INFECTIOUS)
		AgentState.INFECTIOUS:
			set_state(agent_index, AgentState.RECOVERED)
		_:
			pass


## Randomly selects a percentage of agents to start in a specified state.
## Why: Uses Fisher–Yates shuffle for unbiased selection in O(n).
func seed_stage(percentage: float, target_state: AgentState) -> void:
	percentage = clamp(percentage, 0.0, 1.0)
	var total_to_change: int = int(agent_count * percentage)
	if total_to_change <= 0:
		return

	# Build and shuffle index list
	var indices: PackedInt32Array = PackedInt32Array()
	indices.resize(agent_count)
	for i: int in range(agent_count):
		indices[i] = i
	for i: int in range(agent_count - 1, 0, -1):
		var j: int = randi() % (i + 1)
		var tmp: int = indices[i]
		indices[i] = indices[j]
		indices[j] = tmp

	# Apply new state to the first total_to_change shuffled agents
	for i: int in range(total_to_change):
		set_state(indices[i], target_state)
