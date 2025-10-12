## Builds readable summaries of simulation and infection parameters.
## Why: Centralizes formatting for UI and logging without exposing resource internals.
class_name ConfigInfo


## Returns full simulation description.
## Why: Combines global config and infection data for display.
static func get_simulation_description(cfg: SimulationConfig) -> Dictionary[String, String]:
	var description: Dictionary[String, String] = {
		"Running on": ("GPU" if cfg.contact_tracing_on_gpu else "CPU"),
		"Population": "%d" % cfg.agent_count,
		"Speed": "%.2f" % cfg.agent_speed,
		"Size": "%d %s" % [int(cfg.bounds.x * cfg.bounds.y), cfg.bounds]
	}

	description.merge(ConfigInfo.get_infection_description(cfg.infection_config))
	description.merge({
		"Incubation period": "%.2f s - %.2f s" % [
			cfg.stage_durations[AgentStateManager.AgentState.EXPOSED].x,
			cfg.stage_durations[AgentStateManager.AgentState.EXPOSED].y
		],
		"Contagious period": "%.2f s - %.2f s" % [
			cfg.stage_durations[AgentStateManager.AgentState.INFECTIOUS].x,
			cfg.stage_durations[AgentStateManager.AgentState.INFECTIOUS].y
		]
	})
	return description


## Returns infection description only.
## Why: Provides concise contagion tuning summary.
static func get_infection_description(cfg: InfectionConfig) -> Dictionary[String, String]:
	return {
		"Transmission Radius": "%.2f" % cfg.transmission_radius,
		"Transmission Probability": "%.2f percent" % (cfg.transmission_probability * 100),
	}
