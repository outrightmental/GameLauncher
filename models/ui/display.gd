extends Control

# On initialization, connect signals
func _init() -> void:
	ManifestLoader.manifest_loaded.connect(_on_manifest_loaded)
	ManifestLoader.manifest_error.connect(_show_error_dialog)
	GameUpdater.game_updating.connect(_on_game_updating)
	GameUpdater.game_update_finished.connect(_on_game_update_finished)
	GameUpdater.game_update_error.connect(_show_error_dialog)


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
func _show_error_dialog(message: String) -> void:
	#	error_dialog.dialog_text += message + "\n"
	#	if not error_dialog.is_visible():
	#		error_dialog.popup_centered()
	# TODO implement an error dialog
	pass


# Handle the confirmation of the error dialog
# This clears the dialog text and any recorded errors.
func _on_error_dialog_confirmed() -> void:
	#	error_dialog.dialog_text = ""
	#	if ManifestLoader.has_errors():
	#		ManifestLoader.clear_errors()
	#	if GameUpdater.has_errors():
	#		GameUpdater.clear_errors()
	# TODO implement confirmation of error dialog
	pass


# Handle game updating signal
func _on_game_updating(game: ManifestLoader.GameLibraryEntry, message: String, progress: float) -> void:
	# todo show progress in UI
	pass


# Handle game update finished signal
func _on_game_update_finished() -> void:
	# todo show progress in UI
	pass
