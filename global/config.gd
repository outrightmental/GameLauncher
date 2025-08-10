extends Node

# Paths to manifest files
const MANIFEST_FILE_NAME: String     = "games.json"
const MANIFEST_PATH_INTERNAL: String = "res://example/%s" % MANIFEST_FILE_NAME

var MANIFEST_PATH_HOME: String = OS.get_environment(
									 "USERPROFILE" if OS.get_name() == "Windows"
									 else "HOME"
								 ).path_join("Documents").path_join("GameLibrary").path_join(MANIFEST_FILE_NAME)

var MANIFEST_PATH_LOCAL: String = OS.get_executable_path().path_join(MANIFEST_FILE_NAME)
# Formatting template for player input
const player_input_mapping_format: Dictionary = {
													"left": "p%d_left",
													"right": "p%d_right",
													"up": "p%d_up",
													"down": "p%d_down",
													"start": "p%d_start",
													"table": "p%d_table",
												}
