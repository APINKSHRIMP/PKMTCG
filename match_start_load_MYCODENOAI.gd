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
	
	# We don't need to check the rest of the card data if this is an energy or trainer card
	print("Card supertype is: ", main_card_type)
	
	# If the card is a pokemon type then we finally check if it's basic or not
	if main_card_type == "pokémon":
		var card_subtypes_array = card_full_metadata.get("subtypes", [])
		
		# Now We need to make sure it is a BASIC and POKEMON (there exists BASIC ENERGY)
		for each_subtype in card_subtypes_array:
			var each_subtype_lower = each_subtype.to_lower()
			match each_subtype_lower:
				"basic","baby":
					return true
				"stage1","stage2":
					return false
					
	# If the above statements don't deem this a POKEMON card AND a BASIC card then return false
	return false
	
# Main function to launch at start of match to load player's deck and draw 7 cards into players hand
func load_player_deck():
	# Path to the player's deck JSON file
	var player_current_deck_path = "res://playerdata/CurrentDeck.json"
	
	# Set the current player deck and hand to empty arrays first. These will be appended to later
	var player_current_deck = []
	var player_hand = []
	var card_display_script = load("res://CardImage.gd")
	
	# we will be writing to the texturerect node to change the display of the image so save it as a variable to reference
	var player_hand_container = $player_hand_hbox_container

	# Open and read the file
	var loaded_deck_from_file = FileAccess.open(player_current_deck_path, FileAccess.READ)
	
	if loaded_deck_from_file == null:
		print("Error: Could not open deck file at: ", loaded_deck_from_file)
		return
	
	# Read the entire file as plain text first before parsing as JSON
	var unparsed_json_text = loaded_deck_from_file.get_as_text()
	loaded_deck_from_file.close()
	
	print("Raw text of current player deck file is: ", unparsed_json_text)
	
	# Parse the JSON
	var new_json_object = JSON.new()
	var player_current_deck_json = new_json_object.parse(unparsed_json_text)

	# Check the deck has loaded currectly
	if player_current_deck_json != OK:
		print("Error: Failed to parse the raw JSON text into JSON")
		return
		
	# Load the players deck as parsed data
	var player_current_deck_data = new_json_object.data
	print("Parsed deck data: ", player_current_deck_data)
	
	# As we have the json data containing the ids and count of the cards we now need to make this into a readable deck
	if player_current_deck_data.size() > 0:
		for this_card in player_current_deck_data:
			var card_to_append_to_deck_id = this_card["id"]
			var card_to_append_to_deck_count = this_card["count"]
			
			for i in range(card_to_append_to_deck_count):
				player_current_deck.append(card_to_append_to_deck_id)
				
		
	print("Total Cards in deck counted are: ", player_current_deck.size())
	
	# The deck will be in order so we need this shuffling
	player_current_deck.shuffle()
	print("Deck shuffled. First card after shuffle: ", player_current_deck[0])
	
	# Now draw 7 cards and add them to the player's hand
	for i in range(7):
		# Pop front removes the cards from the deck so you don't need to do 2 steps to add and remove
		player_hand.append(player_current_deck.pop_front())
		
	print("7 cards added to hand. Deck size is now: ", player_current_deck.size())
	print("Hand now contains: ", player_hand)
	
	# draw all of the player's hand cards in the collection box for the player's hand		
	for this_card_in_player_hand in player_hand:
		var hand_card_to_display = TextureRect.new()
		
		# Attach the loading of the card image script to the newly generated card
		hand_card_to_display.set_script(card_display_script)
		
		# Add the newly generated card to the player's hand container
		player_hand_container.add_child(hand_card_to_display)
		
		# Load the card image with pixel sizes for hand cards (e.g 100, 138)
		hand_card_to_display.load_card_image(this_card_in_player_hand, 100, 138)
		
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# THIS BIT IS JUST for testing
	var is_this_card_basic = is_basic_pokemon("Base1-3")
	if is_this_card_basic:
		print("Yes basic")
	else:
		print("not basic")
	
	# Load the decks on match launch
	#load_player_deck()
