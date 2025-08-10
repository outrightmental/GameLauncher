extends Node

@onready var error_dialog: AcceptDialog = $ErrorDialog

func _ready() -> void:
	ManifestLoader.manifest_loaded.connect(_on_manifest_loaded)
	
	# If there are errors, display them in a modal dialog
	if ManifestLoader.has_errors():
		_show_error_dialog(ManifestLoader.get_error_messages())
		return

	# If the autoload already loaded before this node was ready:
	if ManifestLoader.manifest.size() > 0:
		_on_manifest_loaded(ManifestLoader.manifest)

func _on_manifest_loaded(manifest: Dictionary) -> void:
	var text: String = ""
	text += "Collection: %s\n" % manifest.get("collection", "")
	for g in manifest["games"]:
		text += "- %s (%s)\n" % [g.get("title", g.get("game", "")), g.get("executable", "")]
	$TextP1.text = text
	$TextP2.text = text

# Display manifest errors in a modal dialog
func _show_error_dialog(message: String) -> void:
	error_dialog.dialog_text = "Manifest loading failed:\n" + message
	error_dialog.popup_centered()
	error_dialog.confirmed.connect(error_dialog.hide)
