extends ResourceOperations

#
# -----------------------------------------------------------
# Game Library Manifest
# -----------------------------------------------------------
# This is a global autoload that loads a games.json manifest file
# from the executable folder. It provides methods to access
# the collection name, directory path, and game entries.
# - manifest is expected to be a JSON object with a specific structure.
# - manifest is loaded when the node is ready
# - `manifest_loaded` signal is emitted when the manifest is successfully loaded.
# - If the manifest fails to load, an error is printed to the console.
#

# Signal emitted when the manifest is successfully loaded.
signal manifest_loaded(manifest: GameLibraryManifest)
# Manifest data storage
var manifest: GameLibraryManifest


# -----------------------------------------------------------
# Game Library Manifest Type
# -----------------------------------------------------------
class GameLibraryManifest extends RefCounted:
	var collection: String = ""
	var directory: String = ""
	var games: Array[GameEntry] = []


# -----------------------------------------------------------
# Game Library Manifest Entry
# -----------------------------------------------------------
class GameEntry extends RefCounted:
	var game: String = ""
	var title: String = ""
	var executable: String = ""
	var developers: Array[String] = []
	var genres: Array[String] = []
	var players: int = 2
	var description := ""
	var repo_owner := ""
	var repo_name := ""


# Prefer a manifest next to the executable (for packaged builds),
# fall back to project folder during development.
func _ready() -> void:
	var exe_dir  := OS.get_executable_path().get_base_dir()
	var external := exe_dir.path_join(Config.MANIFEST_EXTERNAL_PATH)
	var internal =  Config.MANIFEST_INTERNAL_PATH

	if FileAccess.file_exists(external):
		print("Using external manifest at: ", external)
		_load_manifest(external)
	elif FileAccess.file_exists(internal):
		print("Using internal manifest at: ", internal)
		_load_manifest(internal)
	else:
		error("manifest.json not found at either %s or %s" % [external, internal])


# Load a games.json file from the executable folder
# Emits `manifest_loaded` signal on success, or `_error` on failure.
# The manifest should be a JSON object with the following structure:
#
# {
#   "collection": "Noisebridge 1v1 Arcade Table",
#   "directory": "C:\\Users\\noise\\Documents\\GameLibrary",
#   "games": [
#     {
#       "game": "CamelCaseGameName",
#       "title": "Title of the Game",
#       "executable": "GameExecutable.exe",
#       "developers": [
#         "Person1",
#         ...
#       ],
#       "genres": [
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
func _load_manifest(manifest_path: String) -> void:
	var text: String
	var f: FileAccess

	# Use appropriate access (RESOURCES for res://, READ for external)
	f = FileAccess.open(manifest_path, FileAccess.ModeFlags.READ)

	if f == null:
		error("Unable to open %s: %s" % [manifest_path, FileAccess.get_open_error()])
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
			error("Missing required top-level key: %s" % k)
			return

	if typeof(data["games"]) != TYPE_ARRAY:
		error("`games` must be an array.")
		return

	# Optionally validate game entries minimal fields
	for i in data["games"].size():
		var g = data["games"][i]
		if typeof(g) != TYPE_DICTIONARY:
			error("games[%d] must be an object." % i)
			return

	manifest = GameLibraryManifest.new()
	manifest.collection = data.get("collection", "")
	manifest.directory = data.get("directory", "")
	for game_data in data["games"]:
		var entry = GameEntry.new()
		entry.title = _get_required_from_data(game_data,"title", "")
		entry.executable = _get_required_from_data(game_data,"executable", "")
		for developer in _get_required_from_data(game_data,"developers", []):
			entry.developers.append(developer)
		for genre in _get_required_from_data(game_data,"genres", []):
			entry.genres.append(genre)
		entry.players = _get_required_from_data(game_data,"players", 2)
		entry.description = _get_required_from_data(game_data,"description", "")
		entry.repo_owner = _get_required_from_data(game_data,"repo_owner", "")
		entry.repo_name = _get_required_from_data(game_data,"repo_name", "")
		manifest.games.append(entry)
	manifest_loaded.emit(manifest)


# Helper to get a required key from a dictionary
func _get_required_from_data(data: Dictionary, key: String, default: Variant) -> Variant:
	if not data.has(key):
		error("Game entry %s is missing required key: %s" % [data, key])
		return default
	return data[key]


# Get the collection name from the manifest.
# Return a copy to avoid accidental modification
func get_collection_name() -> String:
	if not manifest.has("collection"):
		return ""
	return manifest["collection"].duplicate(true)


# Get the directory path from the manifest.
# Return a copy to avoid accidental modification
func get_directory_path() -> String:
	if not manifest.has("directory"):
		return ""
	return manifest["directory"].duplicate(true)


# Get an array of all game entries in the manifest.
# Return a copy to avoid accidental modification
func get_all_games() -> Array[GameEntry]:
	if not manifest.has("games"):
		return []
	return manifest["games"].duplicate(true)


# Get the absolute path to an executable for a specific game entry.
# This constructs the path using the manifest's directory and the game's executable name.
func get_absolute_path_to_game_executable(repo_owner: String, repo_name: String, executable: String) -> String:
	return get_absolute_path_to_game_folder(repo_owner, repo_name).path_join(executable)


# Get the absolute path to a game folder
func get_absolute_path_to_game_folder(repo_owner: String, repo_name: String) -> String:
	return manifest.directory.path_join(repo_owner).path_join(repo_name)
