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
var current_opponent_deck: String = ""

# The res:// path of the map level the player was on when they entered a battle.
# After the match outro finishes we transition back to this scene.
var return_map_scene_path: String = ""

# Progress tracking
var progress: Dictionary = {}

const PROGRESS_PATH = "res://playerdata/player_progress.json"
const COIN_LIST_PATH = "res://playerdata/player_owned_coin_list.txt"
const COSTUME_LIST_PATH = "res://playerdata/player_owned_costumes.txt"

func _ready():
	load_progress()

# ============================================================
# PROGRESS FILE I/O
# ============================================================

func load_progress():
	if FileAccess.file_exists(PROGRESS_PATH):
		var file = FileAccess.open(PROGRESS_PATH, FileAccess.READ)
		var text = file.get_as_text()
		file.close()
		var parsed = JSON.parse_string(text)
		if parsed != null:
			progress = parsed
		else:
			progress = {"opponents_beaten": [], "cash": 1000}
	else:
		progress = {"opponents_beaten": [], "cash": 1000}
		save_progress()
	
	# Ensure cash field exists for saves created before this update
	if not progress.has("cash"):
		progress["cash"] = 1000
		save_progress()

func save_progress():
	var file = FileAccess.open(PROGRESS_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(progress, "\t"))
	file.close()

# ============================================================
# CASH
# ============================================================

func get_cash() -> int:
	return progress.get("cash", 1000)

func add_cash(amount: int) -> void:
	progress["cash"] = get_cash() + amount
	save_progress()

# ============================================================
# OPPONENT TRACKING
# ============================================================

func has_beaten_opponent(opponent_name: String) -> bool:
	return opponent_name in progress.get("opponents_beaten", [])

func mark_opponent_beaten(opponent_name: String):
	if not has_beaten_opponent(opponent_name):
		progress["opponents_beaten"].append(opponent_name)
		save_progress()

# ============================================================
# COIN COLLECTION
# ============================================================

func add_coin_to_collection(coin_name: String):
	var existing_text = ""
	if FileAccess.file_exists(COIN_LIST_PATH):
		var file = FileAccess.open(COIN_LIST_PATH, FileAccess.READ)
		existing_text = file.get_as_text()
		file.close()
	
	var coin_filename = coin_name + ".png"
	
	if coin_filename in existing_text:
		return
	
	var file = FileAccess.open(COIN_LIST_PATH, FileAccess.WRITE)
	var trimmed = existing_text.strip_edges()
	if trimmed.length() > 0:
		file.store_string(trimmed + "\n" + coin_filename + "\n")
	else:
		file.store_string(coin_filename + "\n")
	file.close()

func has_coin(coin_name: String) -> bool:
	if not FileAccess.file_exists(COIN_LIST_PATH):
		return false
	var file = FileAccess.open(COIN_LIST_PATH, FileAccess.READ)
	var text = file.get_as_text()
	file.close()
	var coin_filename = coin_name + ".png"
	return coin_filename in text

# ============================================================
# COSTUME COLLECTION
# ============================================================

func has_costume(battle_sprite: String) -> bool:
	if not FileAccess.file_exists(COSTUME_LIST_PATH):
		return false
	var file = FileAccess.open(COSTUME_LIST_PATH, FileAccess.READ)
	var text = file.get_as_text()
	file.close()
	var costume_filename = battle_sprite.to_lower() + ".png"
	return costume_filename in text

func add_costume_to_collection(battle_sprite: String) -> void:
	var existing_text = ""
	if FileAccess.file_exists(COSTUME_LIST_PATH):
		var file = FileAccess.open(COSTUME_LIST_PATH, FileAccess.READ)
		existing_text = file.get_as_text()
		file.close()
	
	var costume_filename = battle_sprite.to_lower() + ".png"
	
	if costume_filename in existing_text:
		return
	
	var file = FileAccess.open(COSTUME_LIST_PATH, FileAccess.WRITE)
	var trimmed = existing_text.strip_edges()
	if trimmed.length() > 0:
		file.store_string(trimmed + "\n" + costume_filename + "\n")
	else:
		file.store_string(costume_filename + "\n")
	file.close()
