extends ResourceOperations

# --- Optional: set a GitHub token to avoid harsh rate limits (60/hr unauth'd).
# You can also pass it from project settings or read from env:
var github_token: String =  OS.get_environment("GITHUB_TOKEN")
const API_BASE           := "https://api.github.com"
const GH_HEADERS         := [
							"User-Agent: GodotGameLauncher",
							"Accept: application/vnd.github+json",
							"X-GitHub-Api-Version: 2022-11-28"
							]


# -----------------------------------------------------------
# Public method to update all games from the manifest file.
# -----------------------------------------------------------
# 
func update_all_games() -> void:
	for game in ManifestLoader.manifest.games:
		_update_game(game)


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
	if github_token.strip_edges() != "":
		headers.append("Authorization: Bearer %s" % github_token)
	var release = await _get_json(url, headers)
	if typeof(release) != TYPE_DICTIONARY:
		error("Failed to get release for %s/%s" % [game.repo_owner, game.repo_name])
		return

	var latest_version := str(release.get("tag_name", ""))
	if latest_version == "":
		error("No tag_name on latest release for %s/%s" % [game.repo_owner, game.repo_name])
		return

	if current_version == latest_version:
		print("Game is already up to date (version %s)." % current_version)
		return

	print("Updating game version from %s to %s..." % [current_version, latest_version])

	# Wipe folder contents
	await get_tree().process_frame  # let UI breathe if needed
	_erase_dir_contents(game_folder)

	# Find zip asset
	var assets    =  release.get("assets", [])
	var zip_asset := {}
	for a in assets:
		if typeof(a) == TYPE_DICTIONARY and str(a.get("name", "")).to_lower().ends_with(".zip"):
			zip_asset = a
			break
	if zip_asset.is_empty():
		error("Error: Game artifact (*.zip) not found in latest release for %s/%s" % [game.repo_owner, game.repo_name])
		return

	var zip_url  := str(zip_asset.get("browser_download_url", ""))
	var zip_name := str(zip_asset.get("name", "game.zip"))
	if zip_url == "":
		error("Error: asset has no browser_download_url")
		return

	# Download zip to disk
	var zip_path := game_folder.path_join(zip_name)
	print("Downloading %s ..." % zip_name)
	var ok := await _download_file(zip_url, zip_path, headers)
	if not ok or not FileAccess.file_exists(zip_path):
		error("Error: Failed to download the game zip file.")
		return

	# Extract
	print("Extracting %s ..." % zip_name)
	var extracted := _unzip(zip_path, game_folder)
	# Cleanup zip
	DirAccess.remove_absolute(zip_path)

	if not extracted:
		error("Error: Failed to extract zip.")
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
	var err := http.request(url, _full_headers(headers))
	if err != OK:
		error( "HTTP request failed with error %d for URL: %s headers: %s" % [err, url, headers])
		return null
	var result                          = await http.request_completed
	var resp_code: int                  = result[1]
	var resp_headers: PackedStringArray = result[2]
	var resp_body: PackedByteArray      = result[3]
	if resp_code < 200 or resp_code >= 300:
		error("HTTP request failed with code %d headers %s for URL: %s headers: %s" % [resp_code, resp_headers, url, headers])
		return null
	return JSON.parse_string(resp_body.get_string_from_utf8())


# Download file from URL to disk
# Returns true on success, false on error
# Note: this will overwrite existing files at `to_path`
func _download_file(url: String, to_path: String, headers: Array) -> bool:
	http.download_file = to_path
	var result                          = await http.request_completed
	var resp_code: int                  = result[1]
	var resp_headers: PackedStringArray = result[2]
	http.download_file = ""
	if resp_code >= 200 and resp_code < 300:
		return true
	error("HTTP request failed with code %d headers %s for URL: %s headers: %s" % [resp_code, resp_headers, url, headers])
	return false


# -----------------------------------------------------------
# Zip extraction (Godot 4.x ZIPReader)
# -----------------------------------------------------------
func _unzip(zip_path: String, dest_dir: String) -> bool:
	var zr       := ZIPReader.new()
	var open_err := zr.open(zip_path)
	if open_err != OK:
		error("ZIP open error: %s" % open_err)
		return false

	for inner_path in zr.get_files():
		var out_path := dest_dir.path_join(inner_path)
		_make_dir_recursive_abs(out_path.get_base_dir())

		var data: PackedByteArray =  zr.read_file(inner_path)
		var f                     := FileAccess.open(out_path, FileAccess.WRITE)
		if f == null:
			error("Write fail: %s" % out_path)
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
