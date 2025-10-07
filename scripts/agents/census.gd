class_name Census
## Tracks agent counts per infection stage and broadcasts changes.
## Why: Keeps simulation state aggregated in one place, so UI and other systems
##      can react in real time without querying the entire agent array.
##      The setter-triggered signals guarantee all listeners are kept in sync.

## --- Stage counters ---
## These hold the current number of agents in each SEIR category.
## Why setters emit signals: This allows instant UI updates or logging
## without requiring polling in the main loop.

var susceptible_count: int = 0:
	set(value):
		susceptible_count = value
		## Emits the updated count whenever this value changes,
		## enabling reactive interfaces and analytics hooks.
		census_updated.emit(AgentStateManager.AgentState.SUSCEPTIBLE, susceptible_count)

var exposed_count: int = 0:
	set(value):
		exposed_count = value
		census_updated.emit(AgentStateManager.AgentState.EXPOSED, exposed_count)

var infectious_count: int = 0:
	set(value):
		infectious_count = value
		census_updated.emit(AgentStateManager.AgentState.INFECTIOUS, infectious_count)

var recovered_count: int = 0:
	set(value):
		recovered_count = value
		census_updated.emit(AgentStateManager.AgentState.RECOVERED, recovered_count)

## Fired whenever one of the stage counts changes.
## Why: Decouples data updates from presentation — any node can
## subscribe and react without tightly coupling to simulation logic.
signal census_updated(state_updated: AgentStateManager.AgentState, amount: int)

## Increments a given stage count by `amount`.
## Why: Centralized mutation protects against mismatched updates in other code.
func update_census(state: AgentStateManager.AgentState, amount: int) -> void:
	match state:
		AgentStateManager.AgentState.SUSCEPTIBLE:
			susceptible_count += amount
		AgentStateManager.AgentState.EXPOSED:
			exposed_count += amount
		AgentStateManager.AgentState.INFECTIOUS:
			infectious_count += amount
		AgentStateManager.AgentState.RECOVERED:
			recovered_count += amount
		_:
			pass  ## Defensive default — ignores invalid states.

## Returns the count for a given stage.
## Why: Prevents spreading the internal variable names outside the class,
## allowing a possible change in storage without breaking external calls.
func get_census(state: AgentStateManager.AgentState) -> int:
	match state:
		AgentStateManager.AgentState.SUSCEPTIBLE:
			return susceptible_count
		AgentStateManager.AgentState.EXPOSED:
			return exposed_count
		AgentStateManager.AgentState.INFECTIOUS:
			return infectious_count
		AgentStateManager.AgentState.RECOVERED:
			return recovered_count
		_:
			return 0  ## Defensive default — unknown states report zero.
