## Resource holding all tunable simulation parameters.
## Why: Centralizes configuration to avoid hardcoding in multiple managers,
##      enables Inspector editing, reuse across scenes, and saves tuning presets.
extends Resource
class_name SimulationConfig

## Marks this script as a Resource type in the Godot editor.
@export_category("Simulation Setup")

## Total number of agents; fixed for all managers to ensure buffer size sync.
@export var agent_count: int = 10_000

## Uniform movement speed for all agents.
## Why: Keeps all agents moving at the same rate to simplify collision & timing logic.
@export var agent_speed: float = 25.0

## Maximum X/Y in world coordinate space for agent movement.
## Why: Shared between MovementManager & ContactTracer for consistent spatial bounds.
@export var bounds: Vector2 = Vector2(1024, 1024)


@export_category("Infection Parameters")
@export var infection_config: InfectionConfig = InfectionConfig.new()


@export_category("Disease Stage Durations")

## Duration ranges for each stage (Vector2 = min, max in seconds).
## Why: Allows randomized stage lengths without branching — one variable holds both bounds.
@export var stage_durations: Dictionary[AgentStateManager.AgentState, Vector2] = {
	AgentStateManager.AgentState.SUSCEPTIBLE : Vector2(0.0, 0.0),  ## no timer since not progressing
	AgentStateManager.AgentState.EXPOSED     : Vector2(2.0, 10.0), ## incubation before infectious
	AgentStateManager.AgentState.INFECTIOUS  : Vector2(3.0, 8.0),  ## full contagious period
	AgentStateManager.AgentState.RECOVERED   : Vector2(0.0, 0.0)   ## immune stage, no timer
}

## Initial population distribution by agent state.
## Why: Defines explicit seeding for the simulation’s starting conditions,
## using typed dictionary keys (AgentState enum) for clarity and GPU‑safe integer storage.
@export var initial_states: Dictionary[AgentStateManager.AgentState, int] = {
	AgentStateManager.AgentState.EXPOSED    : 100,
	AgentStateManager.AgentState.INFECTIOUS : 0,
}

