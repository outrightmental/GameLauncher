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
signal manifest_loaded(manifest: Dictionary)
# Manifest data storage
var manifest: GameLibraryManifest


# -----------------------------------------------------------
# Game Library Manifest Type
# -----------------------------------------------------------
class GameLibraryManifest:
	var collection: String = ""
	var directory: String = ""
	var games: Array[GameEntry] = []


# -----------------------------------------------------------
# Game Library Manifest Entry
# -----------------------------------------------------------
class GameEntry:
	var game: String = ""
	var title: String = ""
	var executable: String = ""
	var developers: Array[String] = []
	var genres: Array[String] = []
	var players: int = 2
	var description := ""
	var repo_owner := ""
	var repo_name := ""


# Load the manifest when the node is ready
func _ready() -> void:
	_load_manifest()


# Load a games.json file from the executable folder
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
func _load_manifest() -> void:
	var exe_dir               := OS.get_executable_path().get_base_dir()
	var manifest_path: String =  exe_dir.path_join(Config.MANIFEST_EXTERNAL_PATH)
	var text: String
	var f: FileAccess
	var is_res                := manifest_path.begins_with("res://")

	# Use appropriate access (RESOURCES for res://, READ for external)
	var mode := FileAccess.ModeFlags.READ if is_res else FileAccess.ModeFlags.READ
	f = FileAccess.open(manifest_path, mode)

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
		for req in ["game", "title", "executable"]:
			if not g.has(req):
				error("games[%d] missing required key: %s" % [i, req])
				return

	manifest = data
	manifest_loaded.emit( manifest)


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


# Get a specific game entry by its "game" key.
# Return a copy to avoid accidental modification
func get_game_by_key(game_key: String) -> GameEntry:
	for game in manifest.games:
		if game.game.to_lower() == game_key.to_lower():
			return game.duplicate(true)
	return null
 
