extends Control

# Main function to get metadata of any card passed to it. Goes off UID to lookup JSON data in game file
func get_card_metadata(card_uid: String):
	
	# Check the UID to make sure it's valid and if not error out 
	var split_uid = card_uid.split("-")
	if split_uid.size() != 2:
		print("Invalid UID provided, UID:", card_uid)
		return
	
	# Card details will be for example "Base1-1" "EX2-2"
	var card_set = split_uid[0]
	
	# the json data is in the same folder as the cardimages
	var card_set_json_metadata_path = "res://cardimages/" + card_set + "/" + card_set + ".json"
	
	# Open and read the metadata file
	var metadata_file = FileAccess.open(card_set_json_metadata_path, FileAccess.READ)
	
	# Check to make sure the file can be opened and error if it can't then return null
	if metadata_file == null:
		print("Error: Could not open metadata file at: ", card_set_json_metadata_path)
		return null
	
	# If the card set can be found then open the data and parse the json
	var raw_json_card_set_text = metadata_file.get_as_text()
	metadata_file.close()
	
	# Parse the JSON
	var parsed_card_set_json = JSON.new()
	if parsed_card_set_json.parse(raw_json_card_set_text) != OK:
		print("Error: Failed to parse metadata JSON")
		return null
	
	# If the json was succesfully parsed we now have the whole card set metadata as a variable to read
	var card_set_data = parsed_card_set_json.data
	
	# Now loop through the entire card set data and find the specific card by UID
	for this_card in card_set_data:
		if this_card.get("id") == card_uid.to_lower():
			return this_card
	
	# If the card could not be found in this set then return null
	print("Card not found in metadata: ", card_uid)
	return null

# Main function to check if a card is a basic pokemon or not. Will return true or false
func is_basic_pokemon(card_uid: String) -> bool:
	# Get the full card metadata by running the card uid through the function called get card metadata
	var card_full_metadata = get_card_metadata(card_uid)
	# Make sure a card is actually returned succesfully
	if card_full_metadata == null:
		return false
	
	# Now the card metadata has been found save the super and sub type variables to check
	var main_card_type = card_full_metadata.get("supertype", "").to_lower()
	
	# If the card is a pokemon type then we finally check if it's basic or not
	if main_card_type == "pokémon":
		var card_subtypes_array = card_full_metadata.get("subtypes", [])
		
		# Now We need to make sure it is a BASIC and POKEMON (there exists BASIC ENERGY)
		for each_subtype in card_subtypes_array:
			var each_subtype_lower = each_subtype.to_lower()
			match each_subtype_lower:
				"basic", "baby":
					return true
				"stage 1", "stage 2", "stage1", "stage2":
					return false
	
	# If the above statements don't deem this a POKEMON card AND a BASIC card then return false
	return false

# Reusable function to draw opening hand with mulligan logic for both player and opponent
func draw_opening_hand(deck: Array, player_name: String = "") -> Array:
	# Set the opening variables that will be overwritten by the function
	var hand = []
	var has_basic_pokemon = false
	
	while not has_basic_pokemon:
		# Clear the hand every time this loops otherwise cards would just be continued to be added
		hand.clear()
		# Now draw 7 card and put them in the hand
		for i in range(7):
			# Pop front removes the same card from the deck so you don't need to do a .remove and a .add at the same time
			hand.append(deck.pop_front())
		
		# Check if hand contains at least one Basic Pokemon, if not hand needs to go back in deck and reshuffle
		for card_uid in hand:
			# Is_Basic_pokemon is a function written to check if an array (the hand) contains a basic pokemon
			if is_basic_pokemon(card_uid):
				has_basic_pokemon = true
				break
		
		# If no Basic Pokemon, mulligan
		if not has_basic_pokemon:
			print(player_name, "No Basic Pokemon in hand. Shuffling back...")
			
			# Put hand back into deck
			for card_uid in hand:
				deck.append(card_uid)
			
			# Shuffle again
			deck.shuffle()

	print("Basic pokemon found.", player_name, "'s hand contains: ", hand)
	
	return hand

# Reusable function to load any deck (both player and opponent) from JSON file path
func load_deck_from_file(deck_file_path: String) -> Array:
	var deck = []
	
	# Open and read the file
	var loaded_deck_from_file = FileAccess.open(deck_file_path, FileAccess.READ)
	
	if loaded_deck_from_file == null:
		print("Error: Could not open deck file at: ", deck_file_path)
		return deck
	
	# Read the entire file as plain text first before parsing as JSON
	var unparsed_json_text = loaded_deck_from_file.get_as_text()
	loaded_deck_from_file.close()
	
	print("Raw text of deck file is: ", unparsed_json_text)
	
	# Parse the JSON
	var new_json_object = JSON.new()
	var deck_json_parse_result = new_json_object.parse(unparsed_json_text)
	
	# Check the deck has loaded correctly
	if deck_json_parse_result != OK:
		print("Error: Failed to parse the raw JSON text into JSON")
		return deck
	
	# Load the deck as parsed data
	var deck_data = new_json_object.data
	print("Parsed deck data: ", deck_data)
	
	# As we have the json data containing the ids and count of the cards we now need to make this into a readable deck
	if deck_data.size() > 0:
		for this_card in deck_data:
			var card_to_append_to_deck_id = this_card["id"]
			var card_to_append_to_deck_count = this_card["count"]
			
			for i in range(card_to_append_to_deck_count):
				deck.append(card_to_append_to_deck_id)
	
	print("Total Cards in deck counted are: ", deck.size())
	
	# Shuffle the deck
	deck.shuffle()
	print("Deck shuffled. First card after shuffle: ", deck[0])
	
	return deck

# Display hand cards in a container
func display_hand_cards(hand: Array, hand_container, card_width: int = 100, card_height: int = 138):
	var card_display_script = load("res://CardImage.gd")
	
	# Clear existing cards from container
	for child in hand_container.get_children():
		child.queue_free()
	
	# Draw all cards in the hand
	for this_card_in_hand in hand:
		var hand_card_to_display = TextureRect.new()
		
		# Attach the loading of the card image script to the newly generated card
		hand_card_to_display.set_script(card_display_script)
		
		# Add the newly generated card to the hand container
		hand_container.add_child(hand_card_to_display)
		
		# Load the card image with pixel sizes for hand cards
		hand_card_to_display.load_card_image(this_card_in_hand, card_width, card_height)

# Main function to set up the player's deck and hand at match start
func setup_player():
	var player_deck_path = "res://playerdata/CurrentDeck.json"
	var player_hand_container = $player_hand_hbox_container
	
	# Load and shuffle deck
	var player_deck = load_deck_from_file(player_deck_path)
	
	# Draw opening hand with mulligan
	var player_hand = draw_opening_hand(player_deck, "Player")
	
	print("Player deck size after drawing hand: ", player_deck.size())
	
	# Display the hand
	display_hand_cards(player_hand, player_hand_container, 100, 138)

# Main function to set up the opponents's deck and hand at match start. Looks up the NPC name and finds the corresponding deck file
func setup_opponent(opponent_id: String):
	var opponent_deck_path = "res://opponentdeckdata/"+opponent_id+".json"
	var opponent_hand_container = $opponent_hand_hbox_container
	
	var opponent_deck = load_deck_from_file(opponent_deck_path)
	var opponent_hand = draw_opening_hand(opponent_deck, "Opponent")
	
	display_hand_cards(opponent_hand, opponent_hand_container, 50, 69)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	setup_player()
	setup_opponent("Fisherman1")
