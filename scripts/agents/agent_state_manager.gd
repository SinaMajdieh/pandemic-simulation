## Manages SEIR stage logic and timing for all agents.
## Why: Centralizes stage transitions and timers to ensure consistent behavior
##      across both CPU and future GPU implementations.
class_name AgentStateManager

signal state_census_update(state: AgentState, amount_changed: int)

## Encodes SEIR stages as integers for compact storage and efficient comparisons.
enum AgentState {
	SUSCEPTIBLE = 0,    # Healthy, vulnerable to infection
	EXPOSED     = 1,    # Infected but not yet infectious
	INFECTIOUS  = 2,    # Can transmit to others
	RECOVERED   = 3     # Immune, no longer participates in spread
}

## Duration ranges for each stage (Vector2 = min, max in seconds).
## Why: Stores both bounds directly to avoid branching during random timer generation.
var stage_durations: Dictionary[AgentState, Vector2] = {
	AgentState.SUSCEPTIBLE : Vector2(0.0, 0.0),
	AgentState.EXPOSED     : Vector2(2.0, 10.0),
	AgentState.INFECTIOUS  : Vector2(3.0, 8.0),
	AgentState.RECOVERED   : Vector2(0.0, 0.0),
}

## Total number of agents — defines buffer sizes.
var agent_count: int

## SEIR stage per agent.
var states: PackedInt32Array

## Remaining time for current stage for each agent.
var stage_timer: PackedFloat32Array

## List of agents with active timers to skip inactive ones each frame.
var active_timers: PackedInt32Array

## Tracks per‑state counts and updates external census.
var census: Census


func _init(agent_count_: int, stage_durations_: Dictionary[AgentState, Vector2]) -> void:
	## Initializes all agent buffers and sets initial SUSCEPTIBLE state.
	agent_count = agent_count_
	stage_durations = stage_durations_
	
	census = Census.new()
	state_census_update.connect(census.update_census)
	
	states = PackedInt32Array()
	states.resize(agent_count)
	states.fill(AgentState.SUSCEPTIBLE)
	state_census_update.emit(AgentState.SUSCEPTIBLE, agent_count)

	stage_timer = PackedFloat32Array()
	stage_timer.resize(agent_count)
	stage_timer.fill(0.0)

	active_timers = PackedInt32Array()


func advance_timers(delta: float) -> void:
	## Decrements timers only for agents with active stages until depleted.
	var i: int = 0
	while i < active_timers.size():
		var idx: int = active_timers[i]
		stage_timer[idx] -= delta
		if stage_timer[idx] <= 0.0:
			active_timers.remove_at(i)  # Safe removal inside while loop.
			transition_agent(idx)
		else:
			i += 1


func set_state(agent_index: int, new_state: AgentState) -> void:
	## Updates a single agent’s state and resets its timer accordingly.
	state_census_update.emit(states[agent_index], -1)
	state_census_update.emit(new_state, 1)
	states[agent_index] = new_state
	
	var duration: Vector2 = stage_durations[new_state]
	var timer_value: float = randf_range(duration.x, duration.y)
	stage_timer[agent_index] = timer_value
	
	var active_index: int = active_timers.find(agent_index)
	if timer_value > 0.0:
		if active_index == -1:
			active_timers.append(agent_index)
	elif active_index != -1:
		active_timers.remove_at(active_index)


func transition_agent(agent_index: int) -> void:
	## Advances agent to the next SEIR stage once timer expires.
	match states[agent_index]:
		AgentState.EXPOSED:
			set_state(agent_index, AgentState.INFECTIOUS)
		AgentState.INFECTIOUS:
			set_state(agent_index, AgentState.RECOVERED)
		_:
			pass


func seed_stage(percentage: float, target_state: AgentState) -> void:
	## Randomly initializes a portion of agents to a specific stage.
	percentage = clamp(percentage, 0.0, 1.0)
	var total_to_change: int = int(agent_count * percentage)
	if total_to_change <= 0:
		return
	
	# Build shuffled index list (Fisher–Yates algorithm)
	var indices: PackedInt32Array = PackedInt32Array()
	indices.resize(agent_count)
	for i: int in range(agent_count):
		indices[i] = i
	for i: int in range(agent_count - 1, 0, -1):
		var j: int = randi() % (i + 1)
		var tmp: int = indices[i]
		indices[i] = indices[j]
		indices[j] = tmp
	
	for i: int in range(total_to_change):
		set_state(indices[i], target_state)


func set_state_timer(state: AgentStateManager.AgentState, state_timer: Vector2) -> void:
	## Updates min/max duration for a specific stage.
	if not stage_durations.has(state):
		return
	stage_durations[state] = state_timer

func update_config(cfg: SimulationConfig) -> void:
	agent_count = cfg.agent_count
	stage_durations = cfg.stage_durations