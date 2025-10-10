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
	return """
	Transmission Radius: %.2f
	Transmission Probability: %.2f percent
	""" % [
		transmission_radius,
		transmission_probability * 100.0
	]
