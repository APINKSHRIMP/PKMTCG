class_name card_object

# The card's unique identifier (e.g., "Base1-1")
var uid: String

# The card's metadata from JSON
var metadata: Dictionary

# attached cards tracking
var attached_energies: Array = []
var attached_pre_evolutions: Array = []
var attached_cards: Array = [] # This is a generic catch all for tools, special cards, attached pokemon etc

# Tracks the location of the card in player/opponents control.
var current_location: String = "deck"  # "hand", "deck", "bench", "discard", etc.

# Tracks whether this pokemon was placed on the field during the current turn
var placed_on_field_this_turn: bool = false

# self metadata addition to track hp damage
var current_hp: int = 0

# Status condition tracking
var special_condition: String = ""
var is_poisoned: bool = false
var poison_damage: int = 10
var is_burned: bool = false
var is_blind: bool = false
var has_no_damage: bool = false
var is_invincible: bool = false
var has_destiny_bond: bool = false

# Constructor - initialize the card with a UID and load its metadata
func _init(card_uid: String, card_metadata: Dictionary) -> void:
	uid = card_uid
	metadata = card_metadata
	
	# Initialize current HP to max HP (from metadata)
	if metadata.has("hp"):
		current_hp = int(metadata["hp"])
	else:
		current_hp = 0
