extends Node2D

# ============================================================
# WORLD MAP - Main Controller
# ============================================================
# Loads opponents from JSON, spawns them with movement patterns,
# manages the message box UI, and handles match transitions.
# ============================================================

@onready var player: CharacterBody2D = $Player
@onready var opponents_container: Node2D = $OPPONENTS
@onready var ui_layer: CanvasLayer = $UILAYER

@onready var audio_player = AudioStreamPlayer.new()

# The opponent scene - preloaded so we can instantiate copies
var opponent_scene = preload("res://gdscenes/Opponent.tscn")

# Currently interacting opponent reference
var current_opponent: Node = null

# Message box UI nodes (built in _ready)
var message_panel: PanelContainer
var message_label: Label
var yes_button: Button
var no_button: Button
var ok_button: Button
var button_container: HBoxContainer

# ============================================================
# OPPONENT PLACEMENTS
# ============================================================
# Define where each opponent goes on THIS map and how they move.
# "pattern" options: "idle_random", "idle_cycle", "patrol_line", "patrol_square"
# "patrol_axis" options: "horizontal", "vertical" (for patrol_line only)
# Adjust positions to fit your actual map layout.
# "idle_random" — stands still, randomly faces up/down/left/right every 2–5 seconds
# "idle_cycle" — stands still, plays the walk_down animation on loop (good for swimmers "treading water")
# "patrol_line" — walks back and forth. Set "patrol_axis" to "horizontal" or "vertical", and "patrol_distance" to how far they walk (in pixels) before turning around
# "patrol_square" — walks in a square loop (down → right → up → left). Set "patrol_distance" to the length of each side
# ============================================================
var opponent_placements = [
	{
		"name": "Fisherman_John",
		"position": Vector2(1100, 720),
		"pattern": "idle_random",
	},
	{
		"name": "Bug_Catcher_Alex",
		"position": Vector2(1000, 350),
		"pattern": "patrol_line",
		"patrol_distance": 120,
		"patrol_axis": "horizontal",
	},
	{
		"name": "Swimmer_Jordan",
		"position": Vector2(400, 800),
		"pattern": "idle_cycle",
	},
]

# ============================================================
# INITIALIZATION
# ============================================================

func _ready():
	add_child(audio_player)

	var audio_stream = load("res://audio/bgm/beach_bgm.ogg")
	audio_player.stream = audio_stream
	audio_player.bus = "Master"
	audio_player.stream.loop = true
	audio_player.play()

	_build_message_box()
	_load_and_spawn_opponents()
	
	# Connect to the player's interact signal
	player.interact_pressed.connect(_on_player_interact)
	
	# If returning from a battle, show the result message
	if GameState.returning_from_battle:
		_handle_battle_return()

# ============================================================
# OPPONENT SPAWNING
# ============================================================

func _load_and_spawn_opponents():
	# Read the opponent JSON file
	var file = FileAccess.open("res://opponentdata/opponents_base1.json", FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	
	for placement in opponent_placements:
		# Find this opponent's data in the JSON
		var opp_data = _find_opponent_in_json(data, placement["name"])
		if opp_data == null:
			push_error("Opponent not found in JSON: " + placement["name"])
			continue
		
		# Create an instance of the Opponent scene
		var opp = opponent_scene.instantiate()
		
		# Populate identity data from JSON
		opp.opponent_name = opp_data["name"]
		opp.overworld_sprite = opp_data["overworld_sprite"]
		#opp.battle_sprite = opp_data["battle_sprite"]
		opp.music = opp_data["music"]
		opp.deck = opp_data["deck"]
		opp.meet_text = opp_data["meet_text"]
		opp.rematch_text = opp_data["rematch_text"]
		opp.first_win_text = opp_data["first_win_text"]
		opp.rematch_win_text = opp_data["rematch_win_text"]
		opp.loss_text = opp_data["loss_text"]
		opp.coin_reward = opp_data["coin_reward"]
		opp.cash_reward = opp_data["cash_reward"]
		
		# Set position and movement from placement config
		opp.position = placement["position"]
		opp.movement_pattern = placement.get("pattern", "idle_random")
		opp.patrol_distance = placement.get("patrol_distance", 100.0)
		opp.patrol_speed = placement.get("patrol_speed", 60.0)
		opp.patrol_axis = placement.get("patrol_axis", "horizontal")
		
		# Add to the Opponents container node
		opponents_container.add_child(opp)

func _find_opponent_in_json(data: Dictionary, opp_name: String):
	for opp in data["opponents"]:
		if opp["name"] == opp_name:
			return opp
	return null

# ============================================================
# MESSAGE BOX UI (built programmatically)
# ============================================================

func _build_message_box():
	# --- Outer panel ---
	message_panel = PanelContainer.new()
	message_panel.visible = false
	
	# Position and size the panel at the bottom of the screen
	message_panel.offset_left = 200
	message_panel.offset_top = 800
	message_panel.offset_right = 1720
	message_panel.offset_bottom = 1020
	
	# Style the panel with a dark background
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.2, 0.95)
	style.border_color = Color(0.8, 0.8, 1.0, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(20)
	message_panel.add_theme_stylebox_override("panel", style)
	
	# --- Inner layout ---
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	message_panel.add_child(vbox)
	
	# Message text label
	message_label = Label.new()
	message_label.text = ""
	message_label.add_theme_font_size_override("font_size", 28)
	message_label.add_theme_color_override("font_color", Color.WHITE)
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(message_label)
	
	# Button row
	button_container = HBoxContainer.new()
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	button_container.add_theme_constant_override("separation", 40)
	vbox.add_child(button_container)
	
	# Yes button
	yes_button = Button.new()
	yes_button.text = "  Yes  "
	yes_button.add_theme_font_size_override("font_size", 24)
	yes_button.pressed.connect(_on_yes_pressed)
	button_container.add_child(yes_button)
	
	# No button
	no_button = Button.new()
	no_button.text = "  No  "
	no_button.add_theme_font_size_override("font_size", 24)
	no_button.pressed.connect(_on_no_pressed)
	button_container.add_child(no_button)
	
	# OK button (used for post-battle messages, hidden by default)
	ok_button = Button.new()
	ok_button.text = "  OK  "
	ok_button.add_theme_font_size_override("font_size", 24)
	ok_button.pressed.connect(_on_ok_pressed)
	ok_button.visible = false
	button_container.add_child(ok_button)
	
	# Add to the UI layer so it draws on top of everything
	ui_layer.add_child(message_panel)

func _show_message_with_choices(text: String):
	message_label.text = text
	yes_button.visible = true
	no_button.visible = true
	ok_button.visible = false
	message_panel.visible = true
	player.can_move = false

func _show_message_with_ok(text: String):
	message_label.text = text
	yes_button.visible = false
	no_button.visible = false
	ok_button.visible = true
	message_panel.visible = true
	player.can_move = false

func _hide_message():
	message_panel.visible = false
	player.can_move = true
	if current_opponent != null:
		current_opponent.resume_movement()
	current_opponent = null

# ============================================================
# INTERACTION FLOW
# ============================================================

func _on_player_interact(opponent: Node):
	if message_panel.visible:
		return
	
	current_opponent = opponent
	opponent.pause_and_face(player.position)
	var greeting = opponent.get_greeting_text()
	_show_message_with_choices(greeting)

func _on_yes_pressed():
	if current_opponent == null:
		return
	
	# Save player position so we can restore it on return
	GameState.player_position = player.position
	GameState.current_opponent_name = current_opponent.opponent_name
	GameState.current_opponent_deck = current_opponent.deck
	GameState.returning_from_battle = false
	
	
	_hide_message()
	
	# ---------------------------------------------------------
	# SCENE TRANSITION TO MATCH
	# ---------------------------------------------------------
	# Change this path to your actual match intro scene.
	# Your match intro script should read:
	#   GameState.current_opponent_name
	# to load the correct opponent deck and sprite.
	#
	# When the match ends, your match script should set:
	#   GameState.battle_result = "win" or "loss"
	#   GameState.returning_from_battle = true
	# then change scene back to WorldMap.
	# ---------------------------------------------------------
	get_tree().change_scene_to_file("res://gdscenes/MatchIntro.tscn")

func _on_no_pressed():
	_hide_message()

func _on_ok_pressed():
	_hide_message()

# ============================================================
# POST-BATTLE HANDLING
# ============================================================

func format_coin_name(raw: String) -> String:
	var name = raw.replace("coin_", "").replace(".png", "")
	var colors = ["red", "blue", "gold", "silver", "green", "black", "purple", "pink", "brown"]
	var parts = name.split("_")
	var color = ""
	var pokemon_parts = []
	
	for part in parts:
		if part in colors:
			color = part
		else:
			pokemon_parts.append(part)
	
	return (color + " " + " ".join(pokemon_parts)).strip_edges()

func _handle_battle_return():
	# Find the opponent we just fought
	var fought_name = GameState.current_opponent_name
	var fought_opponent = null
	
	for opp in opponents_container.get_children():
		if opp.opponent_name == fought_name:
			fought_opponent = opp
			break
	
	if fought_opponent == null:
		GameState.returning_from_battle = false
		return
	
	var player_won = (GameState.battle_result == "win")
	var result_text = fought_opponent.get_result_text(player_won)
	
	if player_won:
		# First-time win: reward coin and mark as beaten
		if not GameState.has_beaten_opponent(fought_name):
			GameState.add_coin_to_collection(fought_opponent.coin_reward)
			var coin_friendly_name = format_coin_name(fought_opponent.coin_reward)
			result_text += "\n\nYou received a " + coin_friendly_name + " coin!"
		GameState.mark_opponent_beaten(fought_name)
	
	current_opponent = fought_opponent
	_show_message_with_ok(result_text)
	
	# Clean up the return state
	GameState.returning_from_battle = false
	GameState.battle_result = ""

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file("res://worldmap/mapscenes/World_Map.tscn")
