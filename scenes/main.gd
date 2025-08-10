extends Node

@onready var error_dialog: AcceptDialog = $ErrorDialog


func _init() -> void:
	ManifestLoader.manifest_loaded.connect(_on_manifest_loaded)


# If there are errors, display them in a modal dialog
# Clear errors after displaying
func _physics_process(_delta: float) -> void:
	if ManifestLoader.has_errors():
		_show_error_dialog(ManifestLoader.get_error_messages())
		ManifestLoader.clear_errors() 
		return
		


# After the manifest is loaded
func _on_manifest_loaded() -> void:
	_do_display_games()
	_do_update_all_games()
	
	
# Display the collection name and game entries in the UI
func _do_display_games() -> void:
	var text: String = ""
	text += "[b]Collection: %s[/b]\n\n" % ManifestLoader.manifest.collection
	for game in ManifestLoader.manifest.games:
		text += "[b]%s[/b]\n%s\n\n" % [game.title, ManifestLoader.get_absolute_path_to_game_executable(game)]
	$TextP1.text = text
	$TextP2.text = text
	
	
# Update all games in the library
func _do_update_all_games() -> void:
	GameUpdater.update_all_games()
	


# Display manifest errors in a modal dialog
func _show_error_dialog(message: String) -> void:
	error_dialog.dialog_text = "Manifest loading failed:\n" + message
	error_dialog.popup_centered()
	error_dialog.confirmed.connect(error_dialog.hide)
