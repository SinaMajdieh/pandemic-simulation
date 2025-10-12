## JSON persistence handler for configuration resources.
## Why: Decouples serialization from file I/O.
class_name ConfigPersistence


## Saves configuration to JSON.
## Why: Exports presets or snapshots safely.
static func save_to_json(path: String, config: Resource, to_json_method: String = "to_json") -> void:
	if not config.has_method(to_json_method):
		push_error("Missing method: %s" % to_json_method)
		return
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	var json_data: String = config.call(to_json_method)
	file.store_string(json_data)
	file.close()


## Loads configuration from JSON.
## Why: Restores presets or simulation states.
static func load_from_json(path: String, config: Resource, from_json_method: String = "from_json") -> void:
	if not FileAccess.file_exists(path):
		push_error("File not found: %s" % path)
		return
	if not config.has_method(from_json_method):
		push_error("Missing method: %s" % from_json_method)
		return
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	var content: String = file.get_as_text()
	file.close()
	config.call(from_json_method, content)
