extends GameState
class_name GameStateNewHighScore

func _ready(game: BeepSaber_Game) -> void:
	# populate highscore panel with records
	game.highscore_panel.load_highscores(
		Map.current_info,Map.current_difficulty.difficulty_rank)
	
	game.endscore.set_buttons_disabled(true)
	
	# fill name selector with most recent player names
	game._name_selector().clear_names()
	# WARNING: The get_all_player_names() method could become
	# costly for a very large highscore database (ie. many
	# songs and many difficulties). If that ever becomes a
	# concern, we may want to consider caching a list of the
	# N most recent players instead.
	for player_name in Highscores.get_all_player_names():
		game._name_selector().add_name(player_name)
	
	game.main_menu._hide()
	game.settings_canvas._hide()
	game.show_MapSourceDialogs(false)
	game.endscore._show()
	game.pause_menu._hide()
	game.highscore_canvas._show()
	game.name_selector_canvas._show()
	game.left_saber._hide()
	game.right_saber._hide()
	game.multiplier_label.visible = false
	game.point_label.visible = false
	game.percent_indicator.visible = false
	game.track.visible = false
	game.left_ui_raycast.visible = true
	game.right_ui_raycast.visible = true
	game.highscore_keyboard._show()
	game.online_search_keyboard._hide()
	game.set_colors_from_settings()
