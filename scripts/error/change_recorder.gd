## Centralized error type for ChangeRecorder validation handling.
class_name ChangeRecorderError

## Enumerates possible error categories for recording integrity checks.
enum Code {
	KEY_VALUE_PAIR_MISMATCH,
	MISSING_KEY,
}

## Maps codes to format-ready message templates.
var error_message: Dictionary[Code, String] = {
	Code.KEY_VALUE_PAIR_MISMATCH: "Key Value pair mismatch",
	Code.MISSING_KEY: "Key %s was missing",
}

## Returns formatted string for the given error code and optional arguments.
func get_message(code: Code, args: Array = []) -> String:
	if not error_message.has(code):
		return ""
	return error_message[code] % args
