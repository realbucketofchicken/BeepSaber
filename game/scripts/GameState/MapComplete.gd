extends GameState
class_name GameStateMapComplete

func _ready(game: BeepSaber_Game) -> void:
	game.endscore.set_buttons_disabled(false)
	game.main_menu._hide()
	game.settings_canvas._hide()
	game.show_MapSourceDialogs(false)
	game.endscore._show()
	game.pause_menu._hide()
	game.highscore_canvas._hide()
	game.name_selector_canvas._hide()
	game.left_saber._hide()
	game.right_saber._hide()
	game.multiplier_label.visible = false
	game.point_label.visible = false
	game.percent_indicator.visible = false
	game.track.visible = false
	game.left_ui_raycast.visible = true
	game.right_ui_raycast.visible = true
	game.highscore_keyboard._hide()
	game.online_search_keyboard._hide()
