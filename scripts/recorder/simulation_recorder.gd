## Coordinates creation, storage, and replay of simulation state recordings.
class_name SimulationRecorder

signal update_simulation_config(cfg: SimulationConfig)

var limit: int = 10
var records: Array[ChangeRecorder] = []

var recorder: ChangeRecorder
var _is_recording: bool = false:
	get = is_recording

var timer: FixedStepTimer


## Initializes recorder manager and binds tick event to state watcher.
func _init(timer_: FixedStepTimer) -> void:
	timer = timer_
	timer.tick.connect(check_for_change)


## Creates a new ChangeRecorder using the current configuration.
func create_recorder(cfg: SimulationConfig) -> void:
	if is_recording():
		save_recording()
	recorder = ChangeRecorder.new(cfg.to_dictionary())


## Begins active recording of simulation changes.
func start_recording() -> void:
	_is_recording = true


## Stops active recording session.
func stop_recording() -> void:
	_is_recording = false


## Returns recording state flag.
func is_recording() -> bool:
	return _is_recording


## Records a value update for the current tick if recording is active.
func record(tick: int, key: Array, value: Variant) -> void:
	if not _is_recording:
		return
	if not recorder:
		push_error("There is no recorder, create one first")
		return
	recorder.record(tick, key, value)


## Finalizes current recorder and stores it in history FIFO-style.
func save_recording() -> void:
	stop_recording()
	records.append(recorder)
	if records.size() > limit:
		records.pop_front()


## Loads a selected recording by index or defaults to most recent.
func select_recording(index: int = -1) -> void:
	if is_recording():
		save_recording()
	if index < 0:
		index = records.size() - 1
	index = clamp(index, 0, records.size() - 1)
	recorder = records[index]


## Monitors current tick for recorded changes and emits updated configuration.
func check_for_change(_step_seconds: float) -> void:
	if is_recording():
		return
	var tick: int = timer.get_tick()
	var changes: Array = recorder.get_change(tick)
	if changes.size() > 0:
		for change: Dictionary in changes:
			print("tick %d %s -> %s" % [tick, change["key"], change["value"]])
		var updated_cfg: SimulationConfig = SimulationConfig.new()
		updated_cfg.from_dictionary(recorder.get_state_at(tick))
		update_simulation_config.emit(updated_cfg)
