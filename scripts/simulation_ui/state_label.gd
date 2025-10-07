extends Label

@export var state: AgentStateManager.AgentState
@export var simulation_controller: SimulationController

var census: Census

func _on_census_updated(state_: AgentStateManager.AgentState, amount:int)-> void:
	if state_ != state:
		return
	text = "%d" % amount

func _ready() -> void:
	await get_tree().process_frame
	add_theme_color_override("font_color", AgentRenderer.state_color_map[state])
	census = simulation_controller.agent_manager.state_manager.census
	census.census_updated.connect(_on_census_updated)
	_on_census_updated(state, census.get_census(state))
