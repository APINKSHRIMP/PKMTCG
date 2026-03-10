extends Control

# Variables to store data
var opponent_data: Dictionary
var player_data: Dictionary
var animation_duration: float = 5
var main_match_scene: PackedScene
var main_match_instance: Node

# References to nodes (these get populated when the scene loads)
@onready var background = $match_intro_background
@onready var player_sprite = $PLAYER/player_sprite
@onready var player_name_label = $PLAYER/player_name
@onready var player_deck_label = $PLAYER/player_deck_name
@onready var opponent_sprite = $OPPONENT/opponent_sprite
@onready var opponent_name_label = $OPPONENT/opponent_name
@onready var opponent_deck_label = $OPPONENT/opponent_deck_name
@onready var audio_player = AudioStreamPlayer.new()

# Called when the scene enters the scene tree
func _ready() -> void:
	# Step 1: Load opponent and player data
	load_opponent_data("Bug_Catcher_Alex")
	load_player_data()
	
	main_match_scene = load("res://gdscenes/MatchStart.tscn")
	main_match_instance = main_match_scene.instantiate()  # Create it now
	
	# Step 2: Update UI with loaded data
	update_ui_with_data()
	
	# Step 3: Load and play sound effect
	play_battle_start_sound()
	
	# Step 4: Preload the main match scene in the background
	main_match_scene = load("res://gdscenes/MatchStart.tscn")
	
	# Step 5: Run animations for 6 seconds
	animate_intro()

func _input(event: InputEvent) -> void:
	
	# Press the escape key to quit the game
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().quit()
	

# Step 1: Load opponent data from JSON
func load_opponent_data(trainer_name: String) -> void:
	var file = FileAccess.open("res://opponentdata/opponents_base1.json", FileAccess.READ)
	if file == null:
		print("Error loading opponent file")
		return
	
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	if error != OK:
		print("JSON parse error")
		return
	
	var opponents = json.data["opponents"]
	for opponent in opponents:
		if opponent.get("name") == trainer_name:
			opponent_data = opponent
			GameDataManager.opponent_data = opponent_data
			return
	
	print("Opponent with deck ", trainer_name, " not found")

# Step 1b: Load player data from JSON
func load_player_data() -> void:
	var file = FileAccess.open("res://playerdata/player_data.json", FileAccess.READ)
	if file == null:
		print("Error loading player file")
		return
	
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	if error != OK:
		print("JSON parse error for player data")
		return
	
	# JSON data is a single object at the root level
	player_data = json.data
	GameDataManager.player_data = player_data

# Step 2: Update UI labels and sprites with loaded data
func update_ui_with_data() -> void:
	# Update opponent data
	if opponent_data.has("name"):
		var opponent_name_no_underscores = opponent_data["name"].replace("_"," ")
		opponent_name_label.text = opponent_name_no_underscores
	if opponent_data.has("deck"):
		var opponent_deck_no_underscores = opponent_data["deck"].replace("_"," ")
		opponent_deck_label.text = opponent_deck_no_underscores
	
	# Load opponent sprite from file path
	if opponent_data.has("battle_sprite"):
		var opponent_sprite_path = "res://gameimageassets/npcs/in_battle/" + opponent_data["battle_sprite"].to_lower() + ".png"
		var opponent_texture = load(opponent_sprite_path)
		if opponent_texture:
			opponent_sprite.texture = opponent_texture
		else:
			print("Could not load opponent sprite: ", opponent_sprite_path)
	
	# Update player data
	if player_data.has("name"):
		var player_name_no_underscores = player_data["name"].replace("_"," ")
		player_name_label.text = player_name_no_underscores
	if player_data.has("deck"):
		var player_deck_no_underscores = player_data["deck"].replace("_"," ")
		player_deck_label.text = player_deck_no_underscores
	
	# Load player sprite from file path
	if player_data.has("battle_sprite"):
		var player_sprite_path = "res://gameimageassets/playersprites/in_battle/" + player_data["battle_sprite"].to_lower() + ".png"
		var player_texture = load(player_sprite_path)
		if player_texture:
			player_sprite.texture = player_texture
			player_sprite.flip_h = true
		else:
			print("Could not load player sprite: ", player_sprite_path)

# Step 3: Load and play battle start sound
func play_battle_start_sound() -> void:
	var audio_path = "res://audio/sfx/battle_start.ogg"
	var audio_stream = load(audio_path)
	
	if audio_stream:
		audio_player.stream = audio_stream
		add_child(audio_player)
		audio_player.play()
	else:
		print("Could not load audio: ", audio_path)

# Step 4: Animate sprites, text, and background
func animate_intro() -> void:
	# Create a Tween - Godot's animation system
	# Tweens let you animate properties smoothly over time
	var tween = create_tween()
	
	# Set the tween to run for the animation duration (6 seconds)
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.set_parallel(true)  # Run all animations at the same time
	
	# Animate player sprite moving left 100 pixels
	tween.tween_property(player_sprite, "position:x", player_sprite.position.x - 100, animation_duration)
	
	# Animate opponent sprite moving right 100 pixels
	tween.tween_property(opponent_sprite, "position:x", opponent_sprite.position.x + 100, animation_duration)
	
	# Animate player name and deck labels moving up 50 pixels
	tween.tween_property(player_name_label, "position:y", player_name_label.position.y - 50, animation_duration)
	tween.tween_property(player_deck_label, "position:y", player_deck_label.position.y - 50, animation_duration)
	
	# Animate opponent name and deck labels moving down 50 pixels
	tween.tween_property(opponent_name_label, "position:y", opponent_name_label.position.y + 50, animation_duration)
	tween.tween_property(opponent_deck_label, "position:y", opponent_deck_label.position.y + 50, animation_duration)
	
	# Animate background growing 5% (scale from 1.0 to 1.05)
	tween.tween_property(background, "scale", Vector2(1.15, 1.15), animation_duration)
	
	# When animation completes, transition to main match scene
	await tween.finished
	transition_to_main_match()

func transition_to_main_match() -> void:
	# Fade out the intro
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	await tween.finished
	
	# Add the main match instance to the scene tree
	get_tree().root.add_child(main_match_instance)
	get_tree().set_current_scene(main_match_instance)
	
	# Hide and remove the intro
	queue_free()
