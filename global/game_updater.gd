extends Node

# --- Optional: set a GitHub token to avoid harsh rate limits (60/hr unauth'd).
var GITHUB_TOKEN: String = OS.get_environment("GITHUB_TOKEN")

const API_BASE           := "https://api.github.com"
const GH_HEADERS         := [
							"User-Agent: GodotGameLauncher",
							"Accept: application/vnd.github+json",
							"X-GitHub-Api-Version: 2022-11-28"
							]
signal game_updating(game: ManifestLoader.GameLibraryEntry, message: String, progress: float)
signal game_update_finished()
signal game_update_error(message: String)

# -----------------------------------------------------------
# Public method to update all games from the manifest file.
# -----------------------------------------------------------
# 
func update_all_games() -> void:
	for game in ManifestLoader.manifest.games:
		await _update_game(game)
	game_update_finished.emit()


# -----------------------------------------------------------
# Update one game from the manifest file.
# -----------------------------------------------------------
# 
# This will download the latest release and extract it to the specified folder.
#
func _update_game(game : ManifestLoader.GameLibraryEntry) -> void:
	var game_folder = ManifestLoader.get_absolute_path_to_game_folder(game)
	
	# Ensure folder exists
	_make_dir_recursive_abs(game_folder)

	# Ensure VERSION file exists
	var version_path := game_folder.path_join("VERSION")
	if not FileAccess.file_exists(version_path):
		print("No game version found! Creating new VERSION at %s..." % version_path)
		_write_text_file(version_path, "Nothing")

	# Read current version
	var current_version := FileAccess.get_file_as_string(version_path).strip_edges()

	# Get latest release info
	var url     := "%s/repos/%s/%s/releases/latest" % [API_BASE, game.repo_owner, game.repo_name]
	var headers := GH_HEADERS.duplicate()
	if GITHUB_TOKEN.strip_edges() != "":
		headers.append("Authorization: Bearer %s" % GITHUB_TOKEN)
	var release = await _get_json(url, headers)
	if typeof(release) != TYPE_DICTIONARY:
		game_update_error.emit("[GameUpdater] Failed to get release for %s/%s" % [game.repo_owner, game.repo_name])
		return

	var latest_version := str(release.get("tag_name", ""))
	if latest_version == "":
		game_update_error.emit("[GameUpdater] No tag_name on latest release for %s/%s" % [game.repo_owner, game.repo_name])
		return

	if current_version == latest_version:
		print("Game is already up to date (version %s)." % current_version)
		return

	# Notify user and let UI breathe if needed
	print("Updating game version from %s to %s..." % [current_version, latest_version])
	game_updating.emit(game, "Updating game %s from version %s to %s..." % [game.title, current_version, latest_version], 0.0)
	await get_tree().process_frame

	# Wipe folder contents
	_erase_dir_contents(game_folder)

	# Find zip asset
	var assets    =  release.get("assets", [])
	var zip_asset := {}
	for a in assets:
		if typeof(a) == TYPE_DICTIONARY and str(a.get("name", "")).to_lower().ends_with(".zip"):
			zip_asset = a
			break
	if zip_asset.is_empty():
		game_update_error.emit("[GameUpdater] Error: Game artifact (*.zip) not found in latest release for %s/%s" % [game.repo_owner, game.repo_name])
		return
		
	# Prepare to download zip
	var zip_url  := str(zip_asset.get("browser_download_url", ""))
	var zip_name := str(zip_asset.get("name", "game.zip"))
	if zip_url == "":
		game_update_error.emit("[GameUpdater] Error: asset has no browser_download_url")
		return

	# Notify user and let UI breathe if needed
	print("Downloading %s ..." % zip_name)
	game_updating.emit(game, "Downloading game %s version %s..." % [game.title, latest_version], 0.1)
	await get_tree().process_frame

	# Download zip to disk
	var zip_path := game_folder.path_join(zip_name)
	var http :=     _get_http()
	http.download_file = zip_path
	var result                          = await http.request_completed
	http.queue_free()
	var resp_code: int                  = result[1]
	var resp_headers: PackedStringArray = result[2]
	if resp_code < 200 or resp_code >= 300:
		game_update_error.emit("[GameUpdater] HTTP request failed with code %d headers %s for URL: %s headers: %s" % [resp_code, resp_headers, url, headers])
		return
	
	if not FileAccess.file_exists(zip_path):
		game_update_error.emit("[GameUpdater] Error: Failed to download the game zip file.")
		return

	# Extract
	print("Extracting %s ..." % zip_name)
	var extracted := _unzip(zip_path, game_folder)
	# Cleanup zip
	DirAccess.remove_absolute(zip_path)

	if not extracted:
		game_update_error.emit("[GameUpdater] Error: Failed to extract zip.")
		return

	# Update VERSION
	_write_text_file(version_path, latest_version)
	print("Update complete. Current version is now %s." % latest_version)


# -----------------------------------------------------------
# HTTP helpers
# -----------------------------------------------------------
func _full_headers(custom: Array) -> PackedStringArray:
	var out: PackedStringArray = []
	for h in custom:
		out.append(str(h))
	return out


# Get JSON from URL with headers
# Returns parsed JSON data or null on error
func _get_json(url: String, headers: Array) -> Variant:
	var http := _get_http()
	var err :=  http.request(url, _full_headers(headers))
	if err != OK:
		game_update_error.emit( "HTTP request failed with error %d for URL: %s headers: %s" % [err, url, headers])
		return null
	var result                          = await http.request_completed
	http.queue_free()
	var resp_code: int                  = result[1]
	var resp_headers: PackedStringArray = result[2]
	var resp_body: PackedByteArray      = result[3]
	if resp_code < 200 or resp_code >= 300:
		game_update_error.emit("[GameUpdater] HTTP request failed with code %d headers %s for URL: %s headers: %s" % [resp_code, resp_headers, url, headers])
		return null
	return JSON.parse_string(resp_body.get_string_from_utf8())

# -----------------------------------------------------------
# Zip extraction (Godot 4.x ZIPReader)
# -----------------------------------------------------------
func _unzip(zip_path: String, dest_dir: String) -> bool:
	var zr       := ZIPReader.new()
	var open_err := zr.open(zip_path)
	if open_err != OK:
		game_update_error.emit("[GameUpdater] ZIP open error: %s" % open_err)
		return false

	for inner_path in zr.get_files():
		var out_path := dest_dir.path_join(inner_path)
		_make_dir_recursive_abs(out_path.get_base_dir())

		var data: PackedByteArray =  zr.read_file(inner_path)
		var f                     := FileAccess.open(out_path, FileAccess.WRITE)
		if f == null:
			game_update_error.emit("[GameUpdater] Write fail: %s" % out_path)
			return false
		f.store_buffer(data)
		f.close()

	zr.close()
	return true


# -----------------------------------------------------------
# File and directory operations
# -----------------------------------------------------------

# Ensure the directory exists, creating it recursively if needed
# This is an absolute path operation.
func _make_dir_recursive_abs(path: String) -> void:
	if path == "" or DirAccess.dir_exists_absolute(path):
		return
	DirAccess.make_dir_recursive_absolute(path)


# Erase all contents of a directory recursively.
# This will not remove the directory itself, only its contents.
# If the directory does not exist, it will do nothing.
# This is an absolute path operation.
func _erase_dir_contents(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	var d := DirAccess.open(path)
	if d == null:
		return
	d.list_dir_begin()
	while true:
		var next: String = d.get_next()
		if next == "":
			break
		if next == "." or next == "..":
			continue
		var full := path.path_join(next)
		if d.current_is_dir():
			_erase_dir_contents(full)
			DirAccess.remove_absolute(full)
		else:
			DirAccess.remove_absolute(full)
	d.list_dir_end()


# Write text to a file, creating directories as needed.
# This will overwrite the file if it exists.
# This is an absolute path operation.
# If the file cannot be opened, it will do nothing.
# Returns true on success, false on failure.
func _write_text_file(path: String, text: String) -> void:
	_make_dir_recursive_abs(path.get_base_dir())
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(text)
		f.close()


# Create an HTTP request node and connect its completion signal.
func _get_http() -> HTTPRequest:
	var http = HTTPRequest.new()
	http.timeout = 60.0
	add_child(http)
	return http
