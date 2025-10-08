extends Label
## Displays the current simulation tick rate from a FixedStepTimer.

@export var timer: FixedStepTimer
## FixedStepTimer reference — set in editor.

var previous_step: float
## Stores last step size to avoid unnecessary text updates.

func _ready() -> void:
	## Connect to the timer's tick signal so updates happen only on simulation ticks.
	timer.tick.connect(_on_simulation_tick)

func _on_simulation_tick(step: float) -> void:
	## Updates label if tick size changes — converts step length to ticks/second.
	if is_equal_approx(step, previous_step):
		return
	var tick_rate: int = int(1.0 / step)
	text = "%d ticks" % tick_rate
	previous_step = step
