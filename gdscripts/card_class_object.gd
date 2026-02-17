class_name card_object

# The card's unique identifier (e.g., "Base1-1")
var uid: String

# The card's metadata from JSON
var metadata: Dictionary

# State tracking
var attached_energies: Array = []
var current_location: String = "deck"  # "hand", "deck", "bench", "discard", etc.

# Tracks whether this pokemon was placed on the field during the current turn
var placed_on_field_this_turn: bool = false

# self metadata addition to track hp damage
var current_hp: int = 0

# Constructor - initialize the card with a UID and load its metadata
func _init(card_uid: String, card_metadata: Dictionary) -> void:
	uid = card_uid
	metadata = card_metadata
	
	# Initialize current HP to max HP (from metadata)
	if metadata.has("hp"):
		current_hp = int(metadata["hp"])
	else:
		current_hp = 0
