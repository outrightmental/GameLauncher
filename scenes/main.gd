extends Control

@onready var show_error_container: Control = $ShowError
@onready var show_error_console: RichTextLabel = $ShowError/Console
@onready var show_update_container: PanelContainer = $ShowUpdate
@onready var show_update_progress_bar: ProgressBar = $ShowUpdate/VBoxContainer/ProgressBar
@onready var show_update_console: RichTextLabel = $ShowUpdate/VBoxContainer/Console
@onready var show_games_container: PanelContainer = $ShowGames
@onready var show_games_list: VBoxContainer = $ShowGames/ScrollContainer/VBoxContainer
@onready var show_games_scroll: ScrollContainer = $ShowGames/ScrollContainer
@onready var show_launching_container: Control = $ShowLaunching
const game_list_item_scene: PackedScene         = preload("res://scenes/game_list_item.tscn")
var game_list_items: Array[GameListItem]        = []
var game_list_selected_index: int               = 0
var running_pid: int                            = -1
enum State {
	INITIALIZING,
	MANIFEST_LOADED,
	MANIFEST_ERROR,
	SHOW_GAME_LIBRARY,
	GAME_UPDATE_ERROR,
	RUNNING_GAME,
	ERROR_LAUNCHING_GAME,
}
var state: State = State.INITIALIZING
signal _on_state_changed()

# On initialization, connect signals
func _init() -> void:
	GameLibrary.manifest_error.connect(_on_manifest_error)
	GameLibrary.manifest_loaded.connect(_on_manifest_loaded)
	GameUpdater.game_update_error.connect(_on_game_update_error)
	GameUpdater.game_update_message.connect(_on_game_update_message)
	GameUpdater.game_update_progress.connect(_on_game_update_progress)
	GameUpdater.all_games_updated.connect(_on_all_games_updated)


func _ready() -> void:
	show_error_container.hide()
	show_update_container.hide()
	show_games_container.hide()
	show_launching_container.hide()
	
	
func _update_state(new_state: State) -> void:
	if state != new_state:
		state = new_state
		_on_state_changed.emit()


# Handle input events
func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("p1_left") or Input.is_action_just_pressed("p2_left"):
		_move_selection(-1)
	elif Input.is_action_just_pressed("p1_right") or Input.is_action_just_pressed("p2_right"):
		_move_selection(1)
	elif Input.is_action_just_pressed("p1_start") or Input.is_action_just_pressed("p2_start"):
		if game_list_items.size() > 0:
			var selected_game: GameLibrary.Entry = game_list_items[game_list_selected_index].game
			_launch_game(selected_game)


# Launch the selected game and store the process ID
func _launch_game(game: GameLibrary.Entry) -> void:
	if state == State.RUNNING_GAME:
		print("A game is already running with PID: %d" % running_pid)
		return
	_update_state(State.RUNNING_GAME)
	show_games_container.hide()
	show_launching_container.show()
	# Construct the executable path
	var executable_path: String = GameLibrary.manifest.directory.path_join(game.repo_owner).path_join(game.repo_name).path_join(game.executable)
	print("Launching game: %s" % executable_path)
	running_pid = OS.create_process(executable_path, [])
	if running_pid == -1:
		_show_error("Failed to launch game: %s" % game.title)
		_update_state(State.ERROR_LAUNCHING_GAME)
		return
	print("Launched game with PID: %d" % running_pid)
	# Wait N seconds
	await Util.delay(Constants.GAME_LAUNCH_TIMEOUT_SEC)
	show_games_container.show()
	show_launching_container.hide()
	_update_state(State.SHOW_GAME_LIBRARY)


# After the manifest is loaded, update all games
func _on_manifest_loaded() -> void:
	_update_state(State.MANIFEST_LOADED)
	GameUpdater.update_all_games()


# After all games are updated, display the collection and game details
func _on_all_games_updated() -> void:
	_update_state(State.SHOW_GAME_LIBRARY)
	if show_update_container.is_visible():
		show_update_container.hide()
	if not show_games_container.is_visible():
		show_games_container.show()
	# for each game in the library manifest, add an item to the game list
	for game in GameLibrary.manifest.games:
		var item: Control = game_list_item_scene.instantiate()
		item.setup(game)
		game_list_items.append(item)
		show_games_list.add_child(item)
	_update_selected()


# Handle manifest loading errors
func _on_manifest_error(message: String) -> void:
	_update_state(State.MANIFEST_ERROR)
	_show_error("[Manifest] %s" % message)


# Handle manifest loading errors
func _on_game_update_error(message: String) -> void:
	_update_state(State.GAME_UPDATE_ERROR)
	_show_error("[GameUpdate] %s" % message)


# Display manifest errors in a modal dialog
func _show_error(message: String) -> void:
	show_error_console.text += message + "\n"
	if not show_error_container.is_visible():
		show_error_container.show()
		await Util.delay(Constants.ERROR_DISPLAY_TIMEOUT_SEC)
		show_error_container.hide()
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


# Move the selection up or down in the game list
func _move_selection(direction: int) -> void:
	if game_list_items.size() == 0:
		return
	game_list_selected_index = wrap(game_list_selected_index +direction, 0, game_list_items.size())
	show_games_scroll.scroll_vertical = int(game_list_items[game_list_selected_index].global_position.y)
	_update_selected()


# Update the selected game in the list
func _update_selected() -> void:
	for i in game_list_items.size():
		game_list_items[i].set_selected(i == game_list_selected_index)
