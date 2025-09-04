extends Node

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
signal manifest_loaded
signal manifest_error(message: String)
# Manifest data storage
var manifest: Manifest


# -----------------------------------------------------------
# Game Library Manifest Type
# -----------------------------------------------------------
class Manifest extends RefCounted:
	var collection: String = ""
	var directory: String = ""
	var games: Array[Entry] = []


# -----------------------------------------------------------
# Game Library Manifest Entry
# -----------------------------------------------------------
class Entry extends RefCounted:
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
	var home   = Constants.MANIFEST_PATH_HOME
	var local   = Constants.MANIFEST_PATH_LOCAL
	var internal   = Constants.MANIFEST_PATH_INTERNAL
	if FileAccess.file_exists(home):
		print("Using user default location manifest at: ", home)
		_load_manifest(home)
	elif FileAccess.file_exists(local):
		print("Using local manifest at: ", local)
		_load_manifest(local)
	elif FileAccess.file_exists(internal):
		print("Using internal manifest at: ", internal)
		_load_manifest(internal)
	else:
		manifest_error.emit("manifest.json not found!\n%s\n%s\n%s" % [home, local, internal])


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
		manifest_error.emit("Unable to open %s: %s" % [manifest_path, FileAccess.get_open_error()])
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
			manifest_error.emit("Missing required top-level key: %s" % k)
			return

	if typeof(data["games"]) != TYPE_ARRAY:
		manifest_error.emit("`games` must be an array.")
		return

	# Optionally validate game entries minimal fields
	for i in data["games"].size():
		var g = data["games"][i]
		if typeof(g) != TYPE_DICTIONARY:
			manifest_error.emit("games[%d] must be an object." % i)
			return

	manifest = Manifest.new()
	manifest.collection = data.get("collection", "")
	manifest.directory = data.get("directory", "")
	for game_data in data["games"]:
		var entry = Entry.new()
		entry.title = _get_required_from_data(game_data, "title", "")
		entry.executable = _get_required_from_data(game_data, "executable", "")
		for developer in _get_required_from_data(game_data, "developers", []):
			entry.developers.append(developer)
		for genre in _get_required_from_data(game_data, "genres", []):
			entry.genres.append(genre)
		entry.players = _get_required_from_data(game_data, "players", 2)
		entry.description = _get_required_from_data(game_data, "description", "")
		entry.repo_owner = _get_required_from_data(game_data, "repo_owner", "")
		entry.repo_name = _get_required_from_data(game_data, "repo_name", "")
		manifest.games.append(entry)
	manifest_loaded.emit()


# Helper to get a required key from a dictionary
func _get_required_from_data(data: Dictionary, key: String, default: Variant) -> Variant:
	if not data.has(key):
		manifest_error.emit("Game entry %s is missing required key: %s" % [data, key])
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


# Get the absolute path to an executable for a specific game entry.
# This constructs the path using the manifest's directory and the game's executable name.
func get_absolute_path_to_game_executable(game: Entry) -> String:
	return get_absolute_path_to_game_folder(game).path_join(game.executable)


# Get the absolute path to a game folder
func get_absolute_path_to_game_folder(game: Entry) -> String:
	return manifest.directory.path_join(game.repo_owner).path_join(game.repo_name)
