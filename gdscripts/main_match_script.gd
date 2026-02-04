extends Control

######################################################################################################################################################
################################################################# SET OF VARIABLES ###################################################################
######################################################################################################################################################

# GLOBAL VARIABLES FOR FULL MATCH VARIABLES AND CHANGABLES. MOST ARE SELF EXPLANATORY BY NAME

# PLAYER VARIABLES
var player_hand: Array = []
var player_deck: Array = []
var player_bench: Array = []
var player_active_pokemon: card_object = null

# OPPONENT VARIABLES
var opponent_hand: Array = []
var opponent_deck: Array = []
var opponent_bench: Array = []
var opponent_active_pokemon: card_object = null

# GAME VARIABLES
var amount_of_cards_to_draw = 7

# FUNCTIONAL REQUIREMENT VARIABLES
var card_selection_mode_enabled = false
var selected_card_for_action = null
var card_was_clicked_this_frame: bool = false
var match_just_started_basic_pokemon_required = true

# QUICK REFERENCE VECTORS JUST USED FOR EASY SWAPPING OF SIZES FOR DEVELOPMENT
var card_scales: Dictionary = {
	1: Vector2(450, 619),
	1.5: Vector2(575, 791),
	2: Vector2(400, 550),
	2.5: Vector2(525, 722),
	3: Vector2(375, 515),
	3.5: Vector2(450, 619),
	4: Vector2(350, 481),
	4.5: Vector2(375, 515),
	5: Vector2(350, 481),
	5.5: Vector2(325, 447),
	6: Vector2(300, 413),
	6.5: Vector2(282, 388),
	7: Vector2(265, 364),
	7.5: Vector2(262, 361),
	8: Vector2(260, 358),
	8.5: Vector2(230, 316),
	9: Vector2(200, 275),
	9.5: Vector2(175, 240),
	10: Vector2(150, 206),
	10.5: Vector2(125, 172),
	11: Vector2(100, 138),
	11.5: Vector2(75, 103),
	12: Vector2(50, 69)
}
######################################################################################################################################################
################################################################# END OF VARIABLES ###################################################################
######################################################################################################################################################

######################################################################################################################################################
################################################################ START OF FUNCTIONS ##################################################################
######################################################################################################################################################

################################################################# DISPLAY FUNCTIONS ##################################################################

# Main reusable function to display any array passed in a LARGE viewing mode, hide everything else on the screen and allows selection of cards for action
func show_enlarged_array(card_array: Array) -> void:
	
	# Prevent showing empty arrays
	if card_array.size() == 0:
		print("Cannot show enlarged array: array is empty")
		return
	
	# If we are showing an enlarged display then card selection mode is enabled.
	card_selection_mode_enabled = true
	
	# If we're showing more than 7 cards we want a scrollable container so count total cards in this array
	var amount_of_cards_to_show = card_array.size()
	
	# In enlarged selection mode, we want to hide everything on the main screen and only show the enlarged array and buttons
	$player_hand_hbox_container.visible = false
	$opponent_hand_hbox_container.visible = false
	
	$player_active_pokemon_container.visible = false
	$opponent_active_pokemon_container.visible = false
	
	$player_active_pokemon_container.mouse_filter = MOUSE_FILTER_IGNORE
	$opponent_active_pokemon_container.mouse_filter = MOUSE_FILTER_IGNORE
	
	for card in $player_active_pokemon_container.get_children():
		card.mouse_filter = MOUSE_FILTER_IGNORE
	for card in $opponent_active_pokemon_container.get_children():
		card.mouse_filter = MOUSE_FILTER_IGNORE
	
	$player_bench_container.visible = false
	
	# Show the buttons
	$card_action_button.visible = true
	
	# A specific clause for the start of the game, a basic pokemon HAS to be chosen so we cannot allow cancelling out.
	if match_just_started_basic_pokemon_required == true:
		$cancel_selection_mode_view_button.visible = false
	else:
		$cancel_selection_mode_view_button.visible = true
	
	# Hide action button if viewing opponent's hand
	if card_array == opponent_hand or card_array == opponent_bench:
		$card_action_button.visible = false
	else:
		$card_action_button.visible = true
		
	# If the card array is OVER 7 then use the scroller box. If it's UNDER 7 then just use a box central aligned
	if amount_of_cards_to_show > 7:
		# If OVER 7 cards then use a scrolling box container
		$selection_mode_scroller.visible = true
		$selection_mode_scroller/large_selection_mode_container.visible = true
		
		# Now display the passed through card array to the selection mode container in large pixel format
		display_hand_cards_array(card_array, $selection_mode_scroller/large_selection_mode_container, card_scales[5])
		
		# If UNDER 8 cards (small array)	
	else:
		# DON'T use the scrolling box container
		$small_selection_mode_container.visible = true
		$small_selection_mode_container.custom_minimum_size = Vector2(0, 0)
		
		# Now display the passed through card array to the selection mode container in large pixel format
		display_hand_cards_array(card_array, $small_selection_mode_container, card_scales[amount_of_cards_to_show])

# Displays both the player and opponents hand cards. Shows players at the top of screen and opponents in top right smaller.
func display_hand_cards_array(hand: Array, hand_container, card_size: Vector2):
	
	# Load the script that displays card images
	var card_display_script = load("res://gdscripts/cardimage.gd")
	
	# Clear existing cards from container to prevent stale entries when cards leave or enter the hand
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

# Displays the active pokemon large and central on screen	
func display_active_pokemon() -> void:
	
	# Get the container for the active pokemon
	var active_pokemon_container = $player_active_pokemon_container
	
	# Clear the active pokemon to prevent stale cards when knocked out, retreated or evolved
	for child in active_pokemon_container.get_children():
		child.queue_free()
	
	# Only display if there actually IS an active pokemon. error out if there isn't
	if player_active_pokemon == null:
		print("No active pokemon to display")
		return
	
	# Load the card display script
	var card_display_script = load("res://gdscripts/cardimage.gd")
	
	# Create a new TextureRect for the active pokemon card to be displayed (texture rect =/= a control/container node)
	var active_card_display = TextureRect.new()
	
	# Attach the card display script to display the correct image
	active_card_display.set_script(card_display_script)
	
	# Add the sprite/texture to the container
	active_pokemon_container.add_child(active_card_display)
	
	# Load the card image with a large size
	active_card_display.load_card_image(player_active_pokemon.uid, card_scales[3.5], player_active_pokemon)
	
	# Connect the signal allowing the active pokemon to be clicked and selected
	active_card_display.card_clicked.connect(this_card_clicked)

# Displays the bench pokemon smaller and in corner of screen
func display_bench_pokemon() -> void:
	
	# Get the container for the correct bench
	var bench_container = $player_bench_container
	
	# Clear any existing cards from the container
	for child in bench_container.get_children():
		child.queue_free()
	
	# If bench is empty, nothing to display so don't run the rest of the code
	if player_bench.size() == 0:
		return
	
	# Load the card display script
	var card_display_script = load("res://gdscripts/cardimage.gd")
	
	# Loop through each pokemon on the bench and display it
	for bench_pokemon in player_bench:
		# Create a new TextureRect for each benched pokemon
		var bench_card_display = TextureRect.new()
		
		# Attach the card display script
		bench_card_display.set_script(card_display_script)
		
		# Add it to the container
		bench_container.add_child(bench_card_display)
		
		# Load the card image using card_scales
		bench_card_display.load_card_image(bench_pokemon.uid, card_scales[11], bench_pokemon)
		
		# Connect the signal so benched pokemon can be clicked
		bench_card_display.card_clicked.connect(this_card_clicked)

# Both the cancel button and action button will hide selection mode so function is vaguely named for both actions
func display_main_components_hide_selection_mode() -> void:
	
	if selected_card_for_action != null:
		var card_ui = find_card_ui_for_object(selected_card_for_action)
		if card_ui:
			card_ui.set_selected(false)
	
	# End card selection mode and clear any selected card to prevent errors
	card_selection_mode_enabled = false
	selected_card_for_action = null  
	update_action_button()  
	
	# Hide the enlarged selection mode cards
	$small_selection_mode_container.visible = false
	$selection_mode_scroller.visible = false
	$selection_mode_scroller/large_selection_mode_container.visible = false
	
	# Hide the buttons
	$cancel_selection_mode_view_button.visible = false
	$card_action_button.visible = false
	
	# Show the player and opponents hands
	$player_hand_hbox_container.visible = true
	$opponent_hand_hbox_container.visible = true
	
	# Show the player and opponents active pokemon
	$player_active_pokemon_container.visible = true
	$opponent_active_pokemon_container.visible = true
	
	# Show the player and oppoents bench
	$player_bench_container.visible = true
	
	# Re-enable mouse input on previously hidden containers
	$player_active_pokemon_container.mouse_filter = MOUSE_FILTER_PASS
	$opponent_active_pokemon_container.mouse_filter = MOUSE_FILTER_PASS
	$player_bench_container.mouse_filter = MOUSE_FILTER_PASS
	
	# Re-enable input on cards in the active pokemon containers
	for card in $player_active_pokemon_container.get_children():
		card.mouse_filter = MOUSE_FILTER_PASS
	for card in $opponent_active_pokemon_container.get_children():
		card.mouse_filter = MOUSE_FILTER_PASS
	
############################################################### END DISPLAY FUNCTIONS ################################################################


################################################################ GAME LOAD FUNCTIONS #################################################################
# Reusable function to load any deck (both player and opponent) from JSON file path
func load_deck_from_file(deck_file_path: String) -> Array:
	var deck = []
	
	# Open and read the file
	var loaded_deck_from_file = FileAccess.open(deck_file_path, FileAccess.READ)
	
	# Make sure no errors when loading the file
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

	# As we have the json data containing the ids and amount, we need to add mutiple of some cards
	if deck_data.size() > 0:
		for this_card in deck_data:
			
			# Get the ID and amount there are in the deck
			var card_to_append_to_deck_id = this_card["id"]
			var card_to_append_to_deck_count = this_card["count"]
			
			# We will now add the amount in COUNT to the deck
			for i in range(card_to_append_to_deck_count):
				
				# Get the metadata for this card to save to the card object
				var card_metadata = get_card_metadata(card_to_append_to_deck_id)
				
				# Create a new card_object with the UID and metadata
				var new_card = card_object.new(card_to_append_to_deck_id, card_metadata)
				
				new_card.current_location = "deck" 
				
				# Add the card object to the deck
				deck.append(new_card)

	# Shuffle the fully completed deck
	deck.shuffle()
	
	# Pass the deck back as a saved variable
	return deck

# Main function to set up the player's deck and hand at match start
func setup_player():
	
	# Load the players CURRENT deck from saved files
	var player_deck_path = "res://playerdata/CurrentDeck.json"
	var player_hand_container = $player_hand_hbox_container
	
	# Load and shuffle deck
	player_deck = load_deck_from_file(player_deck_path)
	
	# Draw opening hand with mulligan
	player_hand = draw_opening_hand(player_deck, "Player")
	
	# Display the hand on the main screen at the top centre
	display_hand_cards_array(player_hand, player_hand_container, card_scales[11])

# Main function to set up the opponents's deck and hand at match start. Looks up the NPC name and finds the corresponding deck file
func setup_opponent(opponent_id: String):
	
	# We will need to eventually pass a number of different decks depending on the NPC opponent so load the correct one from file
	var opponent_deck_path = "res://opponentdeckdata/"+opponent_id+".json"
	var opponent_hand_container = $opponent_hand_hbox_container
	
	# Load the deck from the opponent data folder file
	opponent_deck = load_deck_from_file(opponent_deck_path)
	
	# Draw opening cards and mulligan
	opponent_hand = draw_opening_hand(opponent_deck, "Opponent")
	
	# Display the cards in the top right in tiny size just for visual cue
	display_hand_cards_array(opponent_hand, opponent_hand_container, card_scales[12])

# Function to draw opening hand with mulligan logic for both player and opponent
func draw_opening_hand(deck: Array, player_name: String = "") -> Array:
	# Set the opening variables that will be overwritten by the function
	var hand = []
	var has_basic_pokemon = false
	
	# We need to mulligan if no basic pokemon in hand for each draw. May take multiple attempts
	while not has_basic_pokemon:
		
		# Clear the hand every time this loops otherwise cards would just be continued to be added
		hand.clear()
		
		# Now draw X (default is 7) cards and put them in the hand
		for i in range(amount_of_cards_to_draw):
			
			# Pop front removes the same card from the deck so you don't need to do a .remove and a .add at the same time
			var drawn_card = deck.pop_front() 
			
			# Set the card objects current location to be the hand now that it has been added there
			drawn_card.current_location = "hand" 
			
			# Add to the hand
			hand.append(drawn_card)
		
		# Check if hand contains at least one Basic Pokemon, if not hand needs to go back in deck and reshuffle
		for card_uid in hand:
			
			# Is_Basic_pokemon is a function written to check if an array (the hand) contains a basic pokemon
			if is_basic_pokemon(card_uid):
				
				# If one is found then we don't need to keep looping and retrying so exit out of function
				has_basic_pokemon = true
				break
		
		# If no Basic Pokemon, mulligan
		if not has_basic_pokemon:
			print(player_name, "No Basic Pokemon in hand. Shuffling back...")
			
			# Put hand back into deck
			for card_uid in hand:
				deck.append(card_uid)
			
			# Shuffle again and start redraw for new hand again
			deck.shuffle()
	
	return hand

############################################################## END GAME LOAD FUNCTIONS ###############################################################

############################################################ CORE FUNCTIONALITY FUNCTIONS ############################################################
	
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
		
		# Now We need to make sure it is a BASIC and POKEMON (there exists BASIC ENERGY and allow baby pokemon as basic pokemon)
		for each_subtype in card_subtypes_array:
			
			# avoid case sensitivity
			var each_subtype_lower = each_subtype.to_lower()
			
			# Baby pokemon count as basic
			match each_subtype_lower:
				"basic", "baby":
					return true
				"stage 1", "stage 2", "stage1", "stage2":
					return false
	
	# If the above statements don't deem this a POKEMON card at all or it is a pokemon but NOT a BASIC card then return false
	return false

# Get card action is used when selecting a card from an array. Allows basic pokemon to be set, trainers to be played, energies to be attached
func get_card_action(card: card_object) -> Dictionary:
	
	# This function returns a dictionary with the action name and whether it's available
	if card == null:
		return {"action": "NONE", "button_text": ""}
	
	# We need to get the cards type whether it's trainer pokemon or energy
	var card_metadata = card.metadata
	var supertype = card_metadata.get("supertype", "").to_lower()
	
	# As a very specific piece of logic, only basic pokemon can be set as active pokemon on turn 1 and never again.
	if match_just_started_basic_pokemon_required == true:
		
		# Only a pokemon card can be played and ONLY if that pokemon card is basic
		match supertype:
			"pokémon":
				if is_basic_pokemon(card):
					# If the selected card is a basic pokemon then it can be set as active pokemon on turn one
					return {"action": "SET_POKEMON", "button_text": "Play Active Pokemon"}
				else:
					# Stage 1 or Stage 2 cannot be played on turn 1
					return {"action": "NONE", "button_text": "Select Basic Pokemon"}
					
			# trainers and energy cannot be played until a basic pokemon is set
			"trainer","energy":
					return {"action": "NONE", "button_text": "Select Basic Pokemon"}
					
	# If turn one is done and a basic pokemon has been played then any card can be played with different actions
	else:
		match supertype:
			"pokémon":
				if is_basic_pokemon(card):
					return {"action": "SET_POKEMON", "button_text": "Place on Bench"}
				else:
					# Stage 1 or Stage 2 - we'll handle evolution later
					return {"action": "EVOLVE", "button_text": "Evolve"}
			
			"trainer":
				return {"action": "PLAY_TRAINER", "button_text": "Play"}
			
			"energy":
				return {"action": "ATTACH_ENERGY", "button_text": "Attach"}	
				
	
	# Default fallback
	return {"action": "NONE", "button_text": ""}

# Function to change the text, enabled mode and function of the action button.
func update_action_button() -> void:
	
	# We need to see what the button can do by running the function get_card_action
	var action_info = get_card_action(selected_card_for_action)
	var action_button = $card_action_button
	
	# If no card is selected then we have no action to perform so disable the button and change text to select the card
	if selected_card_for_action == null:
		
		# Specific requirement for the first turn, ONLY a basic pokemon can be set and nothing else so change text accordingly
		if match_just_started_basic_pokemon_required:
			action_button.text = "Select Basic Pokemon"
		else:
			action_button.text = "Select A Card"
		
		# If no card is selected, disable the button and change the colour to show it can't be clicked	
		action_button.disabled = true
		action_button.theme = load("res://uiresources/kenneyUI.tres")
	
	# If the match has just started, ONLY a basic pokemon can be played and set as active pokemon, not placed on bench	
	elif match_just_started_basic_pokemon_required and is_basic_pokemon(selected_card_for_action):
		
		# Match just started AND a basic pokemon is selected so card is set to active
		action_button.text = "Play Active Pokemon"
		
		# Enable the button and change the colour
		action_button.disabled = false
		action_button.theme = load("res://uiresources/kenneyUI-green.tres")
	
	# If a basic pokemon is needed for turn 1 but any other card or no card is selected then change text to select basic pokemon	
	elif match_just_started_basic_pokemon_required:
		
		# Match just started BUT wrong card or no card type selected
		action_button.text = "Select Basic Pokemon"
		
		# Disable the button and change the colour
		action_button.disabled = true
		action_button.theme = load("res://uiresources/kenneyUI.tres")
	
	# For 99% of other cases, if a card has been selected from the hand AND it isn't turn 1 requiring a basic, then display the action the card can take	
	else:
		# Normal match play - use action_info
		action_button.text = action_info["button_text"]
		
		# Only disable the button if the action avaialable is none
		action_button.disabled = (action_info["action"] == "NONE")
		
		# If the action button is disabled, change the colour. Change colour if it is enabled
		if action_button.disabled:
			action_button.theme = load("res://uiresources/kenneyUI.tres")
		else:
			action_button.theme = load("res://uiresources/kenneyUI-green.tres")

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
		
	print("Attempting to set an active pokemon:")
	
	# Store the original location before we change it
	var original_location = selected_card_for_action.current_location
	
	# If we get here, it's valid - set it as the active pokemon
	player_active_pokemon = selected_card_for_action
	
	# Update the card's location to "active"
	player_active_pokemon.current_location = "active"
	
	# Now remove from the appropriate location based on where it came from
	match original_location:
		"hand":
			player_hand.erase(selected_card_for_action)
			print("Removed pokemon from hand")
		"bench":
			# We'll implement this when we build the bench system
			# For now: player_bench.erase(selected_card_for_action)
			print("Removed pokemon from bench")
	
	# Print confirmation
	print("Player's active pokemon set to: ", player_active_pokemon.metadata["name"])
	
	# Clear the selection
	selected_card_for_action = null

# Function to add a card from the player's hand to the bench
func add_pokemon_to_bench(pokemon: card_object) -> void:
	# Validate that the card is a basic pokemon
	if not is_basic_pokemon(pokemon):
		print("Error: Cannot add non-basic pokemon to bench")
		return
	
	# Store the original location
	var original_location = pokemon.current_location
	
	# Update the card's location to "bench"
	pokemon.current_location = "bench"
	
	# Remove from the appropriate location based on where it came from
	match original_location:
		"hand":
			player_hand.erase(pokemon)
			print("Removed pokemon from hand and added to bench: ", pokemon.metadata["name"])
		"active":
			# We'll handle bench promotions later if needed
			print("Moved pokemon from active to bench")
	
	# Add the pokemon to the bench array
	player_bench.append(pokemon)
	print("Pokemon added to bench. Bench size: ", player_bench.size())

func find_card_ui_for_object(card_obj: card_object) -> TextureRect:
	# Check small selection container
	if $small_selection_mode_container.visible:
		for card_ui in $small_selection_mode_container.get_children():
			if card_ui.card_ref == card_obj:
				return card_ui
	
	# Check large selection container
	if $selection_mode_scroller.visible:
		for card_ui in $selection_mode_scroller/large_selection_mode_container.get_children():
			if card_ui.card_ref == card_obj:
				return card_ui
	
	return null

########################################################## END CORE FUNCTIONALITY FUNCTIONS ##########################################################

########################################################### USER INPUT ON CLICK FUNCTIONS ############################################################

# Card action button is the physical button that appears when in card selection mode, allows attaching energies, playing pokemon and trainer cards
func action_button_pressed_perform_action() -> void:
	# Don't do anything if no card is selected
	if selected_card_for_action == null:
		print("Error: No card selected for action")
		return
	
	# Prevent playing opponents cards
	if selected_card_for_action not in player_hand:
		print("Error: Can only play cards from your own hand")
		return
		
	# Get the action type
	var action_info = get_card_action(selected_card_for_action)
	var action_type = action_info["action"]
	
	# Perform the appropriate action based on card type
	match action_type:
		"SET_POKEMON":
			if match_just_started_basic_pokemon_required:
				# First turn - set as active pokemon
				set_player_active_pokemon()
				display_active_pokemon()
				display_hand_cards_array(player_hand, $player_hand_hbox_container, card_scales[11])
				match_just_started_basic_pokemon_required = false
			else:
				# After first turn - add to bench instead
				add_pokemon_to_bench(selected_card_for_action)
				display_hand_cards_array(player_hand, $player_hand_hbox_container, card_scales[11])
				display_bench_pokemon()
			
			display_main_components_hide_selection_mode() 
		
		"PLAY_TRAINER":
			print("Trainer card play not yet implemented")
			# We'll add this later
		
		"ATTACH_ENERGY":
			print("Energy attachment not yet implemented")
			# We'll add this later
		
		"EVOLVE":
			print("Evolution not yet implemented")
			# We'll add this later
		
		_:
			print("Unknown action: ", action_type)

# When the cancel button is clicked, hide everthing in card selection mode and show main screen again
func cancel_button_pressed_hide_selection_mode() -> void:
	display_main_components_hide_selection_mode()

# Main function to show all hand cards larger when the player's hand is clicked
func player_hand_clicked_show_hand(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		show_enlarged_array(player_hand)

# Main function to show all hand cards larger when the opponent's hand is clicked		
func opponent_hand_clicked_show_hidden_hand(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		show_enlarged_array(opponent_hand)

# Main function to show all of player's bench cards larger when clicked
func player_bench_clicked_show_bench(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		show_enlarged_array(player_bench)

# Main function to show all of opponent's bench cards larger when clicked
func opponent_bench_clicked_show_bench(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		show_enlarged_array(opponent_bench)

# Called when a card in selection mode is clicked
func this_card_clicked(clicked_card: card_object) -> void:
	if card_selection_mode_enabled == true:
		
		# NEW: Remove visual effect from previously selected card
		if selected_card_for_action != null:
			var prev_card_ui = find_card_ui_for_object(selected_card_for_action)
			if prev_card_ui:
				prev_card_ui.set_selected(false)
		
		# Store reference to the selected card
		selected_card_for_action = clicked_card
		
		print("Selected card for action: ", selected_card_for_action.metadata["name"])
		
		# Apply visual effect to newly selected card
		var card_ui = find_card_ui_for_object(clicked_card)
		if card_ui:
			card_ui.set_selected(true)
		
		# Update the button text and state based on the selected card
		update_action_button()
			
	else:
		selected_card_for_action = null

########################################################### USER INPUT ON CLICK FUNCTIONS ############################################################

######################################################################################################################################################			
################################################################# END OF FUNCTIONS ###################################################################
######################################################################################################################################################

######################################################################################################################################################
####################################################### START OF MAIN GAME RUNNING FUNCTIONS #########################################################
######################################################################################################################################################
	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var mouse_pos = get_global_mouse_position()
		
		# Check if click is on the cancel or action button - if so, ignore
		if $cancel_selection_mode_view_button.visible and $cancel_selection_mode_view_button.get_global_rect().has_point(mouse_pos):
			return
		if $card_action_button.visible and $card_action_button.get_global_rect().has_point(mouse_pos):
			return
		
		# Check if mouse is over any card in the visible containers
		var clicked_on_card = false
		
		# NEW: Only check small selection container if it's visible
		if $small_selection_mode_container.visible:
			for card_ui in $small_selection_mode_container.get_children():
				if card_ui.get_global_rect().has_point(mouse_pos) and card_selection_mode_enabled == true:
					clicked_on_card = true
					print("the game thinks a card has been clicked")
					break

		# NEW: Only check large selection container if it's visible
		if $selection_mode_scroller.visible:
			for card_ui in $selection_mode_scroller/large_selection_mode_container.get_children():
				if card_ui.get_global_rect().has_point(mouse_pos) and card_selection_mode_enabled == true:
					clicked_on_card = true
					break
		
		# If no card was clicked, clear selection
		if not clicked_on_card:
			print("CARD WAS NOT CLICKED SO CLEAR SELECTED")
			
			if selected_card_for_action != null:
				var card_ui = find_card_ui_for_object(selected_card_for_action)
				if card_ui:
					card_ui.set_selected(false)
			
			selected_card_for_action = null
			update_action_button()
			
			

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	# Connect all the signals so that when parts of the UI are clicked by mouse they can perform actions
	$player_hand_hbox_container.gui_input.connect(player_hand_clicked_show_hand)
	$opponent_hand_hbox_container.gui_input.connect(opponent_hand_clicked_show_hidden_hand)
	
	$player_bench_container.gui_input.connect(player_bench_clicked_show_bench)
	$opponent_bench_container.gui_input.connect(opponent_bench_clicked_show_bench)
	
	$cancel_selection_mode_view_button.pressed.connect(cancel_button_pressed_hide_selection_mode)
	$card_action_button.pressed.connect(action_button_pressed_perform_action)
	setup_player()
	setup_opponent("Fisherman1")
	update_action_button()
	show_enlarged_array(player_hand)
	display_bench_pokemon()	


######################################################################################################################################################
####################################################### END OF MAIN GAME RUNNING FUNCTIONS #########################################################
######################################################################################################################################################
