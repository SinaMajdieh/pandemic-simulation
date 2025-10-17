## Records and reconstructs simulation states for deterministic playback and debugging.
class_name ChangeRecorder

var initial_state: Dictionary = {}
var changes: Dictionary = {}

const KEY: String = "key"
const VALUE: String = "value"

var Err: ChangeRecorderError = ChangeRecorderError.new()


## Creates a recorder from a deep copy of the initial dictionary.
func _init(initial_state_: Dictionary) -> void:
	initial_state = initial_state_.duplicate(true)


## Logs a value change under a specific tick index.
func record(tick: int, key: Array, value: Variant) -> void:
	var entry: Dictionary = {KEY: key, VALUE: value}
	changes[tick] = changes.get(tick, []) + [entry]


## Returns all recorded changes in readable text format for analysis.
func _to_string() -> String:
	var changes_str: String = ""
	for tick: int in changes.keys():
		var tick_int: int = tick
		var changes_array: Array = get_change(tick_int)
		for change: Dictionary in changes_array:
			var change_dict: Dictionary = change
			if not _is_change_valid(change_dict):
				push_error(Err.get_message(Err.Code.KEY_VALUE_PAIR_MISMATCH))
				continue
			changes_str += "tick %5d %5s -> %5s\n" % [tick_int, change_dict[KEY], change_dict[VALUE]]
	return changes_str


## Applies a single change to the given state and returns a new state copy.
func _apply_change(state: Dictionary, change: Dictionary) -> Dictionary:
	var state_copy: Dictionary = state.duplicate(true)
	if not _is_change_valid(change):
		push_error(Err.get_message(Err.Code.KEY_VALUE_PAIR_MISMATCH))
		return state_copy

	var keys: Array = change[KEY]
	var current: Dictionary = state_copy

	for i: int in range(keys.size() - 1):
		var key: Variant = keys[i]
		if not current.has(key):
			push_error(Err.get_message(Err.Code.MISSING_KEY, [key]))
			return state_copy
		current = current[key]

	var final_key: Variant = keys[-1]
	if not current.has(final_key):
		push_error(Err.get_message(Err.Code.MISSING_KEY, [final_key]))
		return state_copy

	current[final_key] = change[VALUE]
	return state_copy


## Reconstructs full state up to a given tick by sequentially applying changes.
func get_state_at(target_tick: int) -> Dictionary:
	var snapshot: Dictionary = initial_state.duplicate(true)
	var keys_sorted: Array = changes.keys()
	keys_sorted.sort()

	for tick: int in keys_sorted:
		if tick > target_tick:
			break
		for change: Dictionary in get_change(tick):
			snapshot = _apply_change(snapshot, change)
	return snapshot


## Ensures a change dictionary includes mandatory keys.
func _is_change_valid(change: Dictionary) -> bool:
	return change.has(KEY) and change.has(VALUE)


## Fetches all recorded changes for a specific tick index.
func get_change(tick: int) -> Array:
	return changes.get(tick, [])


## Clears recorder memory and resets all stored state.
func clear() -> void:
	changes.clear()
	initial_state.clear()
