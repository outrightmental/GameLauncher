extends Control

@onready var show_error_container: Control = $ShowError
@onready var show_error_console: RichTextLabel = $ShowError/Console
@onready var show_game_updating_container: PanelContainer = $ShowGameUpdating
@onready var show_game_updating_progress_bar: ProgressBar = $ShowGameUpdating/VBoxContainer/ProgressBar
@onready var show_game_updating_console: RichTextLabel = $ShowGameUpdating/VBoxContainer/Console
@onready var console: RichTextLabel = $Console


# On initialization, connect signals
func _init() -> void:
	ManifestLoader.manifest_error.connect(_show_error)
	GameUpdater.game_update_message.connect(_on_game_update_message)
	GameUpdater.game_update_progress.connect(_on_game_update_progress)
	GameUpdater.game_update_finished.connect(_on_game_update_finished)
	GameUpdater.game_update_error.connect(_show_error)


# Display manifest errors in a modal dialog
func _show_error(message: String) -> void:
	show_error_console.text += message + "\n"
	if not show_error_container.is_visible():
		show_error_container.show()
	pass


# Handle game update message signal
func _on_game_update_message(message: String) -> void:
	print("[GameUpdater] %s" % message)
	show_game_updating_console.text += message + "\n"
	show_game_updating_console.scroll_to_line(show_game_updating_console.get_line_count() - 1)
	if not show_game_updating_container.is_visible():
		show_error_container.show()


# Handle game update progress signal
func _on_game_update_progress(progress: float) -> void:
	show_game_updating_progress_bar.value = progress


# Handle game update finished signal
func _on_game_update_finished() -> void:
	if show_game_updating_container.is_visible():
		show_error_container.hide()
	pass
