extends Panel

@export var beat_saver_panel: BeatSaverPanel

@onready var beat_saver_button := $Margin/VBox/Grid/BeatSaverButton as Button
@onready var beat_sage_button := $Margin/VBox/Grid/BeatSageButton as Button

func _ready() -> void:
	UI_AudioEngine.attach_children(self)
	# initialize items related to Beat Saver UI Dialog
	if is_instance_valid(beat_saver_panel):
		@warning_ignore("return_value_discarded")
		beat_saver_panel.visibility_changed.connect(
			_on_MapSourceUI_closed.bind(beat_saver_panel))
	else:
		vr.log_warning('_beat_saver_panel is null')
		beat_saver_button.disabled = true
		
	# initialize items related to Beat Sage UI Dialog
	if is_instance_valid(beat_saver_panel):
		@warning_ignore("return_value_discarded")
	else:
		vr.log_warning('_beat_sage_panel is null')
		beat_sage_button.disabled = true

# override hide() method to handle case where UI is inside a OQ_UI2DCanvas
func _hide() -> void:
	var parent_canvas: Node = self
	while parent_canvas != null:
		if parent_canvas is OQ_UI2DCanvas:
			(parent_canvas as OQ_UI2DCanvas).hide()
			break
		parent_canvas = parent_canvas.get_parent()
	
	if parent_canvas == null:
		self.visible = false

# override show() method to handle case where UI is inside a OQ_UI2DCanvas
func _show() -> void:
	var parent_canvas: Node = self
	while parent_canvas != null:
		if parent_canvas is OQ_UI2DCanvas:
			(parent_canvas as OQ_UI2DCanvas).show()
			break
		parent_canvas = parent_canvas.get_parent()
		
	if parent_canvas == null:
		self.visible = true

func _on_BeatSaverButton_pressed() -> void:
	beat_saver_panel._show()
	self._hide()

func _on_MapSourceUI_closed(ui_panel: Panel) -> void:
	if not ui_panel.visible:
		self._show()
