## Minimal popup window showing current simulation configuration metadata.
## Why: Offers live read‑only inspection of runtime parameters without reopening config menus.
extends Window
class_name SimulationInfoWindow


## Title label template used for each metadata key.
## Why: Duplicated per entry for dynamic descriptive layout construction.
@export var title_label: Label

## Value label template corresponding to each metadata key.
## Why: Displays individual parameter values extracted from configuration dictionary.
@export var value_label: Label

## Root UI container controlling sizing and bounds synchronization.
## Why: Window dimensions follow this container’s dynamic size.
@export var ui_container: Control

## Container holding generated label pairs.
## Why: Acts as dynamic grid display for key–value entry formatting.
@export var label_container: Control

@export var contact_tracing_time_label: Label

## Preloaded scene reference for consistent instantiation with pre-configured template.
## Why: Guarantees parameterized creation identical to other simulation window classes.
const SCENE: PackedScene = preload("res://scenes/info_window.tscn")


## Factory constructor for creating and initializing an info window instance.
## Why: Encapsulates creation and initialization logic; allows one‑line creation from controllers.
static func new_info_window(description: Dictionary[String, String]) -> SimulationInfoWindow:
	var window: SimulationInfoWindow = SCENE.instantiate() as SimulationInfoWindow
	window.init(description)
	return window


## Initializes all UI content from provided configuration description.
## Why: Dynamically builds a full list of labeled entries based on current simulation values.
func init(description: Dictionary[String, String]) -> void:
	ui_container.resized.connect(_set_size)
	for key: String in description.keys():
		var title_label_: Label = title_label.duplicate()
		title_label_.text = key

		var value_label_: Label = value_label.duplicate()
		value_label_.text = description[key]

		label_container.add_child(title_label_)
		label_container.add_child(value_label_)

		title_label_.show()
		value_label_.show()


## Synchronizes window size to UI container during resize events.
## Why: Maintains layout cohesion when viewport or content dimensions change.
func _set_size() -> void:
	size = ui_container.size


## Handles closing of the info window.
## Why: Frees memory only when user explicitly closes; no need to retain temporary data.
func _on_close() -> void:
	queue_free()

func on_contact_tracing_elapsed_time(elapsed_time_ms: int) -> void:
	contact_tracing_time_label.text = "%.2f ms" % (elapsed_time_ms / 1000.0)
