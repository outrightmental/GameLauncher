class_name GameListItem
extends Control

@onready var text_label: RichTextLabel = $PanelContainer/RichTextLabel
@onready var background_color: ColorRect = $BackgroundColor

var game: GameLibrary.Entry


func setup(entry: GameLibrary.Entry) -> void:
	game = entry


func _ready() -> void:
	text_label.bbcode_text = "[b]%s[/b]\nby %s\n%s" % [game.title, ", ".join(game.developers), game.description]
	set_selected(false)


func set_selected(selected: bool) -> void:
	var bg_color: Color   = Constants.GAME_LIST_ITEM_BG_SELECTED_COLOR if selected else Constants.GAME_LIST_ITEM_BG_UNSELECTED_COLOR
	var text_color: Color = Constants.GAME_LIST_ITEM_TEXT_SELECTED_COLOR if selected else Constants.GAME_LIST_ITEM_TEXT_UNSELECTED_COLOR
	background_color.color = bg_color
	text_label.set("theme_override_colors/default_color", text_color)
