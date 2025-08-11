extends Node

# On initialization, connect signals
func _init() -> void:
	ManifestLoader.manifest_loaded.connect(_on_manifest_loaded)


# After the manifest is loaded
func _on_manifest_loaded() -> void:
	_do_update_all_games()


# Update all games in the library
func _do_update_all_games() -> void:
	GameUpdater.update_all_games()
