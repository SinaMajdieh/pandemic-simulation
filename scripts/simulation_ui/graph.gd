extends Control
## Periodically samples the current agent count for a given state from the Census
## and appends it to a MetricGraphPanel over time.
## Why Control: Can be dropped into any UI scene and handle its own layout + graph child.

@export var state: AgentStateManager.AgentState
## Which agent state this sampler is tracking, e.g. Susceptible/Infectious/Recovered.
## Exported so it can be set directly from the editor for different instances.

@export var simulation_controller: SimulationController
## Reference to the main simulation coordinator, used to reach the Census data.

@export var line_width: float = 2.0
## Thickness of the rendered line in the graph — larger for readability on dense data.

@export var max_points: int = 1000
## Buffer cap: determines how many historical samples are retained in the graph.

@export var sampling_rate: float = 1.0
## Time interval (seconds) between samples — 1.0 means once per second.
## Why configurable: Allows faster sampling for volatile states, slower for stable.

var next_sample_in: float
## Countdown timer until next sample — positive means still waiting.

var graph_panel: MetricGraphPanel
## Runtime-created panel containing a MetricGraph for this state.

var census: Census
## Link to the centralized state population tracker.

# === Core update logic ===
func _update_graph() -> void:
	## Get the current count of agents in the chosen state.
	## Why cast to float: Graph API expects float values for drawing, even if discrete.
	var amount: int = census.get_census(state)
	graph_panel.add_metric(float(amount))

# === Initialization ===
func _ready() -> void:
	simulation_controller.ended.connect(_on_simulation_ended)
	simulation_controller.started.connect(_on_simulation_started)

	## One-frame delay ensures viewport dimensions are finalized before adding UI children.
	await get_tree().process_frame

	## Create a new panel with title from enum key, state-specific color, and capacity settings.
	graph_panel = MetricGraphPanel.new_panel(
		AgentStateManager.AgentState.find_key(state),  ## Title string from enum key name.
		line_width,
		AgentRenderer.state_color_map[state],          ## Consistent with agent render color for visual coherence.
		max_points
	)
	add_child(graph_panel)  ## Attach panel so it appears in the scene immediately.

	## Set timer until next sample — avoids double‑sampling right after init.
	next_sample_in = sampling_rate

# === Per-frame execution ===
func _process(delta: float) -> void:
	if simulation_controller.timer.paused:
		return
	_advance_interval(delta)

# === Sampling interval management ===
func _advance_interval(delta: float) -> void:
	## Why decrement then check <= 0: Ensures accumulation of sub‑second deltas
	## and sampling exactly at or after desired interval, even with small frame times.
	if next_sample_in <= 0:
		_update_graph()
		next_sample_in = sampling_rate
		return

	next_sample_in -= delta

func _on_simulation_ended() -> void:
	graph_panel.clear()

func _on_simulation_started() -> void:
	## Connect to live census data in the simulation.
	census = simulation_controller.agent_manager.state_manager.census
