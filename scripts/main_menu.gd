extends Control

@onready var start_button = $VBoxContainer/start_game_button
@onready var settings_button = $VBoxContainer/settings_button
@onready var credits_button = $VBoxContainer/credits_button
@onready var exit_button = $VBoxContainer/exit_button

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_ui.tscn")  # Update path as needed

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/settings_scene.tscn")  # Update path as needed

func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/credits_scene.tscn")  # Update path as needed

func _on_exit_pressed() -> void:
	get_tree().quit()
