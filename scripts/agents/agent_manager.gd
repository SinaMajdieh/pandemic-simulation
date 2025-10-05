## Central coordination of movement, infection logic, and SEIR state updates.
## Why: Aggregates separate managers to keep responsibilities modular,
##      enabling independent optimization and future GPU/CU substitution.
class_name AgentManager

## Total agents; fixed to allow buffer preallocation across subsystems.
var agent_count: int
## Manages SEIR state transitions and exposure/infection timers.
var state_manager: AgentStateManager
## Controls agent movement and boundary reflection.
var movement_manager: AgentMovementManager
## Handles spatial partitioning and contact-based transmission checks.
var contact_tracer: ContactTracer


## Creates all managers and seeds simulation state.
## Why: Initializes subsystems once to avoid repeated allocation during simulation runtime.
func _init(cfg: SimulationConfig) -> void:
	agent_count = cfg.agent_count
	state_manager = AgentStateManager.new(agent_count)
	movement_manager = AgentMovementManager.new(
		cfg.agent_count, cfg.bounds, cfg.agent_speed
	)
	contact_tracer = ContactTracer.new(cfg.agent_count, cfg.bounds, state_manager, cfg.infection_config) # radius fixed here for uniform contact range
	movement_manager.randomize() # Ensures agents start dispersed with normalized movement


## Advances simulation step for movement, infection, and state timers.
## Why: Keeps frame-step logic in one call for predictable order of updates.
func advance(delta: float) -> void:
	movement_manager.advance(delta)                      # Positions updated first so contacts use current frame data
	state_manager.advance_timers(delta)                  # Timers tick after movement for consistent exposure decay
	contact_tracer.infect_contacts(movement_manager.positions, state_manager.states) # Runs after timers so new infections start fresh
