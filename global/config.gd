extends Node

# Paths to manifest files
const MANIFEST_EXTERNAL_PATH: String = "manifest.json"
const MANIFEST_INTERNAL_PATH: String = "res://assets/manifest.json"
# Formatting template for player input
const player_input_mapping_format: Dictionary = {
													"left": "p%d_left",
													"right": "p%d_right",
													"up": "p%d_up",
													"down": "p%d_down",
													"start": "p%d_start",
													"table": "p%d_table",
												}
