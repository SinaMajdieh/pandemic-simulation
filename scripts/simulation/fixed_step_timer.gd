## Deterministic timer emitting fixed‑step ticks independent of frame rate.
## Why: Keeps simulation updates consistent regardless of rendering performance.
extends Node
class_name FixedStepTimer

## Fired each fixed step; carries step length for consumers.
signal tick(step_seconds: float)

## Fixed tick duration (default 60 Hz).
## Why: Defines discrete simulation interval.
@export var step_seconds: float = 1.0 / 60.0

## Time‑scaling multiplier for speeding/slowing simulation.
## Why: Enables fast‑forward or slow‑motion effects.
@export var speed_multiplier: float = 1.0

## Pauses ticking completely.
## Why: Supports controlled manual stepping/debug break.
@export var paused: bool = false

## Carries unprocessed frame time to maintain deterministic ticking.
## Why: Prevents loss of fractional delta between frames.
var _accumulator: float = 0.0

## Fraction toward next tick for smooth render interpolation.
## Why: Used to blend visual states between logic frames.
var _alpha: float = 0.0:
	get = get_alpha

## Sequential tick counter for diagnostics and replay tracking.
var _tick_index: int = 0:
	get = get_tick


## Converts frame delta into one or more fixed ticks.
func update(delta: float) -> void:
	if paused:
		return
	
	_accumulator += delta * speed_multiplier        # Apply speed control to elapsed time.
	while _accumulator >= step_seconds:             # Catch up one or more ticks if lagged.
		tick.emit(step_seconds)
		_tick_index += 1
		_accumulator -= step_seconds
	
	_alpha = _accumulator / step_seconds            # Compute interpolation ratio for visuals.


## Toggles pause state.
func set_paused(paused_: bool = true) -> void:
	paused = paused_


## Adjusts playback speed dynamically.
func set_speed(speed_multiplier_: float = 1.0) -> void:
	speed_multiplier = speed_multiplier_


## Emits exactly one tick while paused (manual step).
func single_step() -> void:
	if paused:
		tick.emit(step_seconds)


## Returns render interpolation fraction.
func get_alpha() -> float:
	return _alpha


## Returns current tick index.
func get_tick() -> int:
	return _tick_index


## Resets internal counters and time accumulation.
func reset() -> void:
	_accumulator = 0.0
	_alpha = 0.0
	_tick_index = 0
