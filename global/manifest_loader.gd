extends Node

signal manifest_loaded(manifest: Dictionary)
var manifest: Dictionary  = {}
var manifest_path: String
var errors: Array[String] = []


# Returns a string of all error messages, separated by newlines.
func get_error_messages() -> String:
	var error_messages: String = ""
	for err in errors:
		error_messages += err + "\n"
	return error_messages.strip_edges()


# Returns true if there are any errors recorded.
func has_errors() -> bool:
	return errors.size() > 0


# Load a manifest.json file from the executable folder or res://
# Emits `manifest_loaded` signal on success, or `_error` on failure.
# The manifest should be a JSON object with the following structure:
#
# {
#   "collection": "Noisebridge 1v1 Arcade Table",
#   "directory": "C:\\Users\\noise\\Documents\\Games",
#   "games": [
#     {
#       "game": "CamelCaseGameName",
#       "title": "Title of the Game",
#       "executable": "GameExecutable.exe",
#       "developer": [
#         "Person1",
#         ...
#       ],
#       "genre": [
#         "Genre1",
#         ...
#       ],
#       "players": 2,
#       "description": "A brief description of the game.",
#       "repo_owner": "github_repo_owner",
#       "repo_name": "RepoName",
#     },
#     ...
#   ]
# }
# 
func _ready() -> void:
	# Prefer a manifest next to the executable (for packaged builds),
	# fall back to project folder during development.
	var exe_dir  := OS.get_executable_path().get_base_dir()
	var external := exe_dir.path_join(Config.MANIFEST_EXTERNAL_PATH)
	var internal =  Config.MANIFEST_INTERNAL_PATH

	if FileAccess.file_exists(external):
		print("Using external manifest at: ", external)
		manifest_path = external
	elif FileAccess.file_exists(internal):
		print("Using internal manifest at: ", internal)
		manifest_path = internal
	else:
		_error("manifest.json not found (looked in executable folder and res://).")
		return

	_load_manifest()


func reload() -> void:
	if manifest_path == "":
		_error("No manifest path set to reload.")
		return
	_load_manifest()


func _load_manifest() -> void:
	var text: String
	var f: FileAccess
	var is_res := manifest_path.begins_with("res://")

	# Use appropriate access (RESOURCES for res://, READ for external)
	var mode := FileAccess.ModeFlags.READ if is_res else FileAccess.ModeFlags.READ
	f = FileAccess.open(manifest_path, mode)

	if f == null:
		_error("Unable to open %s: %s" % [manifest_path, FileAccess.get_open_error()])
		return

	text = f.get_as_text()
	f.close()

	var json   = JSON.new()
	var status = json.parse(text)
	if status != OK:
		print("JSON Parse Error: ", json.get_error_message(), " at line ", json.get_error_line())
		return
	var data = json.data

	# Basic schema sanity checks (adjust to your exact issue spec)
	var required_top := ["collection", "directory", "games"]
	for k in required_top:
		if not data.has(k):
			_error("Missing required top-level key: %s" % k)
			return

	if typeof(data["games"]) != TYPE_ARRAY:
		_error("`games` must be an array.")
		return

	# Optionally validate game entries minimal fields
	for i in data["games"].size():
		var g = data["games"][i]
		if typeof(g) != TYPE_DICTIONARY:
			_error("games[%d] must be an object." % i)
			return
		for req in ["game", "title", "executable"]:
			if not g.has(req):
				_error("games[%d] missing required key: %s" % [i, req])
				return

	manifest = data
	manifest_loaded.emit( manifest)


# Helper function to log errors
func _error(message: String) -> void:
	errors.append(message)
	push_error("[ManifestLoader] %s" % message)
