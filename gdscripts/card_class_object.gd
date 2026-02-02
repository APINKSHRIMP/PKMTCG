class_name card_object

# The card's unique identifier (e.g., "Base1-1")
var uid: String

# The card's metadata from JSON
var metadata: Dictionary

# State tracking
var attached_energies: Array = []
var current_location: String = "deck"  # "hand", "deck", "bench", "discard", etc.

# Constructor - initialize the card with a UID and load its metadata
func _init(card_uid: String, card_metadata: Dictionary) -> void:
	uid = card_uid
	metadata = card_metadata
