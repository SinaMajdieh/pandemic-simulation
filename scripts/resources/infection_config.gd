## Resource holding all infection-related simulation parameters.
## Why: Separates contagion tuning from global agent/world settings,
##      allows swapping infection rules independently of agent movement logic.
extends Resource
class_name InfectionConfig

@export_category("Contact Parameters")

## Infection radius in game units.
@export var transmission_radius: float = 16.0:
	set(value):
		transmission_radius = value
		transmission_radius_sq = transmission_radius * transmission_radius

## Probability of infection upon valid contact; 1 = certain transmission.
@export var transmission_probability: float = 0.0005

## Upper bound of infectious agents stored per spatial grid cell.
## Why: Prevents overflow in fixed-size cell buffer for spatial partitioning.
@export var max_per_cell: int = 32


@export_category("Precomputed Values (auto)")

## Why: Cached to avoid recomputing in hot loops — set once when resource initialized.
var transmission_radius_sq: float

func _init() -> void:
	transmission_radius_sq = transmission_radius * transmission_radius
