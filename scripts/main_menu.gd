extends Control

@onready var start_button = $VBoxContainer/start_game_button
@onready var settings_button = $VBoxContainer/settings_button
@onready var info_button = $VBoxContainer/info_button
@onready var exit_button = $VBoxContainer/exit_button

var clicks = 0
var times_through = 0

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	info_button.pressed.connect(_on_info_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_ui.tscn")  # Update path as needed

func _on_settings_pressed() -> void:
	# get_tree().change_scene_to_file("res://scenes/settings_scene.tscn")  # Update path as needed
	clicks += 1
	if clicks >= 100 && times_through < 1:
		$settings_not_ready.dialog_text = "Knock that shit off, it's disabled for now."
		$settings_not_ready.popup_centered()
		clicks = 0
		times_through += 1
	elif clicks >= 100 && times_through == 1:
		$settings_not_ready.dialog_text = "Alright jerk I'm turning this button off...nothing else is gana happen."
		$settings_not_ready.popup_centered()
	else:
		clicks = 101
		times_through = 2

func _on_info_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/info_scene.tscn")  # Update path as needed

func _on_exit_pressed() -> void:
	get_tree().quit()
