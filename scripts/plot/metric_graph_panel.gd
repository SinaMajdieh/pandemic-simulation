extends Control
class_name MetricGraphPanel
## A Control-based wrapper for MetricGraph, making it drop‑in ready for UI layouts.
## Why: MetricGraph itself may be a pure drawing node; wrapping in a Control allows
## positioning, anchoring, and sizing within Godot UI without manual container setup.

const PANEL_SCENE: String = "res://scenes/metric_graph_panel.tscn"
## Why constant reference: Using a fixed PackedScene path ensures consistency
## between dynamically spawned panels and editor-placed panels.

# === Exported properties ===
@export var graph_node: MetricGraph
## Direct reference to the actual graph logic/renderer inside the panel.
## Why export: Lets designers wire up which sub‑node is the graph in the editor
## without hard‑coding lookups.

@export var title_label: Label
## UI label showing the graph’s title.
## Why: Makes the panel self‑describing when displayed in a dashboard.

var title: String:
	set(value):
		title = value
		## Why update label here: Centralizing title assignment ensures label stays
		## in sync whether title is set from editor or via constructor.
		title_label.text = title

# === Constructor-like factory ===
static func new_panel(
	title_: String = "SEIR",
	width: float = 2.0,
	color: Color = MetricGraph.DEFAULT_LINE_COLOR,
	max_points: int = 200
) -> MetricGraphPanel:
	## Why factory method: Allows creating a fully‑configured panel at runtime
	## without manually instancing the scene and setting properties after.
	var packed: PackedScene = load(PANEL_SCENE)
	var panel_instance: MetricGraphPanel = packed.instantiate() as MetricGraphPanel
	
	## Set visible title before returning.
	panel_instance.title = title_
	## Configure graph appearance and capacity.
	panel_instance.graph_node.line_width = width
	panel_instance.graph_node.line_color = color
	panel_instance.graph_node.max_points = max_points

	return panel_instance

# === Public API ===
func add_metric(value: float) -> void:
	## Delegates metric addition to the internal graph.
	## Why: Panel acts as pass‑through so external code doesn’t need direct graph access.
	if not graph_node:
		return
	graph_node.add_metric(value)

func clear() -> void:
	## Clears all metrics in the internal graph — useful for reset buttons in dashboards.
	if not graph_node:
		return
	graph_node.clear()
