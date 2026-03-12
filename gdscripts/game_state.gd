extends Node

# ============================================================
# GAME STATE - Autoload Singleton
# ============================================================
# This script persists between scene changes. It holds data
# that needs to survive when switching from WorldMap → Match
# and back. Register this as an Autoload in Project Settings.
# ============================================================

# Data passed between scenes during a match
var current_opponent_name: String = ""
var returning_from_battle: bool = false
var battle_result: String = ""  # "win" or "loss"
var player_position: Vector2 = Vector2.ZERO

# Progress tracking
var progress: Dictionary = {}

const PROGRESS_PATH = "res://playerdata/player_progress.json"
const COIN_LIST_PATH = "res://playerdata/player_owned_coin_list.txt"

var current_opponent_deck: String = ""

func _ready():
	load_progress()

# --- Progress File I/O ---

func load_progress():
	if FileAccess.file_exists(PROGRESS_PATH):
		var file = FileAccess.open(PROGRESS_PATH, FileAccess.READ)
		var text = file.get_as_text()
		file.close()
		var parsed = JSON.parse_string(text)
		if parsed != null:
			progress = parsed
		else:
			progress = {"opponents_beaten": []}
	else:
		progress = {"opponents_beaten": []}
		save_progress()

func save_progress():
	var file = FileAccess.open(PROGRESS_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(progress, "\t"))
	file.close()

# --- Opponent Tracking ---

func has_beaten_opponent(opponent_name: String) -> bool:
	return opponent_name in progress.get("opponents_beaten", [])

func mark_opponent_beaten(opponent_name: String):
	if not has_beaten_opponent(opponent_name):
		progress["opponents_beaten"].append(opponent_name)
		save_progress()

# --- Coin Collection ---

func add_coin_to_collection(coin_name: String):
	var existing_text = ""
	if FileAccess.file_exists(COIN_LIST_PATH):
		var file = FileAccess.open(COIN_LIST_PATH, FileAccess.READ)
		existing_text = file.get_as_text()
		file.close()
	
	# Build the full filename (e.g. "coin_gyarados_blue.png")
	var coin_filename = coin_name + ".png"
	
	# Don't add duplicates
	if coin_filename in existing_text:
		return
	
	# Append the new coin
	var file = FileAccess.open(COIN_LIST_PATH, FileAccess.WRITE)
	var trimmed = existing_text.strip_edges()
	if trimmed.length() > 0:
		file.store_string(trimmed + "\n" + coin_filename + "\n")
	else:
		file.store_string(coin_filename + "\n")
	file.close()
