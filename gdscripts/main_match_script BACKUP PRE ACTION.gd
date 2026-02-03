extends Control

################################################################# SET OF VARIABLES ###################################################################

# GLOBAL VARIABLES FOR FULL MATCH VARIABLES AND CHANGABLES
var player_hand: Array = []
var player_deck: Array = []

var opponent_hand: Array = []
var opponent_deck: Array = []

var player_active_pokemon: card_object = null
var opponent_active_pokemon: card_object = null

var amount_of_cards_to_draw = 7

var card_selection_mode_enabled = false
var selected_card_for_action = null
var card_was_clicked_this_frame: bool = false

# I know this vector dict code is a bit messy but for testing and just resizing things on the UI it's easier
# I should delete most of these when done
var card_scales: Dictionary = {
	1: Vector2(600, 825),
	2: Vector2(550, 756),
	3: Vector2(500, 688),
	4: Vector2(400, 550),
	5: Vector2(350, 481),
	6: Vector2(300, 413),
	7: Vector2(265, 364),
	8: Vector2(260, 358),
	9: Vector2(200, 275),
	10: Vector2(150,206),
	11: Vector2(100, 138),
	12: Vector2(50, 69)
}

################################################################# END OF VARIABLES ###################################################################

################################################################ START OF FUNCTIONS ##################################################################

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
func is_basic_pokemon(card: card_object) -> bool:
	# Get the metadata from the card object directly
	var card_full_metadata = card.metadata
	
	# Make sure metadata exists
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
		for i in range(amount_of_cards_to_draw):
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
	
	# Parse the JSON
	var new_json_object = JSON.new()
	var deck_json_parse_result = new_json_object.parse(unparsed_json_text)
	
	# Check the deck has loaded correctly
	if deck_json_parse_result != OK:
		print("Error: Failed to parse the raw JSON text into JSON")
		return deck
	
	# Load the deck as parsed data
	var deck_data = new_json_object.data

	# As we have the json data containing the ids and count of the cards we now need to make this into a readable deck
	if deck_data.size() > 0:
		for this_card in deck_data:
			var card_to_append_to_deck_id = this_card["id"]
			var card_to_append_to_deck_count = this_card["count"]
			
			for i in range(card_to_append_to_deck_count):
				# Get the metadata for this card to save to the card object
				var card_metadata = get_card_metadata(card_to_append_to_deck_id)
				
				# Create a new card_object with the UID and metadata
				var new_card = card_object.new(card_to_append_to_deck_id, card_metadata)
				
				# Add the card object to the deck
				deck.append(new_card)

	# Shuffle the deck
	deck.shuffle()

	return deck

# Called when a card in selection mode is clicked
func this_card_clicked(clicked_card: card_object) -> void:
	if card_selection_mode_enabled == true:
		#print("Card clicked: ", clicked_card.uid)
		
		# We now have the actual card object, so we can access its metadata directly
		#print("Card name: ", clicked_card.metadata.get("name", "Unknown"))
		
		# Store reference to the selected card
		selected_card_for_action = clicked_card
		
		print("Selected card for action: ", selected_card_for_action.metadata["name"])
			
	else:
		selected_card_for_action = null

# Display hand cards in a container
func display_array_of_cards(hand: Array, hand_container, card_size: Vector2):
	var card_display_script = load("res://gdscripts/cardimage.gd")
	
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
		hand_card_to_display.load_card_image(this_card_in_hand.uid, card_size, this_card_in_hand)
		
		# Connect this card's signal to the main script's handler
		hand_card_to_display.card_clicked.connect(this_card_clicked)

# Main function to set up the player's deck and hand at match start
func setup_player():
	var player_deck_path = "res://playerdata/CurrentDeck.json"
	var player_hand_container = $player_hand_hbox_container
	
	# Load and shuffle deck
	player_deck = load_deck_from_file(player_deck_path)
	
	# Draw opening hand with mulligan
	player_hand = draw_opening_hand(player_deck, "Player")
	
	# Display the hand
	display_array_of_cards(player_hand, player_hand_container, card_scales[11])

# Main function to set up the opponents's deck and hand at match start. Looks up the NPC name and finds the corresponding deck file
func setup_opponent(opponent_id: String):
	var opponent_deck_path = "res://opponentdeckdata/"+opponent_id+".json"
	var opponent_hand_container = $opponent_hand_hbox_container
	
	opponent_deck = load_deck_from_file(opponent_deck_path)
	opponent_hand = draw_opening_hand(opponent_deck, "Opponent")
	
	display_array_of_cards(opponent_hand, opponent_hand_container, card_scales[12])

# Main function to show all hand cards larger when the player's hand is clicked
func _on_player_hand_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		show_enlarged_array(player_hand)
		
func _on_opponent_hand_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		show_enlarged_array(opponent_hand)

# This is a reusable function to display any array passed to it and hide everything else on the screen.
# Used for any selection of hand discard pile bench etc
func show_enlarged_array(card_array: Array) -> void:
	card_selection_mode_enabled = true
	var amount_of_cards_to_show = card_array.size()
	# I couldn't figure out how to get a scrolling box to be centrally aligned and gave up
	# So instead, if the card array is OVER 7 then use the scroller box. If it's UNDER 7 then just use a box central aligned
	if amount_of_cards_to_show > 7:
		# Hide ALL UI components
		$player_hand_hbox_container.visible = false
		$opponent_hand_hbox_container.visible = false
		$small_selection_mode_container.visible = false
		
		# Show only the selection mode container and the button to cancel the view
		$cancel_selection_mode_view_button.visible = true
		$selection_mode_scroller.visible = true
		$selection_mode_scroller/large_selection_mode_container.visible = true
		
		# Now display the passed through card array to the selection mode container in large pixel format
		display_array_of_cards(card_array, $selection_mode_scroller/large_selection_mode_container, card_scales[5])
		
		# If UNDER 8 cards (small array)	
	else:
		#Hide ALL UI components
		$player_hand_hbox_container.visible = false
		$opponent_hand_hbox_container.visible = false
		$selection_mode_scroller/large_selection_mode_container.visible = false
		
		# Show only the selection mode container and the button to cancel the view
		$cancel_selection_mode_view_button.visible = true
		$selection_mode_scroller.visible = true
		$small_selection_mode_container.visible = true
		
		$small_selection_mode_container.custom_minimum_size = Vector2(0, 0)
		
		# Now display the passed through card array to the selection mode container in large pixel format
		display_array_of_cards(card_array, $small_selection_mode_container, card_scales[amount_of_cards_to_show])

# When the cancel button is clicked, hide everthing in card selection mode and show main screen again
func _on_cancel_selection_mode_button_pressed() -> void:
	card_selection_mode_enabled = false
	$selection_mode_scroller.visible = false
	$selection_mode_scroller/large_selection_mode_container.visible = false
	$cancel_selection_mode_view_button.visible = false
	$small_selection_mode_container.visible = false
	
	$player_hand_hbox_container.visible = true
	$opponent_hand_hbox_container.visible = true

# Function for setting the active pokemon from hand of bench
func set_player_active_pokemon() -> void:
	# First, check if a card was actually selected
	if selected_card_for_action == null:
		print("Error: No card selected for action")
		return
	
	# Check if the selected card is a basic pokemon
	if not is_basic_pokemon(selected_card_for_action):
		print("Error: Selected card is not a basic pokemon")
		return
	
	# If we get here, it's valid - set it as the active pokemon
	player_active_pokemon = selected_card_for_action
	
	# Remove this card from the player's hand since it's now active
	player_hand.erase(selected_card_for_action)
	
	# Print confirmation
	print("Player's active pokemon set to: ", player_active_pokemon.metadata["name"])
	
	# Clear the selection
	selected_card_for_action = null

func display_active_pokemon() -> void:
	# Get the container for the player's active pokemon
	var active_pokemon_container = $player_active_pokemon_container
	
	# Clear any existing card from the container
	for child in active_pokemon_container.get_children():
		child.queue_free()
	
	# Only display if there actually IS an active pokemon
	if player_active_pokemon == null:
		print("No active pokemon to display")
		return
	
	# Load the card display script (same as we do for hand cards)
	var card_display_script = load("res://gdscripts/cardimage.gd")
	
	# Create a new TextureRect for the active pokemon
	var active_card_display = TextureRect.new()
	
	# Attach the card display script
	active_card_display.set_script(card_display_script)
	
	# Add it to the container
	active_pokemon_container.add_child(active_card_display)
	
	# Load the card image with a larger size (let's use card_scales[2])
	active_card_display.load_card_image(player_active_pokemon.uid, card_scales[2], player_active_pokemon)
	
	# Connect the signal (though we might want to prevent clicking active pokemon later)
	active_card_display.card_clicked.connect(this_card_clicked)

func _on_set_button_pressed() -> void:
	# Try to set the player's active pokemon
	set_player_active_pokemon()
	
	# Refresh the active pokemon display
	display_active_pokemon()
	
	# Close the selection mode (same as cancel button)
	_on_cancel_selection_mode_button_pressed()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		# Get the mouse position
		var mouse_pos = get_global_mouse_position()
		
		# Check if mouse is over any card in the visible containers
		var clicked_on_card = false
		
		
		# Check small selection container cards
		for card_ui in $small_selection_mode_container.get_children():
			if card_ui.get_global_rect().has_point(mouse_pos) and card_selection_mode_enabled == true:
				clicked_on_card = true
				print("the game thinks a card has been clicked")
				break

		# Check large selection container cards
		for card_ui in $selection_mode_scroller/large_selection_mode_container.get_children():
			if card_ui.get_global_rect().has_point(mouse_pos) and card_selection_mode_enabled == true:
				clicked_on_card = true
				break
		
		# If no card was clicked, clear selection
		if not clicked_on_card:
			print("CARD WAS NOT CLICKED SO CLEAR SELECTED")
			selected_card_for_action = null
			
################################################################ END OF FUNCTIONS ##################################################################

################################################################ START OF GAME ##################################################################
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$player_hand_hbox_container.gui_input.connect(_on_player_hand_clicked)
	$opponent_hand_hbox_container.gui_input.connect(_on_opponent_hand_clicked)
	$cancel_selection_mode_view_button.pressed.connect(_on_cancel_selection_mode_button_pressed)
	setup_player()
	setup_opponent("Fisherman1")
	show_enlarged_array(player_hand)
################################################################ END OF GAME ##################################################################
