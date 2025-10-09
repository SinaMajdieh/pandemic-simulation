## Central coordination of movement, infection logic, and SEIR state updates.
## Why: Combines subsystem managers but keeps them modular for easy optimization or GPU substitution.
class_name AgentManager

## Fixed agent count for stable array allocation across subsystems.
var agent_count: int

## Handles SEIR transitions and disease timers.
var state_manager: AgentStateManager

## Manages movement and boundary reflection.
var movement_manager: AgentMovementManager

## Performs contact-based infection checks.
var contact_tracer: ContactTracer


func _init(cfg: SimulationConfig) -> void:
	## Creates subsystem managers and seeds initial state.
	## Why: Avoids runtime allocation during each simulation tick.
	agent_count = cfg.agent_count
	
	state_manager = AgentStateManager.new(agent_count, cfg.stage_durations)
	movement_manager = AgentMovementManager.new(cfg.agent_count, cfg.bounds, cfg.agent_speed)
	contact_tracer = ContactTracer.new(cfg.agent_count, cfg.bounds, state_manager, cfg.infection_config)
	
	movement_manager.randomize()  # Ensures agents start dispersed


func advance(delta: float) -> void:
	## Executes one simulation step in deterministic order.
	movement_manager.advance(delta)  # Move first so contact checks use updated positions
	state_manager.advance_timers(delta)  # Advance infection timers before contact tracing
	contact_tracer.infect_contacts(movement_manager.positions, state_manager.states)


func set_bounds(new_bounds: Vector2) -> void:
	## Updates boundary limits across subsystems.
	movement_manager.bounds = new_bounds
	contact_tracer.bounds = new_bounds

func set_speed(speed: float) -> void:
	## Adjusts global movement speed.
	movement_manager.agent_speed = speed

func set_transmission_radius(radius: float) -> void:
	## Updates contact sensitivity range.
	contact_tracer.set_transmission_radius(radius)

func set_transmission_probability(probability: float) -> void:
	## Changes infection probability on contact.
	contact_tracer.set_transmission_probability(probability)

func set_state_timer(state: AgentStateManager.AgentState, state_timer: Vector2) -> void:
	## Updates per-state duration range (min,max).
	state_manager.set_state_timer(state, state_timer)
