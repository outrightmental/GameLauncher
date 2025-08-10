extends Node

# --- Lifecycle -----------------------------------------------------------
signal action_pressed(player: int, action: String)     # e.g., "fire", "start"
signal action_released(player: int, action: String)
# --- Config --------------------------------------------------------------

# Names of input actions that are used in the Input Map
const INPUT_LEFT: String  = "left"
const INPUT_RIGHT: String = "right"
const INPUT_UP: String    = "up"
const INPUT_DOWN: String  = "down"
const INPUT_START: String = "start"
const INPUT_TABLE: String = "table"
# Formatting template for player input
const PLAYER_INPUT_MAPPING_FORMAT: Dictionary = {
													INPUT_LEFT: "p%d_left",
													INPUT_RIGHT: "p%d_right",
													INPUT_UP: "p%d_up",
													INPUT_DOWN: "p%d_down",
													INPUT_START: "p%d_start",
													INPUT_TABLE: "p%d_table",
												}
# Keyboard action names that already exist in your Input Map
var P1_KEYS := _compute_player_input_map(1)
var P2_KEYS := _compute_player_input_map(2)


func _compute_player_input_map(player: int) -> Dictionary:
	var input_mapping: Dictionary = {}
	# Set up input mapping for player
	for key in PLAYER_INPUT_MAPPING_FORMAT.keys():
		var action_name: String = PLAYER_INPUT_MAPPING_FORMAT[key] % player
		if InputMap.has_action(action_name):
			input_mapping[key] = action_name
		else:
			push_error("Input action not found: ", action_name)
	return input_mapping


func _input(event: InputEvent) -> void:
	# Keyboard: only for players that DON'T have a gamepad
	if event is InputEventKey and not event.is_echo():
		_handle_keyboard_action_event(1, event, P1_KEYS)
		_handle_keyboard_action_event(2, event, P2_KEYS)


# Map key events to abstract actions
func _handle_keyboard_action_event(player: int, event: InputEventKey, keys: Dictionary) -> void:
	for key in keys.keys():
		if event.pressed:
			if event.is_action_pressed(keys[key]):
				action_pressed.emit( player, key)
		else:
			if event.is_action_released(keys[key]):
				action_released.emit( player, key)
