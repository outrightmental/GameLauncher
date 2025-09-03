extends Control

@onready var title_label: Label = $RichTextLabel

var game: GameLibrary.Entry

func setup(entry: GameLibrary.Entry) -> void:
	game = entry
	var developers: String = ""
	if game.developers.size() > 0:
		developers = "by %s" % ", ".join(game.developers)
	var genres: String = ""
	if game.genres.size() > 0:
		genres = "Genres: %s" % ", ".join(game.genres)
	var players: String = ""
	if game.players > 0:
		players = "Players: %d" % game.players
	var description: String = ""
	if game.description != "":
		description = "\n\n%s" % game.description
	title_label.bbcode_text = "[b]%s[/b]\n%s\n%s%s" % [game.title, developers, genres, players, description]
	title_label.scroll_to_line(0)
	
