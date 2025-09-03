extends Control

@onready var show_error_container: Control = $ShowError
@onready var show_error_console: RichTextLabel = $ShowError/Console
@onready var show_update_container: PanelContainer = $ShowUpdate
@onready var show_update_progress_bar: ProgressBar = $ShowUpdate/VBoxContainer/ProgressBar
@onready var show_update_console: RichTextLabel = $ShowUpdate/VBoxContainer/Console
@onready var console: RichTextLabel = $Console


# On initialization, connect signals
func _init() -> void:
	GameLibrary.manifest_error.connect(_on_manifest_error)
	GameLibrary.manifest_loaded.connect(_on_manifest_loaded)
	GameUpdater.game_update_error.connect(_on_game_update_error)
	GameUpdater.game_update_message.connect(_on_game_update_message)
	GameUpdater.game_update_progress.connect(_on_game_update_progress)
	GameUpdater.all_games_updated.connect(_on_all_games_updated)


# After the manifest is loaded, update all games
func _on_manifest_loaded() -> void:
	GameUpdater.update_all_games()


# After all games are updated, display the collection and game details
func _on_all_games_updated() -> void:
	if show_update_container.is_visible():
		show_update_container.hide()
	var text: String = ""
	text += "[b]Collection: %s[/b]\n\n" % GameLibrary.manifest.collection
	for game in GameLibrary.manifest.games:
		text += "[b]%s[/b]\n%s\n\n" % [game.title, GameLibrary.get_absolute_path_to_game_executable(game)]
	$Console.text = text


# Handle manifest loading errors
func _on_manifest_error(message: String) -> void:
	_show_error("[Manifest] %s" % message)


# Handle manifest loading errors
func _on_game_update_error(message: String) -> void:
	_show_error("[GameUpdate] %s" % message)


# Display manifest errors in a modal dialog
func _show_error(message: String) -> void:
	show_error_console.text += message + "\n"
	if not show_error_container.is_visible():
		show_error_container.show()
	pass


# Handle game update message signal
func _on_game_update_message(message: String) -> void:
	print("[GameUpdater] %s" % message)
	show_update_console.text += message + "\n"
	show_update_console.scroll_to_line(show_update_console.get_line_count() - 1)
	if not show_update_container.is_visible():
		show_update_container.show()


# Handle game update progress signal
func _on_game_update_progress(progress: float) -> void:
	show_update_progress_bar.value = progress
	
