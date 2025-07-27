extends Control

@onready var unicorn_toggle = $settings_container/unicorn_row/unicorn_toggle
@onready var smoothing_toggle = $settings_container/smoothing_row/smoothing_toggle
@onready var restore_button = $settings_container/restore_button
@onready var back_button = $back_button

func _ready() -> void:
	_set_toggles()
	unicorn_toggle.toggled.connect(_on_unicorn_toggled)
	smoothing_toggle.toggled.connect(_on_smoothing_toggled)
	restore_button.pressed.connect(_on_restore_defaults_pressed)
	back_button.pressed.connect(_on_back_pressed)

func _on_unicorn_toggled(button_pressed: bool) -> void:
	# Toggle unicorn mode (replace with real logic)
	GameSettings.unicorn_mode = button_pressed

func _on_smoothing_toggled(button_pressed: bool) -> void:
	# Toggle smoothing (placeholder)
	GameSettings.graph_smoothing = button_pressed

func _on_restore_defaults_pressed() -> void:
	unicorn_toggle.button_pressed = false
	smoothing_toggle.button_pressed = false
	GameSettings.reset_to_defaults()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	
func _set_toggles() -> void:
	unicorn_toggle.button_pressed = GameSettings.unicorn_mode
	smoothing_toggle.button_pressed = GameSettings.graph_smoothing
