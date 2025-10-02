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

const GAME_LIST_ITEM_CONTENT_MARGIN: int = 16
const GAME_LIST_ITEM_BG_UNSELECTED_COLOR: Color = Color(0.1, 0.1, 0.1, 0.5)
const GAME_LIST_ITEM_BG_SELECTED_COLOR: Color = Color(0.2, 0.2, 0.2, 0.8)
const GAME_LIST_ITEM_TEXT_UNSELECTED_COLOR: Color = Color(1, 1, 1, 0.5)
const GAME_LIST_ITEM_TEXT_SELECTED_COLOR: Color = Color(1, 1, 1, 1)

const OVERLAY_BASE_WIDTH: int = 200
const OVERLAY_BASE_HEIGHT: int = 1440
const IN_GAME_OVERLAY_DELAY_SEC: float = 3.0
const IN_GAME_OVERLAY_DISPLAY_SEC: float = 5.0

const GAME_LAUNCH_TIMEOUT_SEC: float = 10.0
const ERROR_DISPLAY_TIMEOUT_SEC: float = 5.0