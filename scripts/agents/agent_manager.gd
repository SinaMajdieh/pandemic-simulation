## Central coordination of movement, infection logic, and SEIR state updates.
## Why: Aggregates subsystem managers (state, movement, contact) while keeping them modular
## for future optimization or GPU substitution without disrupting data interfaces.
class_name AgentManager


## Fixed agent count for stable array allocation across all subsystems.
var agent_count: int

## Handles SEIR transitions, stage progression, and infection timers.
var state_manager: AgentStateManager

## Controls positions and velocity; supports boundary reflection.
var movement_manager: AgentMovementManager

## Executes proximity‑based infection checks between agents.
var contact_tracer: ContactTracer


## Initializes subsystem managers using configuration data.
## Why: Preallocates arrays to prevent runtime heap allocation during each tick,
## ensuring deterministic performance in large‑scale simulations.
func _init(cfg: SimulationConfig) -> void:
	agent_count = cfg.agent_count

	state_manager = AgentStateManager.new(agent_count, cfg.stage_durations)
	movement_manager = AgentMovementManager.new(cfg.agent_count, cfg.bounds, cfg.agent_speed)

	if cfg.contact_tracing_on_gpu:
		contact_tracer = ContactTracerGPU.new(cfg.agent_count, cfg.bounds, state_manager, cfg.infection_config)
	else:
		contact_tracer = ContactTracer.new(cfg.agent_count, cfg.bounds, state_manager, cfg.infection_config)

	movement_manager.randomize()  # Ensures agents start spatially dispersed


## Executes one simulation tick in deterministic order.
## Why: Movement precedes contact tracing to ensure accurate proximity calculations,
## and timers update prior to infection logic for coherent SEIR phasing.
func advance(delta: float) -> void:
	movement_manager.advance(delta)
	state_manager.advance_timers(delta)
	contact_tracer.infect_contacts(movement_manager.positions, state_manager.states)


## Updates boundary limits for all subsystems operating on spatial data.
func set_bounds(new_bounds: Vector2) -> void:
	movement_manager.bounds = new_bounds
	contact_tracer.bounds = new_bounds


## Adjusts global movement speed affecting all agents.
func set_speed(speed: float) -> void:
	movement_manager.agent_speed = speed


## Updates infection radius for proximity evaluation in contact tracing.
func set_transmission_radius(radius: float) -> void:
	contact_tracer.set_transmission_radius(radius)


## Changes probabilistic infection sensitivity on valid contact.
func set_transmission_probability(probability: float) -> void:
	contact_tracer.set_transmission_probability(probability)


## Updates duration range per SEIR stage across the agent population.
func set_state_timer(state: AgentStateManager.AgentState, state_timer: Vector2) -> void:
	state_manager.set_state_timer(state, state_timer)

func update_config(cfg: SimulationConfig) -> void:
	agent_count = cfg.agent_count
	state_manager.update_config(cfg)
	movement_manager.update_config(cfg)
	contact_tracer.update_config(cfg)
