## Resource holding all infection-related simulation parameters.
## Why: Encapsulates contagion tuning (radius, probability, density limits)
## apart from global agent/world configuration — providing clean modular control
## over infection dynamics and allowing independent swapping of infection logic.
extends Resource
class_name InfectionConfig


@export_category("Contact Parameters")

## Infection radius measured in world units.
## Why: Defines physical proximity threshold for transmission events.
@export var transmission_radius: float = 16.0:
	set(value):
		transmission_radius = value
		transmission_radius_sq = transmission_radius * transmission_radius

## Probability of infection per valid contact (1.0 = guaranteed infection).
## Why: Controls stochastic infection chance, tuned for realism or acceleration.
@export var transmission_probability: float = 0.0005

## Maximum count of infectious agents stored per spatial grid cell.
## Why: Ensures deterministic buffer allocation and safeguards against overflow
## in GPU or CPU contact-tracing grids.
@export var max_per_cell: int = 32


@export_category("Precomputed Values (auto)")

## Cached squared infection radius.
## Why: Precomputed to avoid repeating multiplications in high‑frequency loops;
## auto‑updated whenever the transmission radius changes.
var transmission_radius_sq: float


## Initializes cached values once when resource is constructed.
## Why: Keeps derived quantity (`transmission_radius_sq`) synchronized
## if loaded from external configuration file.
func _init() -> void:
	transmission_radius_sq = transmission_radius * transmission_radius


## Returns a readable summary string of infection parameters.
## Why: Useful for debug logging, UI display, and ensuring the same params
## are injected into compute dispatch metadata.
func _to_string() -> String:
	var description_string: String = ""
	var description: Dictionary[String, String] = ConfigInfo.get_infection_description(self)
	for key: String in description.keys():
		description_string += "%s: %s\n" % [key, description[key]]
	return description_string


## Serializes infection parameters to dictionary form.
## Why: Produces simple structured output suitable for JSON encoding.
func to_dictionary() -> Dictionary:
	var results: Dictionary = {}
	results["transmission_radius"] = transmission_radius
	results["transmission_probability"] = transmission_probability
	return results


func from_dictionary(dictionary: Dictionary) -> void:
	if dictionary.has("transmission_radius"):
		transmission_radius = float(dictionary["transmission_radius"])
	if dictionary.has("transmission_probability"):
		transmission_probability = float(dictionary["transmission_probability"])


## Converts dictionary to JSON for persistence or inspection.
## Why: Supports configuration saving and deterministic simulation replay.
func to_json(pretty: bool = true) -> String:
	var dictionary: Dictionary = to_dictionary()
	var json_string: String = JSON.stringify(dictionary, "\t" if pretty else "", pretty)
	return json_string


## Loads configuration fields from a JSON string.
## Why: Restores exported infection settings from a previous simulation or saved preset.
func from_json(json_string: String) -> void:
	var result: Variant = JSON.parse_string(json_string)
	if result == null:
		push_error("InfectiousConfig.from_json(): Invalid JSON format.")
		return
	var dictionary: Dictionary = result
	from_dictionary(dictionary)
