extends Control

@onready var show_error_container: Control = $ShowError
@onready var show_error_console: RichTextLabel = $ShowError/Console
@onready var show_update_container: PanelContainer = $ShowUpdate
@onready var show_update_progress_bar: ProgressBar = $ShowUpdate/VBoxContainer/ProgressBar
@onready var show_update_console: RichTextLabel = $ShowUpdate/VBoxContainer/Console
@onready var show_games_container: PanelContainer = $ShowGames
@onready var show_games_list: VBoxContainer = $ShowGames/ScrollContainer/VBoxContainer
@onready var show_games_scroll: ScrollContainer = $ShowGames/ScrollContainer
const game_list_item_scene: PackedScene         = preload("res://scenes/game_list_item.tscn")
const in_game_overlay_scene: PackedScene        = preload("res://scenes/in_game_overlay.tscn")
var game_list_items: Array[GameListItem]        = []
var game_list_selected_index: int               = 0
var overlay_window: Window                      = null


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


# Handle input events
func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("p1_left") or Input.is_action_just_pressed("p2_left"):
		_move_selection(-1)
	elif Input.is_action_just_pressed("p1_right") or Input.is_action_just_pressed("p2_right"):
		_move_selection(1)
	elif Input.is_action_just_pressed("p1_start") or Input.is_action_just_pressed("p2_start"):
		if game_list_items.size() > game_list_selected_index:
			_launch_game(game_list_items[game_list_selected_index].game)


# After the manifest is loaded, update all games
func _on_manifest_loaded() -> void:
	GameUpdater.update_all_games()


# After all games are updated, display the collection and game details
func _on_all_games_updated() -> void:
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
	_show_error("[Manifest] %s" % message)


# Handle manifest loading errors
func _on_game_update_error(message: String) -> void:
	_show_error("[GameUpdate] %s" % message)


# Display manifest errors in a modal dialog
func _show_error(message: String) -> void:
	show_error_console.text += message + "\n"
	if not show_error_container.is_visible():
		show_error_container.show()
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


# Launch the selected game
func _launch_game(game: GameLibrary.Entry) -> void:
	var executable_path: String = GameLibrary.manifest.directory.path_join(game.repo_owner).path_join(game.repo_name).path_join(game.executable)
	print("Launching game: %s" % executable_path)
	# TODO launch game after we figure out the overlay stuff
	var err = OS.shell_open(executable_path)
	if err != OK:
		_show_error("Failed to launch game: %s" % executable_path)
	await get_tree().create_timer(Constants.IN_GAME_OVERLAY_DELAY_SEC).timeout
	_show_in_game_overlay()
	await get_tree().create_timer(Constants.IN_GAME_OVERLAY_DISPLAY_SEC).timeout
	_hide_in_game_overlay()


# Create a window with exit instructions
# FUTURE: spawn separate windows for left and right side of screen
func _show_in_game_overlay() -> void:
	_hide_in_game_overlay()
	var window_scale: float = float(DisplayServer.screen_get_size().y) / float(Constants.WINDOW_BASE_HEIGHT)
	# Create a new overlay window
	overlay_window       = Window.new()
	overlay_window.borderless = true
	overlay_window.transient = false
	overlay_window.unresizable = true
	overlay_window.wrap_controls = true
	overlay_window.transparent = true
	overlay_window.always_on_top = true
	overlay_window.size = Vector2(Constants.IN_GAME_OVERLAY_WIDTH * window_scale, DisplayServer.screen_get_size().y)
	overlay_window.position = Vector2(0, 0)
	# Determine scale relative to the base window size
	var content: Node = in_game_overlay_scene.instantiate()
	content.rotation_degrees = 90
	content.scale = Vector2(window_scale, window_scale)
	content.position = Vector2(Constants.IN_GAME_OVERLAY_WIDTH * window_scale, 0)
	overlay_window.add_child(content)
	call_deferred("add_child", overlay_window)

	
func _hide_in_game_overlay() -> void:
	if overlay_window != null:
		overlay_window.queue_free()
		overlay_window = null
