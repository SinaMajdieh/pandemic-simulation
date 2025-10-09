extends Node
class_name FixedStepTimer
## Emits a fixed-step `tick` signal for deterministic simulation updates, decoupled from Godot's frame rate.
## Why: Ensures simulation logic runs at consistent time intervals regardless of rendering performance.

signal tick(step_seconds: float)
## Emitted once per fixed step, passing the step duration as a parameter.

@export var step_seconds: float = 1.0 / 60.0
## Length of each simulation tick in seconds — 1/60 = 60 ticks per second.
## Why export: Allows quick tuning from the editor without code changes.

@export var speed_multiplier: float = 1.0
## Multiplies delta time before accumulation — use to speed up or slow down simulation
## without changing `step_seconds` (e.g., for fast-forward or slow-motion).

@export var paused: bool = false
## If true, halts normal ticking until resumed — single-step still possible.

var _accumulator: float = 0.0
## Holds leftover time from frames that didn’t fill a whole tick — carried over until enough accumulates.
## Why accumulate: Avoids temporal drift by carrying surplus time rather than discarding it.

var _alpha: float = 0.0:
	get = get_alpha
## Interpolation factor in range [0, 1).
## Why store: Used by render code to interpolate between previous and current simulation states for smooth visuals.


## Called every rendered frame with its real-world duration.
func update(delta: float) -> void:
	if paused:
		return
	
	## Scale delta by speed multiplier for fast-forward/slow-motion effects.
	_accumulator += delta * speed_multiplier
	
	## Use while-loop instead of if:
	## Why: If frame delta is large (slow frame), multiple ticks may be needed to catch up
	## in one update call — prevents simulation from lagging behind real time.
	while _accumulator >= step_seconds:
		tick.emit(step_seconds)     ## Fire logic update at fixed interval.
		_accumulator -= step_seconds
	
	## Compute fraction of next tick elapsed — used for smooth interpolation in visuals.
	_alpha = _accumulator / step_seconds


## Pauses or resumes ticking — useful for debugging or manual control.
func set_paused(paused_: bool = true) -> void:
	
	paused = paused_


## Adjusts playback speed without disturbing tick length.
func set_speed(speed_multiplier_: float = 1.0) -> void:
	speed_multiplier = speed_multiplier_


## Fires exactly one tick while paused — allows advancing the simulation manually frame-by-frame.
func single_step() -> void:
	if paused:
		tick.emit(step_seconds)


## Returns interpolation factor so render systems can blend between last and next state.
func get_alpha() -> float:
	return _alpha
