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
		


func _on_manifest_loaded(manifest: ManifestLoader.GameLibraryManifest) -> void:
	var text: String = ""
	text += "[b]Collection: %s[/b]\n\n" % manifest.collection
	for game in manifest.games:
		text += "[b]%s[/b]\n%s\n\n" % [game.title, ManifestLoader.get_absolute_path_to_game_executable(game.repo_owner, game.repo_name, game.executable)]
	$TextP1.text = text
	$TextP2.text = text


# Display manifest errors in a modal dialog
func _show_error_dialog(message: String) -> void:
	error_dialog.dialog_text = "Manifest loading failed:\n" + message
	error_dialog.popup_centered()
	error_dialog.confirmed.connect(error_dialog.hide)
