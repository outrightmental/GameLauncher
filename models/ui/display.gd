extends Control


# On initialization, connect signals
func _init() -> void:
	ManifestLoader.manifest_loaded.connect(_on_manifest_loaded)
	ManifestLoader.manifest_error.connect(_show_error)
	GameUpdater.game_updating.connect(_on_game_updating)
	GameUpdater.game_update_finished.connect(_on_game_update_finished)
	GameUpdater.game_update_error.connect(_show_error)


# After the manifest is loaded
func _on_manifest_loaded() -> void:
	_do_display_games()


# Display the collection name and game entries in the UI
func _do_display_games() -> void:
	var text: String = ""
	text += "[b]Collection: %s[/b]\n\n" % ManifestLoader.manifest.collection
	for game in ManifestLoader.manifest.games:
		text += "[b]%s[/b]\n%s\n\n" % [game.title, ManifestLoader.get_absolute_path_to_game_executable(game)]
	$Console.text = text


# Display manifest errors in a modal dialog
func _show_error(message: String) -> void:
	$ShowError/Console.text += message + "\n"
	if not $ShowError.is_visible():
		$ShowError.show()
	pass


# Handle game updating signal
func _on_game_updating(game: ManifestLoader.GameLibraryEntry, message: String, progress: float) -> void:
	# todo show progress in UI
	pass


# Handle game update finished signal
func _on_game_update_finished() -> void:
	# todo show progress in UI
	pass
