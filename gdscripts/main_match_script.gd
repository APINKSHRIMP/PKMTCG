extends Control

######################################################################################################################################################
################################################################# SET OF VARIABLES ###################################################################
######################################################################################################################################################

# GLOBAL VARIABLES FOR FULL MATCH VARIABLES AND CHANGABLES. MOST ARE SELF EXPLANATORY BY NAME

# TESTING VARIABLES
var amount_of_cards_to_draw = 7	# CAN CHANGE THE AMOUNT OF INITIAL HAND CARDS TO CHECK ARRAYS AND CARD FUNCTIONS
var hide_hidden_cards = true      	# TO SHOW PRIZE CARDS AND OPPONENTS HAND SET TO TRUE. FOR REAL GAME SET TO FALSE
var opponent_deck_name = "StatusChecks"
var player_deck_name = "StatusChecks"

# TESTING - There are different rulesets for burn and confusion depending on what generation/set is being played.
# Additionally I personally felt base set confusion retreat rule is horrendous, so I have created a personal rule that doesn't give free retreat but doesn't force discard then coin flip
var burn_rules: String = "base_set_burn_rules" # "base_set_burn_rules" or "modern_era_burn_rules"
var confusion_rules: String = "base_set_confusion_rules" # "base_set_confusion_rules" or "fairer_confusion_rules" or "modern_era_confusion_rules"

# Customisable in game textures
# Load coin textures
var tex_heads = load("res://gameimageassets/coins/coin_groudon_red.png")
var tex_tails = load("res://gameimageassets/coins/coin_back_basic.png")

# Game Variables
var turn_number: int = 0

# PLAYER VARIABLES
var player_hand: Array = []
var player_deck: Array = []
var player_bench: Array = []
var player_prize_cards = []
var player_active_pokemon: card_object = null
var player_discard_pile: Array = []

# OPPONENT VARIABLES
var opponent_hand: Array = []
var opponent_deck: Array = []
var opponent_bench: Array = []
var opponent_prize_cards = []
var opponent_active_pokemon: card_object = null
var opponent_discard_pile: Array = []

# FUNCTIONAL REQUIREMENT VARIABLES
var card_selection_mode_enabled = false
var selected_card_for_action = null
var card_was_clicked_this_frame: bool = false
var prize_card_selection_active: bool = false
var knockout_bench_selection_active: bool = false

var match_just_started_basic_pokemon_required = true
var bench_setup_phase_active = false

var player_energy_played_this_turn: bool = false
var opponent_energy_played_this_turn: bool = false

var energy_card_awaiting_target: card_object = null  # Stores the energy card while selecting its target
var card_attach_mode_active: bool = false

var evolution_card_awaiting_target: card_object = null
var evolution_mode_active: bool = false

var opponents_turn_active: bool = false

var retreat_mode_active: bool = false
var retreat_bench_selection_active: bool = false
var retreat_energies_selected: Array = []
var retreat_cost_remaining: int = 0
var player_retreat_disabled: bool = false
var opponent_retreat_disabled: bool = false
var player_retreated_this_turn: bool = false
var opponent_retreated_this_turn: bool = false

# UI VARIABLES
var large_header_text_label: Label
var small_hint_info_text_label: Label

#signals
signal message_acknowledged
signal prize_card_taken
signal knockout_replacement_chosen

# QUICK REFERENCE VECTORS JUST USED FOR EASY SWAPPING OF SIZES FOR DEVELOPMENT
var card_scales: Dictionary = {
	1: Vector2(450, 619),
	1.5: Vector2(575, 791),
	2: Vector2(400, 550),
	2.5: Vector2(525, 722),
	3: Vector2(375, 515),
	3.5: Vector2(405, 557),
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
	11.55: Vector2(83, 113),
	11.5: Vector2(75, 103),
	12: Vector2(50, 69),
	13: Vector2(25, 35)
}
######################################################################################################################################################
################################################################# END OF VARIABLES ###################################################################
######################################################################################################################################################

######################################################################################################################################################
################################################################ START OF FUNCTIONS ##################################################################
######################################################################################################################################################

#       #####     ######  #####   #####    ##         ##    ##   ##
#       ##   ##     ##   ##       ##   ##  ##        ####    ##  ##
#       ##     ##   ##     ###    #####    ##       ##  ##     ###
#       ##   ##     ##        ##  ##       ##      ########     ##
#       #####     ######  #####   ##       #####  ##      ##   ###

######################################################################################################################################################
################################################################# DISPLAY FUNCTIONS ##################################################################

# Main reusable function to display any array passed in a LARGE viewing mode, hide everything else on the screen and allows selection of cards for action
func show_enlarged_array_selection_mode(card_array: Array) -> void:
	
	$SELECTION_MODE/selection_mode_scroller.visible = false
	$SELECTION_MODE/selection_mode_scroller/large_selection_mode_container.visible = false
	$SELECTION_MODE/small_selection_mode_container.visible = false
	
	# Prevent showing empty arrays
	if card_array.size() == 0:
		print("Cannot show enlarged array: array is empty")
		return
	
	# Hide attack buttons if they are currently showing
	if $BUTTONS/main_screen_attack_buttons_container.visible:
		hide_attack_buttons()
	
	# If we are showing an enlarged display then card selection mode is enabled.
	card_selection_mode_enabled = true
	
	# If we're showing more than 7 cards we want a scrollable container so count total cards in this array
	var amount_of_cards_to_show = card_array.size()
	
	# In enlarged selection mode, we want to hide everything on the main screen and only show the enlarged array and buttons
	$CARD_COLLECTIONS/PLAYER/player_hand_hbox_container.visible = false
	$CARD_COLLECTIONS/OPPONENT/opponent_hand_hbox_container.visible = false
	
	$ACTIVE_POKEMON/PLAYER/player_active_pokemon_container.visible = false
	$ACTIVE_POKEMON/OPPONENT/opponent_active_pokemon_container.visible = false
	
	$ACTIVE_POKEMON/PLAYER/player_active_pokemon_container.mouse_filter = MOUSE_FILTER_IGNORE
	$ACTIVE_POKEMON/OPPONENT/opponent_active_pokemon_container.mouse_filter = MOUSE_FILTER_IGNORE
	
	$ACTIVE_POKEMON/PLAYER/player_active_pokemon_energies.visible = false
	$ACTIVE_POKEMON/OPPONENT/opponent_active_pokemon_energies.visible = false
	
	$ACTIVE_POKEMON/PLAYER/player_active_pokemon_hp_container.visible = false
	$ACTIVE_POKEMON/OPPONENT/opponent_active_pokemon_hp_container.visible = false
	
	$CARD_COLLECTIONS/PLAYER/player_bench_container.visible = false
	$CARD_COLLECTIONS/OPPONENT/opponent_bench_container.visible = false
	
	$SCREEN_LABELS/OPPONENT/opponent_bench_cards_label.visible = false
	$SCREEN_LABELS/PLAYER/player_bench_cards_label.visible = false
	
	$SCREEN_LABELS/OPPONENT/opponent_prize_cards_label.visible = false
	$SCREEN_LABELS/PLAYER/player_prize_cards_label.visible = false
	
	$CARD_COLLECTIONS/OPPONENT/opponent_prize_cards_container.visible = false
	$CARD_COLLECTIONS/PLAYER/player_prize_cards_container.visible = false
	
	$CARD_COLLECTIONS/PLAYER/player_deck_icon.visible = false
	$CARD_COLLECTIONS/OPPONENT/opponent_deck_icon.visible = false
	
	$CARD_COLLECTIONS/PLAYER/player_discard_pile_icon.visible = false
	$CARD_COLLECTIONS/OPPONENT/opponent_discard_pile_icon.visible = false
	
	# We do however want to show the header and hint labels
	$SCREEN_LABELS/MAIN_LABELS/small_hint_info_text_label.visible = true
	$SCREEN_LABELS/MAIN_LABELS/large_header_text_label.visible = true
	
	$BUTTONS/main_screen_buttons_container.visible = false
	
	for card in $ACTIVE_POKEMON/PLAYER/player_active_pokemon_container.get_children():
		card.mouse_filter = MOUSE_FILTER_IGNORE
	for card in $ACTIVE_POKEMON/OPPONENT/opponent_active_pokemon_container.get_children():
		card.mouse_filter = MOUSE_FILTER_IGNORE
	
	# Show the buttons
	$BUTTONS/SELECTION_BUTTONS/card_action_button.visible = true
	
	# A specific clause for the start of the game, a basic pokemon HAS to be chosen so we cannot allow cancelling out.
	if match_just_started_basic_pokemon_required == true or knockout_bench_selection_active == true:
		$cancel_selection_mode_view_button.visible = false
	else:
		$cancel_selection_mode_view_button.visible = true
	
	# Hide action button for view-only arrays (prize cards are only actionable during prize selection)
	var is_view_only_array = card_array in [opponent_hand, opponent_bench, player_discard_pile, opponent_discard_pile]
	if not prize_card_selection_active:
		is_view_only_array = is_view_only_array or card_array in [player_prize_cards, opponent_prize_cards]
		
	if is_view_only_array:
		$BUTTONS/SELECTION_BUTTONS/card_action_button.visible = false		
	else:
		$BUTTONS/SELECTION_BUTTONS/card_action_button.visible = true
		
	if $BUTTONS/SELECTION_BUTTONS/card_action_button.visible:
		$cancel_selection_mode_view_button.offset_left = 35.0
		$cancel_selection_mode_view_button.offset_right = 473.0
	else:
		$cancel_selection_mode_view_button.offset_left = -219.0
		$cancel_selection_mode_view_button.offset_right = 219.0
		
	update_selection_mode_labels(card_array, match_just_started_basic_pokemon_required)
	
	$SELECTION_MODE/selection_mode_scroller.visible = false
	$SELECTION_MODE/selection_mode_scroller/large_selection_mode_container.visible = false
	
	# Hide opponents hand but show player's
	var should_hide = hide_hidden_cards and (card_array == opponent_hand or card_array == player_prize_cards or card_array == opponent_prize_cards)
	
	# If the card array is OVER 7 then use the scroller box. If it's UNDER 7 then just use a box central aligned
	if amount_of_cards_to_show > 7:
		# If OVER 7 cards then use a scrolling box container
		$SELECTION_MODE/selection_mode_scroller.visible = true
		$SELECTION_MODE/selection_mode_scroller/large_selection_mode_container.visible = true
		
		# Now display the passed through card array to the selection mode container in large pixel format
		display_hand_cards_array(card_array, $SELECTION_MODE/selection_mode_scroller/large_selection_mode_container, card_scales[5], should_hide)
		
		# If UNDER 8 cards (small array)	
	else:
		# DON'T use the scrolling box container
		$SELECTION_MODE/small_selection_mode_container.visible = true
		$SELECTION_MODE/small_selection_mode_container.custom_minimum_size = Vector2(0, 0)
		
		# Now display the passed through card array to the selection mode container in large pixel format
		display_hand_cards_array(card_array, $SELECTION_MODE/small_selection_mode_container, card_scales[amount_of_cards_to_show], should_hide)

# Both the cancel button and action button will hide selection mode so function is vaguely named for both actions
func hide_selection_mode_display_main() -> void:
	
	if selected_card_for_action != null:
		var card_ui = find_card_ui_for_object(selected_card_for_action)
		if card_ui:
			card_ui.set_selected(false)
	
	# End card selection mode and clear any selected card to prevent errors
	card_selection_mode_enabled = false
	selected_card_for_action = null  
	update_action_button()  
	
	# Hide the enlarged selection mode cards
	$SELECTION_MODE/small_selection_mode_container.visible = false
	$SELECTION_MODE/selection_mode_scroller.visible = false
	$SELECTION_MODE/selection_mode_scroller/large_selection_mode_container.visible = false
	
	# Hide the buttons
	$cancel_selection_mode_view_button.visible = false
	$BUTTONS/SELECTION_BUTTONS/card_action_button.visible = false
	
	# Show the player and opponents hands
	$CARD_COLLECTIONS/PLAYER/player_hand_hbox_container.visible = true
	$CARD_COLLECTIONS/OPPONENT/opponent_hand_hbox_container.visible = true
	
	# Show the player and opponents active pokemon
	$ACTIVE_POKEMON/PLAYER/player_active_pokemon_container.visible = true
	$ACTIVE_POKEMON/OPPONENT/opponent_active_pokemon_container.visible = true
	
	$ACTIVE_POKEMON/PLAYER/player_active_pokemon_energies.visible = true
	$ACTIVE_POKEMON/OPPONENT/opponent_active_pokemon_energies.visible = true
	
	$ACTIVE_POKEMON/PLAYER/player_active_pokemon_hp_container.visible = true
	$ACTIVE_POKEMON/OPPONENT/opponent_active_pokemon_hp_container.visible = true
	
	$BUTTONS/main_screen_buttons_container.visible = true
	
	# Show the player and oppoents bench
	$CARD_COLLECTIONS/PLAYER/player_bench_container.visible = true
	$CARD_COLLECTIONS/OPPONENT/opponent_bench_container.visible = true
	
	$SCREEN_LABELS/OPPONENT/opponent_bench_cards_label.visible = true
	$SCREEN_LABELS/PLAYER/player_bench_cards_label.visible = true
	
	$SCREEN_LABELS/OPPONENT/opponent_prize_cards_label.visible = true
	$SCREEN_LABELS/PLAYER/player_prize_cards_label.visible = true
	
	$CARD_COLLECTIONS/OPPONENT/opponent_prize_cards_container.visible = true
	$CARD_COLLECTIONS/PLAYER/player_prize_cards_container.visible = true
	
	$CARD_COLLECTIONS/PLAYER/player_deck_icon.visible = true
	$CARD_COLLECTIONS/OPPONENT/opponent_deck_icon.visible = true

	$CARD_COLLECTIONS/PLAYER/player_discard_pile_icon.visible = true
	$CARD_COLLECTIONS/OPPONENT/opponent_discard_pile_icon.visible = true
	
	update_deck_icon(false)
	update_deck_icon(true)
	
	# We do however want to show the header and hint labels
	$SCREEN_LABELS/MAIN_LABELS/small_hint_info_text_label.visible = false
	$SCREEN_LABELS/MAIN_LABELS/large_header_text_label.visible = false
	
	$BUTTONS/SELECTION_BUTTONS/card_action_button.text = "Select a Card"
	$BUTTONS/SELECTION_BUTTONS/card_action_button.disabled = true
	$BUTTONS/SELECTION_BUTTONS/card_action_button.theme = load("res://uiresources/kenneyUI.tres")
	
	# Re-enable mouse input on previously hidden containers
	$ACTIVE_POKEMON/PLAYER/player_active_pokemon_container.mouse_filter = MOUSE_FILTER_PASS
	$ACTIVE_POKEMON/OPPONENT/opponent_active_pokemon_container.mouse_filter = MOUSE_FILTER_PASS
	$CARD_COLLECTIONS/PLAYER/player_bench_container.mouse_filter = MOUSE_FILTER_PASS
	
	# Re-enable input on cards in the active pokemon containers
	for card in $ACTIVE_POKEMON/PLAYER/player_active_pokemon_container.get_children():
		card.mouse_filter = MOUSE_FILTER_PASS
	for card in $ACTIVE_POKEMON/OPPONENT/opponent_active_pokemon_container.get_children():
		card.mouse_filter = MOUSE_FILTER_PASS
	
# Displays both the player and opponents hand cards. Shows players at the top of screen and opponents in top right smaller.
func display_hand_cards_array(hand: Array, hand_container, card_size: Vector2, face_down: bool = false, max_hand_width: float = 1300.0, max_before_overlap: int = 12):
	
	# Load the script that displays card images
	var card_display_script = load("res://gdscripts/cardimage.gd")
	
	# Clear existing cards from container to prevent stale entries when cards leave or enter the hand
	for child in hand_container.get_children():
		child.queue_free()
		
	if hand_container is HBoxContainer:
		var is_inside_scroller = hand_container.get_parent() is ScrollContainer
		if not is_inside_scroller and hand.size() > max_before_overlap:
			var card_width = card_size.x
			var n = hand.size()
			var sep = (max_hand_width - (n * card_width)) / (n - 1)
			hand_container.add_theme_constant_override("separation", int(sep))
		else:
			hand_container.add_theme_constant_override("separation", 3)
	
	# Draw all cards in the hand
	for index in range(hand.size()):
		var this_card_in_hand = hand[index]
		var hand_card_to_display = TextureRect.new()
		
		# Attach the loading of the card image script to the newly generated card
		hand_card_to_display.set_script(card_display_script)
		
		# Add the newly generated card to the hand container
		hand_container.add_child(hand_card_to_display)
		
		# Load the card image with pixel sizes for hand cards
		hand_card_to_display.load_card_image(this_card_in_hand.uid, card_size, this_card_in_hand, face_down)
		
		# Connect this card's signal to the main script's handler
		hand_card_to_display.card_clicked.connect(this_card_clicked)
		
		# If this is the active Pokemon (last card in attach mode), add visual distinction
		if (card_attach_mode_active or evolution_mode_active or retreat_mode_active) and index == hand.size() - 1 and this_card_in_hand.current_location == "active":
			# Add large spacer BEFORE the active Pokemon to separate it from bench
			var spacer = Control.new()
			spacer.custom_minimum_size = Vector2(25, 0)
			spacer.mouse_filter = MOUSE_FILTER_IGNORE
			hand_container.add_child(spacer)
			hand_container.move_child(spacer, hand_container.get_child_count() - 2)  # Move to second-to-last position
			
			# Make the active Pokemon noticeably larger by reloading with bigger card_size
			var larger_size = Vector2(card_size.x * 1.2, card_size.y * 1.2)
			hand_card_to_display.load_card_image(this_card_in_hand.uid, larger_size, this_card_in_hand)
			
			# Align to bottom
			hand_card_to_display.size_flags_vertical = Control.SIZE_SHRINK_END
		else:
			hand_card_to_display.size_flags_vertical = Control.SIZE_SHRINK_END
						
# Display active and bench pokemon for either player or opponent. is_opponent: true for opponent, false for player
func display_pokemon(is_opponent: bool) -> void:
	var active_pokemon = opponent_active_pokemon if is_opponent else player_active_pokemon
	var bench_pokemon_array = opponent_bench if is_opponent else player_bench
	var active_container = $ACTIVE_POKEMON/OPPONENT/opponent_active_pokemon_container if is_opponent else $ACTIVE_POKEMON/PLAYER/player_active_pokemon_container
	var bench_container = $CARD_COLLECTIONS/OPPONENT/opponent_bench_container if is_opponent else $CARD_COLLECTIONS/PLAYER/player_bench_container
	
	# Clear active pokemon container
	for child in active_container.get_children():
		child.queue_free()
	
	# Display active pokemon if exists
	if active_pokemon != null:
		var card_display_script = load("res://gdscripts/cardimage.gd")
		var active_card_display = TextureRect.new()
		active_card_display.set_script(card_display_script)
		active_container.add_child(active_card_display)
		active_card_display.load_card_image(active_pokemon.uid, card_scales[3.5], active_pokemon)
		active_card_display.card_clicked.connect(this_card_clicked)
	
	# Clear bench container
	for child in bench_container.get_children():
		child.queue_free()
	
	# Display bench pokemon
	if bench_pokemon_array.size() > 0:
		var card_display_script = load("res://gdscripts/cardimage.gd")
		for bench_pokemon in bench_pokemon_array:
			var bench_card_display = TextureRect.new()
			bench_card_display.set_script(card_display_script)
			bench_container.add_child(bench_card_display)
			bench_card_display.load_card_image(bench_pokemon.uid, card_scales[11], bench_pokemon)
			bench_card_display.card_clicked.connect(this_card_clicked)
			
	# Display HP circles for active Pokemon
	display_hp_circles_above_align(active_pokemon, is_opponent)

# Updates the header and hint labels based on what array is being displayed
func update_selection_mode_labels(array_displayed: Array, is_starting_game: bool = false) -> void:
	
	# Special case: if we're in bench setup phase, use specific text
	if bench_setup_phase_active:
		$SCREEN_LABELS/MAIN_LABELS/large_header_text_label.text = "Build Your Bench"
		$SCREEN_LABELS/MAIN_LABELS/small_hint_info_text_label.text = "Select up to 5 Pokémon to place on your bench"
		return
	
	# Determine which array we're displaying and set appropriate text
	if array_displayed == player_hand:
		if is_starting_game:
			$SCREEN_LABELS/MAIN_LABELS/large_header_text_label.text = "Select a Basic Pokémon"
			$SCREEN_LABELS/MAIN_LABELS/small_hint_info_text_label.text = "You must place a Basic Pokémon as your Active Pokémon to start"
		else:
			$SCREEN_LABELS/MAIN_LABELS/large_header_text_label.text = "Your Hand"
			$SCREEN_LABELS/MAIN_LABELS/small_hint_info_text_label.text = "Select a card to play"
	
	elif array_displayed == player_bench:
		$SCREEN_LABELS/MAIN_LABELS/large_header_text_label.text = "Your Bench"
		$SCREEN_LABELS/MAIN_LABELS/small_hint_info_text_label.text = "Select a card to set as your Active Pokémon"
	
	elif array_displayed == opponent_hand:
		$SCREEN_LABELS/MAIN_LABELS/large_header_text_label.text = "Opponent's Hand"
		$SCREEN_LABELS/MAIN_LABELS/small_hint_info_text_label.text = "Viewing opponent's hand"
		
	elif array_displayed == opponent_bench:
		$SCREEN_LABELS/MAIN_LABELS/large_header_text_label.text = "Opponent's Bench"
		$SCREEN_LABELS/MAIN_LABELS/small_hint_info_text_label.text = "Viewing opponent's bench"
		
	elif array_displayed == player_prize_cards:
		$SCREEN_LABELS/MAIN_LABELS/large_header_text_label.text = "Your Prize Cards"
		$SCREEN_LABELS/MAIN_LABELS/small_hint_info_text_label.text = "Viewing your prize cards"
		
	elif array_displayed == opponent_prize_cards:
		$SCREEN_LABELS/MAIN_LABELS/large_header_text_label.text = "Opponent's prize cards"
		$SCREEN_LABELS/MAIN_LABELS/small_hint_info_text_label.text = "Viewing opponent's prize cards"

	elif array_displayed == player_discard_pile:
		$SCREEN_LABELS/MAIN_LABELS/large_header_text_label.text = "Your Discard Pile"
		$SCREEN_LABELS/MAIN_LABELS/small_hint_info_text_label.text = "Viewing your discard pile"
		
	elif array_displayed == opponent_discard_pile:
		$SCREEN_LABELS/MAIN_LABELS/large_header_text_label.text = "Opponent's Discard Pile"
		$SCREEN_LABELS/MAIN_LABELS/small_hint_info_text_label.text = "Viewing opponent's discard pile"

# Function to change the text, enabled mode and function of the action button.
func update_action_button() -> void:
	
	# We need to see what the button can do by running the function get_card_action
	var action_info = get_card_action(selected_card_for_action)
	var action_button = $BUTTONS/SELECTION_BUTTONS/card_action_button
	var action_type = action_info["action"]
	
	if action_type == "SET_POKEMON" and not match_just_started_basic_pokemon_required:
		if player_bench.size() >= 5:
			action_button.disabled = true
			action_button.text = "BENCH FULL"
			# If no card is selected, disable the button and change the colour to show it can't be clicked	
			action_button.theme = load("res://uiresources/kenneyUI.tres")
			return
	
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
	
	# If the match has just started, ONLY a basic pokemon can be played and SET AS ACTIVE POKEMON pokemon, not placed on bench	
	elif match_just_started_basic_pokemon_required and is_basic_pokemon(selected_card_for_action):
		
		# Match just started AND a basic pokemon is selected so card is set to active
		action_button.text = "SET AS ACTIVE POKEMON"
		
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
	
	# If the card selected was an energy card
	elif action_info["action"] == "ATTACH_ENERGY":
		# Energy card is selected and we're ready to attach it
		if player_energy_played_this_turn:
			action_button.text = "ENERGY PLAYED"
			action_button.disabled = true
			action_button.theme = load("res://uiresources/kenneyUI.tres")
		else:
			action_button.text = "ATTACH ENERGY"
			action_button.disabled = false
			action_button.theme = load("res://uiresources/kenneyUI-green.tres")
	
	elif action_info["action"] == "EVOLVE":
		var valid_targets = get_valid_evolution_targets(selected_card_for_action, false)
		if valid_targets.size() > 0:
			action_button.text = "EVOLVE"
			action_button.disabled = false
			action_button.theme = load("res://uiresources/kenneyUI-green.tres")
		else:
			action_button.text = "CANNOT EVOLVE"
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

# Displays the prize cards for the specified player in their prize cards container
func display_prize_cards(is_opponent: bool) -> void:
	
	# Get the appropriate container and prize cards array
	var prize_cards_container: HBoxContainer
	var prize_cards: Array
	
	if is_opponent:
		prize_cards_container = $CARD_COLLECTIONS/OPPONENT/opponent_prize_cards_container
		prize_cards = opponent_prize_cards		
	else:
		prize_cards_container = $CARD_COLLECTIONS/PLAYER/player_prize_cards_container
		prize_cards = player_prize_cards

	# Clear any existing cards from the container
	for child in prize_cards_container.get_children():
		child.queue_free()
	
	# If prize cards array is empty, nothing to display
	if prize_cards.size() == 0:
		return
	
	# Load the card display script
	var card_display_script = load("res://gdscripts/cardimage.gd")
	
	# Display each prize card
	for prize_card in prize_cards:
		var prize_card_display = TextureRect.new()
		
		# Attach the card display script
		prize_card_display.set_script(card_display_script)
		
		# Add to container
		prize_cards_container.add_child(prize_card_display)
		
		# Load the card image with a size appropriate for prize cards
		prize_card_display.load_card_image(prize_card.uid, card_scales[11.55], prize_card, hide_hidden_cards)
		
		# Connect the signal so prize cards can be clicked if needed
		prize_card_display.card_clicked.connect(this_card_clicked)	

# Displays attached energy cards next to the active Pokemon, stacking with overlap
func display_active_pokemon_energies(is_opponent: bool = false) -> void:
	var energy_container = $ACTIVE_POKEMON/OPPONENT/opponent_active_pokemon_energies if is_opponent else $ACTIVE_POKEMON/PLAYER/player_active_pokemon_energies
	var active_pokemon = opponent_active_pokemon if is_opponent else player_active_pokemon

	for child in energy_container.get_children():
		child.queue_free()

	if active_pokemon == null:
		return

	if active_pokemon.attached_energies.size() == 0:
		return

	var card_display_script = load("res://gdscripts/cardimage.gd")
	var energy_card_size = card_scales[11]
	var card_width = energy_card_size.x
	var overlap_offset = 80

	if active_pokemon.attached_energies.size() > 6:
		var target_width = 480.0
		var n = active_pokemon.attached_energies.size()
		overlap_offset = (target_width - card_width) / (n - 1)

	for i in range(active_pokemon.attached_energies.size()):
		var attached_energy = active_pokemon.attached_energies[i]
		var energy_display = TextureRect.new()
		energy_display.set_script(card_display_script)
		energy_container.add_child(energy_display)
		energy_display.load_card_image(attached_energy.uid, energy_card_size, attached_energy)
		energy_display.position.x = overlap_offset * i if is_opponent else -(i * overlap_offset)
		
# Displays HP circles above the active pokemon, colouring red from damage taken
func display_hp_circles_above_align(active_pokemon: card_object, is_opponent: bool) -> void:
	var hp_grid_container = $ACTIVE_POKEMON/OPPONENT/opponent_active_pokemon_hp_container if is_opponent else $ACTIVE_POKEMON/PLAYER/player_active_pokemon_hp_container
	
	for child in hp_grid_container.get_children():
		child.queue_free()
	
	hp_grid_container.columns = 12
	
	if active_pokemon == null or not active_pokemon.metadata.has("hp"):
		return
	
	var max_hp = int(active_pokemon.metadata["hp"])
	var total_circles = max_hp / 10
	var red_circles = (max_hp - active_pokemon.current_hp) / 10
	
	var circles_per_row = 12
	var bottom_row_circles = min(total_circles, circles_per_row)
	var top_row_circles = max(0, total_circles - circles_per_row)
	var top_row_spacers = circles_per_row - top_row_circles
	var bottom_row_spacers = circles_per_row - bottom_row_circles
	
	# Damage fills top row entirely first, remainder spills into bottom row
	var top_red = min(red_circles, top_row_circles)
	var bottom_red = red_circles - top_red
	
	if is_opponent:
		for i in range(top_row_circles):
			var circle = ColorRect.new()
			circle.custom_minimum_size = Vector2(30, 30)
			circle.color = Color.RED if i < top_red else Color.GREEN
			hp_grid_container.add_child(circle)
		for _i in range(top_row_spacers):
			var spacer = Control.new()
			spacer.custom_minimum_size = Vector2(30, 30)
			hp_grid_container.add_child(spacer)
	else:
		for _i in range(top_row_spacers):
			var spacer = Control.new()
			spacer.custom_minimum_size = Vector2(30, 30)
			hp_grid_container.add_child(spacer)
		for i in range(top_row_circles):
			var circle = ColorRect.new()
			circle.custom_minimum_size = Vector2(30, 30)
			circle.color = Color.RED if i < top_red else Color.GREEN
			hp_grid_container.add_child(circle)
	
	if is_opponent:
		for i in range(bottom_row_circles):
			var circle = ColorRect.new()
			circle.custom_minimum_size = Vector2(30, 30)
			circle.color = Color.RED if i >= (bottom_row_circles - bottom_red) else Color.GREEN
			hp_grid_container.add_child(circle)
		for _i in range(bottom_row_spacers):
			var spacer = Control.new()
			spacer.custom_minimum_size = Vector2(30, 30)
			hp_grid_container.add_child(spacer)
	else:
		for _i in range(bottom_row_spacers):
			var spacer = Control.new()
			spacer.custom_minimum_size = Vector2(30, 30)
			hp_grid_container.add_child(spacer)
		for i in range(bottom_row_circles):
			var circle = ColorRect.new()
			circle.custom_minimum_size = Vector2(30, 30)
			circle.color = Color.RED if i < bottom_red else Color.GREEN
			hp_grid_container.add_child(circle)

# Hides the main action buttons and generates one attack button per attack the pokemon has
func show_attack_buttons() -> void:
	if player_active_pokemon == null:
		return
	
	if turn_number <= 1:
		await show_message("You cannot attack on the first turn!")
		hide_attack_buttons()
		return
	if player_active_pokemon.special_condition == "Paralyzed":
		await show_message(player_active_pokemon.metadata.get("name", "").to_upper() + " IS PARALYZED AND CANNOT ATTACK!")
		hide_attack_buttons()
		return
	if player_active_pokemon.special_condition == "Asleep":
		await show_message(player_active_pokemon.metadata.get("name", "").to_upper() + " IS ASLEEP AND CANNOT ATTACK!")
		hide_attack_buttons()
		return
	
	$BUTTONS/main_screen_buttons_container.visible = false
	$BUTTONS/main_screen_attack_buttons_container.visible = true
	
	var attacks = get_attacks_for_card(player_active_pokemon)
	
	if attacks.size() == 0:
		print("Active pokemon has no attacks")
		return
	
	# Loop through each attack and generate a button for it
	for i in range(attacks.size()):
		var attack = attacks[i]
		var btn = Button.new()
		btn.text = attack.get("name", "Attack")
		btn.custom_minimum_size = Vector2(350, 50)
		$BUTTONS/main_screen_attack_buttons_container.add_child(btn)
		
		# Enable and colour green if requirements met, disable and grey out if not
		if check_attack_requirements(attack, player_active_pokemon):
			btn.disabled = false
			btn.theme = load("res://uiresources/kenneyUI-green.tres")
		else:
			btn.disabled = true
			btn.theme = load("res://uiresources/kenneyUI.tres")
		
		# bind(i) locks the current index into the callable so each button calls with its own attack index
		btn.pressed.connect(perform_attack.bind(i))

# Clears generated attack buttons and restores the main action buttons
func hide_attack_buttons() -> void:
	for child in $BUTTONS/main_screen_attack_buttons_container.get_children():
		# Skip the cancel button — it's a permanent node, not dynamically generated
		if child.name == "cancel_attack_mode_button":
			continue
		child.queue_free()
	
	$BUTTONS/main_screen_attack_buttons_container.visible = false
	$BUTTONS/main_screen_buttons_container.visible = true

# Displays the message box with given text and pauses execution until the player clicks
func show_message(message_text: String) -> void:
	$messagebox_container.visible = true
	$messagebox_container/messagebox_texture.visible = true
	$messagebox_container/messagebox_text_label.visible = true
	$messagebox_container/messagebox_text_label.text = message_text
	await message_acknowledged
	$messagebox_container/messagebox_text_label.visible = false
	$messagebox_container/messagebox_texture.visible = false
	$messagebox_container.visible = false

# Changes the deck icon to show how many cards are (roughly)
func update_deck_icon(is_opponent: bool) -> void:
	var deck = opponent_deck if is_opponent else player_deck
	var widget = $CARD_COLLECTIONS/OPPONENT/opponent_deck_icon if is_opponent else $CARD_COLLECTIONS/PLAYER/player_deck_icon
	var count = deck.size()

	var count_label = widget.get_node("opponent_deck_count_label") if is_opponent else widget.get_node("player_deck_count_label")
	count_label.text = str(count)

	if count == 0:
		widget.texture = null
		return

	var image_path: String
	if count >= 42:
		image_path = "res://cardimages/cardbacksanddecks/1deckfulltrans_clean.png"
	elif count >= 35:
		image_path = "res://cardimages/cardbacksanddecks/2deck3quarts.png"
	elif count >= 20:
		image_path = "res://cardimages/cardbacksanddecks/3deckhalf.png"
	elif count >= 10:
		image_path = "res://cardimages/cardbacksanddecks/4deckquarter.png"
	else:
		image_path = "res://cardimages/cardbacksanddecks/cardbacksmall.png"
	widget.texture = load(image_path)
	
# Enables or disables all main screen buttons based on current game state
func update_main_screen_buttons() -> void:
	var should_disable = (
		match_just_started_basic_pokemon_required or
		bench_setup_phase_active or
		card_selection_mode_enabled or
		opponents_turn_active or
		card_attach_mode_active or
		evolution_mode_active or
		retreat_mode_active or
		retreat_bench_selection_active
	)

	if should_disable:
		$BUTTONS/main_screen_buttons_container/button_main_attack.theme = load("res://uiresources/kenneyUI.tres")
		$BUTTONS/main_screen_buttons_container/button_main_power.theme = load("res://uiresources/kenneyUI.tres")
		$BUTTONS/main_screen_buttons_container/button_main_retreat.theme = load("res://uiresources/kenneyUI.tres")
		$BUTTONS/main_screen_buttons_container/button_main_endturn.theme = load("res://uiresources/kenneyUI.tres")
	else:
		$BUTTONS/main_screen_buttons_container/button_main_attack.theme = load("res://uiresources/kenneyUI-blue.tres")
		$BUTTONS/main_screen_buttons_container/button_main_power.theme = load("res://uiresources/kenneyUI-blue.tres")
		$BUTTONS/main_screen_buttons_container/button_main_retreat.theme = load("res://uiresources/kenneyUI-blue.tres")
		$BUTTONS/main_screen_buttons_container/button_main_endturn.theme = load("res://uiresources/kenneyUI-blue.tres")	
				
	$BUTTONS/main_screen_buttons_container/button_main_attack.disabled = should_disable
	$BUTTONS/main_screen_buttons_container/button_main_power.disabled = should_disable
	$BUTTONS/main_screen_buttons_container/button_main_retreat.disabled = should_disable
	$BUTTONS/main_screen_buttons_container/button_main_endturn.disabled = should_disable	

# Updates the discard pile icon to show the top card and count for the specified player
func update_discard_pile_display(is_opponent: bool) -> void:
	var discard = opponent_discard_pile if is_opponent else player_discard_pile
	var icon = $CARD_COLLECTIONS/OPPONENT/opponent_discard_pile_icon if is_opponent else $CARD_COLLECTIONS/PLAYER/player_discard_pile_icon
	var label_name = "opponent_discard_pile_label" if is_opponent else "player_discard_pile_label"
	
	icon.get_node(label_name).text = str(discard.size())
	
	for child in icon.get_children():
		if child is TextureRect:
			child.queue_free()
	
	if discard.size() == 0:
		return
	
	var card_display_script = load("res://gdscripts/cardimage.gd")
	var top_card = discard.back()
	var top_display = TextureRect.new()
	top_display.set_script(card_display_script)
	top_display.mouse_filter = MOUSE_FILTER_IGNORE
	icon.add_child(top_display)
	top_display.load_card_image(top_card.uid, Vector2(110, 141), top_card)
	icon.move_child(icon.get_node(label_name), -1)

# Clears and rebuilds status condition icons for a pokemon's status container
func update_status_icons(pokemon: card_object, is_opponent: bool) -> void:
	var container = $ACTIVE_POKEMON/OPPONENT/opponent_active_pokemon_status_container if is_opponent else $ACTIVE_POKEMON/PLAYER/player_active_pokemon_status_container
	for child in container.get_children():
		child.queue_free()

	var icons_to_show: Array = []

	if pokemon.special_condition == "Paralyzed":
		icons_to_show.append("status_paralyzed.png")
	if pokemon.special_condition == "Asleep":
		icons_to_show.append("status_asleep.png")
	if pokemon.special_condition == "Confused":
		icons_to_show.append("status_confused.png")
	if pokemon.is_poisoned and pokemon.poison_damage == 10:
		icons_to_show.append("status_poisoned.png")
	if pokemon.is_poisoned and pokemon.poison_damage == 20:
		icons_to_show.append("status_toxic.png")
	if pokemon.is_burned:
		icons_to_show.append("status_burned.png")
	if pokemon.is_blind:
		icons_to_show.append("status_blind.png")
	if pokemon.has_no_damage:
		icons_to_show.append("status_no_damage.png")
	if pokemon.is_invincible:
		icons_to_show.append("status_invincible.png")
	if pokemon.has_destiny_bond:
		icons_to_show.append("status_destiny_bond.png")

	for icon_file in icons_to_show:
		var icon = TextureRect.new()
		icon.texture = load("res://gameimageassets/statusicons/" + icon_file)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.custom_minimum_size = Vector2(100, 30)
		icon.size = Vector2(100, 30)
		container.add_child(icon)

############################################################### END DISPLAY FUNCTIONS ################################################################
######################################################################################################################################################

#	   ##      ####    ##  ########      ##      ##          ##    ########  ########
#     ####     ## ##   ##     ##        ####    ####        ####      ##     ##
#    ##  ##    ##  ##  ##     ##       ##  ##  ##  ##      ##  ##     ##     ########
#   ########   ##   ## ##     ##      ##    ####    ##    ########    ##     ##
#  ##      ##  ##    ####  ########  ##      ##      ##  ##      ##   ##     ########

######################################################################################################################################################
################################################################ ANIMATION FUNCTIONS #################################################################

# Creates a floating label at a given position that drifts upward and fades out over 2 seconds
func show_floating_label(message: String, spawn_position: Vector2, upwards: bool = true) -> void:
	var label = Label.new()
	label.text = message
	
	# uncomment these to make it centrally aligned instead of left aligned
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(300, 0)
	
	label.position = spawn_position
	label.modulate = Color(1, 1, 1, 1)
	
	# Apply kenney theme for the pixel font, then override colour and size
	label.theme = load("res://uiresources/kenneyUI.tres")
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 10)
	label.add_theme_font_size_override("font_size", 36)
	
	add_child(label)
	
	var tween = create_tween()
	tween.set_parallel(true)
	if upwards:
		tween.tween_property(label, "position:y", spawn_position.y - 250, 1.5)
	else:
		tween.tween_property(label, "position:y", spawn_position.y + 250, 1.5)		
	tween.tween_property(label, "modulate:a", 0.0, 1.0)
	
	await tween.finished
	label.queue_free()

# Animates a card back image sliding from one node's position to another
func animate_card_a_to_b(from_node: Control, to_node: Control, animation_speed: float = 0.8, custom_texture: Texture2D = null, custom_size: Vector2 = Vector2(83, 113)) -> void:
	$animation_input_blocker.visible = true
	var card_image = TextureRect.new()
	card_image.texture = custom_texture if custom_texture else load("res://cardimages/cardbacksanddecks/cardbacksmall.png")
	card_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	card_image.custom_minimum_size = custom_size
	card_image.size = custom_size
	card_image.z_index = 100
	add_child(card_image)
	
	card_image.global_position = from_node.global_position
	var target_pos = to_node.global_position + Vector2(to_node.size.x / 2, 0,)
	
	var tween = create_tween()
	tween.tween_property(card_image, "global_position", target_pos, animation_speed).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(card_image.queue_free)
	await tween.finished
	$animation_input_blocker.visible = false

# Animate discarding for reatreat and knockout
func animate_energies_to_discard(energy_cards: Array, pokemon: card_object, is_opponent: bool) -> void:
	var discard_node = $CARD_COLLECTIONS/OPPONENT/opponent_discard_pile_icon if is_opponent else $CARD_COLLECTIONS/PLAYER/player_discard_pile_icon
	var discard_pile = opponent_discard_pile if is_opponent else player_discard_pile
	var from_node = find_card_ui_for_object(pokemon)

	if from_node == null:
		return

	for energy in energy_cards:
		var energy_texture = get_card_texture(energy)
		animate_card_a_to_b(from_node, discard_node, 0.2, energy_texture, card_scales[10])

		# Remove this energy from the pokemon's attached list NOW,
		# so the redraw reflects one fewer energy each frame
		pokemon.attached_energies.erase(energy)

		# Actually add the energy to the discard pile array
		energy.current_location = "discard"
		discard_pile.append(energy)

		display_active_pokemon_energies(is_opponent)
		await get_tree().create_timer(0.2).timeout

	# Update the discard pile visual to show the new top card
	update_discard_pile_display(is_opponent)
				
# Animates the retreat sequence: energies to discard, message, then swap pokemon positions
func animate_retreat(old_active: card_object, new_active: card_object, discarded_energies: Array, is_opponent: bool) -> void:
	var active_container = $ACTIVE_POKEMON/OPPONENT/opponent_active_pokemon_container if is_opponent else $ACTIVE_POKEMON/PLAYER/player_active_pokemon_container
	var bench_container = $CARD_COLLECTIONS/OPPONENT/opponent_bench_container if is_opponent else $CARD_COLLECTIONS/PLAYER/player_bench_container
	
	if discarded_energies.size() > 0:
		await animate_energies_to_discard(discarded_energies, old_active, is_opponent)
		update_discard_pile_display(is_opponent)
	
	display_active_pokemon_energies()
	
	await show_message(old_active.metadata["name"].to_upper() + " RETREATED TO THE BENCH!")
	
	var old_texture = get_card_texture(old_active)
	var new_texture = get_card_texture(new_active)
	
	animate_card_a_to_b(active_container, bench_container, 0.3, old_texture, card_scales[10])
	await animate_card_a_to_b(bench_container, active_container, 0.3, new_texture, card_scales[10])

# Creates continuous sparkle particles around a given node, returns the node for manual cleanup
func start_sparkle_effect(target_node: Control) -> CPUParticles2D:
	var particles = CPUParticles2D.new()
	add_child(particles)
	
	particles.global_position = target_node.global_position + target_node.size / 2
	particles.z_index = 101
	particles.amount = 20
	particles.lifetime = 0.9
	particles.one_shot = false
	particles.explosiveness = 0.0
	particles.emitting = true

	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = target_node.size / 2
	
	particles.direction = Vector2(0, 0)
	particles.initial_velocity_min = 0.0
	particles.initial_velocity_max = 0.0
	particles.gravity = Vector2(0, 0)
	
	particles.scale_amount_min = 3.0
	particles.scale_amount_max = 6.0
	
	var sparkle_colour = get_coin_sparkle_colour()
	var bright = sparkle_colour.lightened(1)
	
	var gradient = Gradient.new()
	gradient.set_color(0, Color(bright.r, bright.g, bright.b, 0.0))
	gradient.add_point(0.3, sparkle_colour)
	gradient.add_point(0.5, bright)
	gradient.set_color(3, Color(sparkle_colour.r, sparkle_colour.g, sparkle_colour.b, 0.0))
	particles.color_ramp = gradient
	
	return particles

# Each coin can be one of a few colours so make the sparkles match	
func get_coin_sparkle_colour() -> Color:
	var coin_name = tex_heads.resource_path.to_lower()
	if "_red" in coin_name:
		return Color(1.0, 0.2, 0.2)
	elif "_gold" in coin_name:
		return Color(1.0, 0.85, 0.2)
	elif "_silver" in coin_name:
		return Color(0.85, 0.85, 0.9)
	elif "_blue" in coin_name:
		return Color(0.3, 0.5, 1.0)
	elif "_green" in coin_name:
		return Color(0.2, 0.9, 0.3)
	elif "_pink" in coin_name:
		return Color(1.0, 0.2, 0.7)
	elif "_purple" in coin_name:
		return Color(0.55, 0.1, 1)
	elif "_black" in coin_name:
		return Color(0, 0, 0)
	elif "_brown" in coin_name:
		return Color(0.5, 0.3, 0.2)
	return Color(1.0, 1.0, 1.0)

# Returns a colour for a given Pokemon type string
func get_type_colour(type_name: String) -> Color:
	match type_name.to_lower():
		"fire": return Color(1.0, 0.2, 0.1)
		"water": return Color(0.2, 0.5, 1.0)
		"grass": return Color(0.2, 0.8, 0.3)
		"lightning": return Color(1.0, 0.9, 0.1)
		"darkness": return Color(0.15, 0.1, 0.2)
		"psychic": return Color(0.55, 0.1, 1)
		"metal": return Color(0.6, 0.6, 0.65)
		"fighting": return Color(0.5, 0.3, 0.2)
		"dragon": return Color(0.9, 0.7, 0.2)
		"fairy": return Color(1.0, 0.4, 0.7)
		_: return Color(1.0, 1.0, 1.0)

# Plays a one-shot upward particle burst over a pokemon card for evolution
func play_evolution_effect(pokemon: card_object) -> void:
	var target_pos: Vector2
	var target_size: Vector2
	var is_active: bool = false

	# Determine position by checking identity against known game variables directly
	# This avoids relying on current_location or child node lookups which can be stale
	if pokemon == opponent_active_pokemon:
		target_pos = $ACTIVE_POKEMON/OPPONENT/opponent_active_pokemon_container.global_position
		target_size = card_scales[3.5]
		is_active = true
	elif pokemon == player_active_pokemon:
		target_pos = $ACTIVE_POKEMON/PLAYER/player_active_pokemon_container.global_position
		target_size = card_scales[3.5]
		is_active = true
	elif pokemon in opponent_bench:
		var index = opponent_bench.find(pokemon)
		target_size = card_scales[11]
		var separation = $CARD_COLLECTIONS/OPPONENT/opponent_bench_container.get_theme_constant("separation")
		target_pos = $CARD_COLLECTIONS/OPPONENT/opponent_bench_container.global_position + Vector2(index * (target_size.x + separation), 0)
	elif pokemon in player_bench:
		var index = player_bench.find(pokemon)
		target_size = card_scales[11]
		var separation = $CARD_COLLECTIONS/PLAYER/player_bench_container.get_theme_constant("separation")
		target_pos = $CARD_COLLECTIONS/PLAYER/player_bench_container.global_position + Vector2(index * (target_size.x + separation), 0)
	else:
		print("WARNING: play_evolution_effect - could not locate pokemon: ", pokemon.metadata["name"])
		return

	print("EVOLUTION EFFECT: ", pokemon.metadata["name"], " | active=", is_active, " | pos=", target_pos, " | size=", target_size)

	var particles = CPUParticles2D.new()
	add_child(particles)

	particles.global_position = target_pos + Vector2(target_size.x / 2, target_size.y)
	particles.z_index = 101
	particles.amount = 750
	particles.lifetime = 0.25
	particles.one_shot = true
	particles.explosiveness = 0.3

	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(target_size.x / 2, 0)

	particles.direction = Vector2(0, -1)
	particles.spread = 20
	particles.initial_velocity_min = target_size.y * 3.5
	particles.initial_velocity_max = target_size.y * 5
	particles.gravity = Vector2(0, 0)

	if is_active:
		particles.scale_amount_min = 8.0
		particles.scale_amount_max = 25.0
	else:
		particles.scale_amount_min = 3.0
		particles.scale_amount_max = 6.0

	var type_colour = get_pokemon_type_colour(pokemon)
	var darker = type_colour.darkened(0.4)

	var gradient = Gradient.new()
	gradient.set_color(0, darker)
	gradient.set_color(1, Color(type_colour.r, type_colour.g, type_colour.b, 0.0))
	particles.color_ramp = gradient

	# Set emitting AFTER all particle properties are configured
	particles.emitting = true

	await get_tree().create_timer(1).timeout
	particles.queue_free()
	
# Plays a one-shot upward particle burst when energy is attached to a pokemon
func play_energy_attached_effect(pokemon: card_object, energy_card: card_object) -> void:
	var target_pos: Vector2
	var target_size: Vector2
	var is_active: bool = false

	# Determine position by checking identity against known game variables directly
	# This avoids relying on current_location or child node lookups which can be stale
	if pokemon == opponent_active_pokemon:
		target_pos = $ACTIVE_POKEMON/OPPONENT/opponent_active_pokemon_container.global_position
		target_size = card_scales[3.5]
		is_active = true
	elif pokemon == player_active_pokemon:
		target_pos = $ACTIVE_POKEMON/PLAYER/player_active_pokemon_container.global_position
		target_size = card_scales[3.5]
		is_active = true
	elif pokemon in opponent_bench:
		var index = opponent_bench.find(pokemon)
		target_size = card_scales[11]
		var separation = $CARD_COLLECTIONS/OPPONENT/opponent_bench_container.get_theme_constant("separation")
		target_pos = $CARD_COLLECTIONS/OPPONENT/opponent_bench_container.global_position + Vector2(index * (target_size.x + separation), 0)
	elif pokemon in player_bench:
		var index = player_bench.find(pokemon)
		target_size = card_scales[11]
		var separation = $CARD_COLLECTIONS/PLAYER/player_bench_container.get_theme_constant("separation")
		target_pos = $CARD_COLLECTIONS/PLAYER/player_bench_container.global_position + Vector2(index * (target_size.x + separation), 0)
	else:
		print("WARNING: play_energy_attached_effect - could not locate pokemon: ", pokemon.metadata["name"])
		return

	print("ENERGY EFFECT: ", pokemon.metadata["name"], " | active=", is_active, " | pos=", target_pos, " | size=", target_size)

	var particles = CPUParticles2D.new()
	add_child(particles)

	particles.global_position = target_pos + Vector2(target_size.x / 2, target_size.y)
	particles.z_index = 101
	particles.amount = 1000
	particles.lifetime = 0.25
	particles.one_shot = true
	particles.explosiveness = 0

	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(target_size.x / 2, 0)

	particles.direction = Vector2(0, -1)
	particles.spread = 1
	particles.initial_velocity_min = target_size.y * 3
	particles.initial_velocity_max = target_size.y * 4.5
	particles.gravity = Vector2(0, 0)

	if is_active:
		particles.scale_amount_min = 4
		particles.scale_amount_max = 10
	else:
		particles.scale_amount_min = 1
		particles.scale_amount_max = 3
		particles.lifetime = 0.2

	var type_colour = get_type_colour(get_energy_type_from_card(energy_card))
	var darker = type_colour.darkened(0.2)

	var gradient = Gradient.new()
	gradient.set_color(0, darker)
	gradient.set_color(1, Color(type_colour.r, type_colour.g, type_colour.b, 0.0))
	particles.color_ramp = gradient

	particles.emitting = true
	await get_tree().create_timer(1).timeout
	particles.queue_free()

# Animate a quick attack effect for when an attack is used
func play_attack_animation(pokemon: card_object, is_opponent: bool) -> void:

	
	if is_opponent: 
		print("Opponent attacking")
	else:
		print("Player attacking")
		
############################################################## END ANIMATION FUNCTIONS ###############################################################
######################################################################################################################################################

#                    ##     #####      ##     #####
#                    ##    ##   ##    ####    ##   ##
#                    ##    ##   ##   ##  ##   ##    ##
#                    ##    ##   ##  ########  ##   ##
#                    #####  #####  ##      ## #####

######################################################################################################################################################
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
	var player_deck_path = "res://playerdata/"+player_deck_name+".json"
	var player_hand_container = $CARD_COLLECTIONS/PLAYER/player_hand_hbox_container
	
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
	var opponent_hand_container = $CARD_COLLECTIONS/OPPONENT/opponent_hand_hbox_container
	
	# Load the deck from the opponent data folder file
	opponent_deck = load_deck_from_file(opponent_deck_path)
	
	# Draw opening cards and mulligan
	opponent_hand = draw_opening_hand(opponent_deck, "Opponent")
	
	# Display the cards in the top right in tiny size just for visual cue
	display_hand_cards_array(opponent_hand, opponent_hand_container, card_scales[11.55], hide_hidden_cards)

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

# Draws the top 6 cards from the specified player's deck and adds them to prize cards
func draw_prize_cards(is_opponent: bool) -> void:
	
	# Get the appropriate deck and prize cards array based on whether it's player or opponent
	var deck: Array
	var prize_cards: Array
	
	if is_opponent:
		deck = opponent_deck
		prize_cards = opponent_prize_cards
	else:
		deck = player_deck
		prize_cards = player_prize_cards
	
	# Check if there are at least 6 cards in the deck
	if deck.size() < 6:
		print("Error: Not enough cards in deck to draw 6 prize cards. Current deck size: ", deck.size())
		return
	
	# Draw the top 6 cards from the deck and add them to prize cards
	for i in range(6):
		var prize_card = deck.pop_front()
		prize_cards.append(prize_card)
	
	# Display the prize cards
	display_prize_cards(is_opponent)
	
	# Sync deck icon count after prize cards are removed from deck
	update_deck_icon(is_opponent)
	
# Initiates the bench setup phase after the active pokemon is selected at game start
func start_bench_setup_phase() -> void:
		
	# Set the flag so we know we're in bench setup mode
	bench_setup_phase_active = true
	$BUTTONS/SELECTION_BUTTONS/card_action_button.text = "Select a Card"
	$BUTTONS/SELECTION_BUTTONS/card_action_button.disabled = true
	$BUTTONS/SELECTION_BUTTONS/card_action_button.theme = load("res://uiresources/kenneyUI.tres")
	
	selected_card_for_action = null
	
	$cancel_selection_mode_view_button.text = "Done"
	$cancel_selection_mode_view_button.theme = load("res://uiresources/kenneyUI-green.tres")
	
	# Show the hand again for bench pokemon selection
	show_enlarged_array_selection_mode(player_hand)	

############################################################### END GAME LOAD FUNCTIONS ##############################################################
######################################################################################################################################################
#
#                    #######  #######    #######  #######
#                    ##      ##     ##  ##        ##
#                    ##      ##     ##  ##        #######
#                    ##      ##     ##  ##        ##
#                    #######  #######   ##        #######
#
######################################################################################################################################################
############################################################ CORE FUNCTIONALITY FUNCTIONS ############################################################

# Quit the game when called
func end_game() -> void:
	get_tree().quit()
	
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
	
	if prize_card_selection_active:
		return {"action": "TAKE_PRIZE", "button_text": "TAKE PRIZE"}
	
	# We need to get the cards type whether it's trainer pokemon or energy
	var card_metadata = card.metadata
	var supertype = card_metadata.get("supertype", "").to_lower()
	
	# As a very specific piece of logic, only basic pokemon can be SET AS ACTIVE POKEMON pokemon on turn 1 and never again.
	if match_just_started_basic_pokemon_required == true:
		
		# Only a pokemon card can be played and ONLY if that pokemon card is basic
		match supertype:
			"pokémon":
				if is_basic_pokemon(card):
					# If the selected card is a basic pokemon then it can be SET AS ACTIVE POKEMON pokemon on turn one
					return {"action": "SET_POKEMON", "button_text": "SET AS ACTIVE POKEMON"}
				else:
					# Stage 1 or Stage 2 cannot be played on turn 1
					return {"action": "NONE", "button_text": "Select Basic Pokemon"}
					
			# trainers and energy cannot be played until a basic pokemon is set
			"trainer","energy":
					return {"action": "NONE", "button_text": "Select Basic Pokemon"}
	
	elif bench_setup_phase_active:
		# Only a pokemon card can be played and ONLY if that pokemon card is basic
		match supertype:
			"pokémon":
				if is_basic_pokemon(card):
					# If the selected card is a basic pokemon then it can be SET AS ACTIVE POKEMON pokemon on turn one
					return {"action": "SET_POKEMON", "button_text": "PLACE ON BENCH"}
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
	player_active_pokemon.placed_on_field_this_turn = true
	
	
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
	
	# Set max on bench to 5
	if player_bench.size() >= 5:
		print("Error: Bench is full (maximum 5 pokemon)")
		return
		
	# Validate that the card is a basic pokemon
	if not is_basic_pokemon(pokemon):
		print("Error: Cannot add non-basic pokemon to bench")
		return
	
	# Store the original location
	var original_location = pokemon.current_location
	
	# Update the card's location to "bench"
	pokemon.current_location = "bench"
	pokemon.placed_on_field_this_turn = true
	
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

# Function that get's the card position/location/object. Called from various functions when trying to find a specific card object
func find_card_ui_for_object(card_obj: card_object) -> TextureRect:
	# Check small selection container
	if $SELECTION_MODE/small_selection_mode_container.visible:
		for card_ui in $SELECTION_MODE/small_selection_mode_container.get_children():
			# Only check if this is a TextureRect with card_ref
			if card_ui is TextureRect and "card_ref" in card_ui:
				if card_ui.card_ref == card_obj:
					return card_ui
	
	# Check large selection container
	if $SELECTION_MODE/selection_mode_scroller.visible:
		for card_ui in $SELECTION_MODE/selection_mode_scroller/large_selection_mode_container.get_children():
			if card_ui is TextureRect and "card_ref" in card_ui:
				if card_ui.card_ref == card_obj:
					return card_ui
	
	# Check main screen containers
	for container in [$ACTIVE_POKEMON/PLAYER/player_active_pokemon_container, $ACTIVE_POKEMON/OPPONENT/opponent_active_pokemon_container, 
			$CARD_COLLECTIONS/PLAYER/player_bench_container, $CARD_COLLECTIONS/OPPONENT/opponent_bench_container,
			$ACTIVE_POKEMON/PLAYER/player_active_pokemon_energies, $ACTIVE_POKEMON/OPPONENT/opponent_active_pokemon_energies,
			$CARD_COLLECTIONS/PLAYER/player_hand_hbox_container, $CARD_COLLECTIONS/OPPONENT/opponent_hand_hbox_container]:
		for card_ui in container.get_children():
			if card_ui is TextureRect and "card_ref" in card_ui:
				if card_ui.card_ref == card_obj:
					return card_ui
	
	return null

# Function called when selecting an energy card to attach to a pokemon. Calls show enlarged array as a subfunction	
func start_energy_attachment() -> void:
	# Validate that an energy card is selected
	if selected_card_for_action == null:
		print("Error: No energy card selected for attachment")
		return
	
	# Store the energy card for later attachment
	energy_card_awaiting_target = selected_card_for_action
	
	# Create temporary array of valid attachment targets
	var attachment_targets = []
	
	attachment_targets.append_array(player_bench)
	if player_active_pokemon != null:
		attachment_targets.append(player_active_pokemon)
	
	
	# Enter attach mode and show only valid targets
	card_attach_mode_active = true
	show_enlarged_array_selection_mode(attachment_targets)
	
	# Update labels for energy attachment context
	var energy_name = energy_card_awaiting_target.metadata.get("name", "Unknown Energy")
	$SCREEN_LABELS/MAIN_LABELS/large_header_text_label.text = "ATTACHING " + energy_name.to_upper()
	$SCREEN_LABELS/MAIN_LABELS/small_hint_info_text_label.text = "Select a Pokémon to attach " + energy_name + " to"
	
	# Update action button text
	$BUTTONS/SELECTION_BUTTONS/card_action_button.text = "ATTACH ENERGY"
	
# Add this new function after start_energy_attachment()
func perform_energy_attachment() -> void:
	# Validate that we have an energy card awaiting attachment
	if energy_card_awaiting_target == null:
		print("Error: No energy card awaiting attachment")
		return
	
	var energy_card = energy_card_awaiting_target
	
	# Validate that we have a target Pokemon selected
	if selected_card_for_action == null:
		print("Error: No target Pokemon selected")
		return
	
	# Get the target Pokemon
	var target_pokemon = selected_card_for_action
	
	# Add the energy to the Pokemon's attached energies array
	target_pokemon.attached_energies.append(energy_card_awaiting_target)
	
	print("Attached ", energy_card_awaiting_target.metadata.get("name", "Unknown Energy"), " to ", target_pokemon.metadata.get("name", "Unknown Pokemon"))
	
	# Remove the energy card from the player's hand
	player_hand.erase(energy_card_awaiting_target)
	
	# Set the flag so no more energies can be attached this turn
	player_energy_played_this_turn = true
	
	# Clear the attachment variables
	energy_card_awaiting_target = null
	selected_card_for_action = null
	
	# Exit attach mode
	card_attach_mode_active = false
	
	# Return to normal UI
	hide_selection_mode_display_main()
	
	# Refresh hand first so the energy visually disappears from it
	display_hand_cards_array(player_hand, $CARD_COLLECTIONS/PLAYER/player_hand_hbox_container, card_scales[11])
	
	# Animate energy flying from hand to the target pokemon
	var target_node = $ACTIVE_POKEMON/PLAYER/player_active_pokemon_energies if target_pokemon == player_active_pokemon else $CARD_COLLECTIONS/PLAYER/player_bench_container
	var energy_set = energy_card.uid.split("-")[0]
	var energy_texture = load("res://cardimages/" + energy_set + "/Small/" + energy_card.uid + ".png")
	await animate_card_a_to_b($CARD_COLLECTIONS/PLAYER/player_hand_hbox_container, target_node, 0.2, energy_texture, card_scales[12])
		
	# Refresh the active Pokemon display to show the attached energy
	display_pokemon(false)	
	
	# Display the attached energies on the active Pokemon
	display_active_pokemon_energies()

	await get_tree().process_frame
	await play_energy_attached_effect(target_pokemon, energy_card)

# Called when any win/loss condition is met to end the match
func game_end_logic(loser_is_player: bool) -> void:
	if loser_is_player:
		print("GAME OVER: Player has lost the game!")
		await show_message("GAME OVER: YOU LOST!!!!!")
		end_game()
	else:
		print("GAME OVER: Opponent has lost the game!")
		await show_message("CONGRATULATIONS: YOU WON!!!!!")
		end_game()

# Draws one card from the top of the deck and adds it to the hand
func draw_card_from_deck(is_opponent: bool) -> card_object:
	var deck = opponent_deck if is_opponent else player_deck
	var hand = opponent_hand if is_opponent else player_hand

	if deck.size() == 0:
		game_end_logic(not is_opponent)
		return null

	var drawn_card = deck.pop_front()
	drawn_card.current_location = "hand"
	hand.append(drawn_card)

	if is_opponent:
		await animate_card_a_to_b($CARD_COLLECTIONS/OPPONENT/opponent_deck_icon, $CARD_COLLECTIONS/OPPONENT/opponent_hand_hbox_container, 0.2)
	else:
		await animate_card_a_to_b($CARD_COLLECTIONS/PLAYER/player_deck_icon, $CARD_COLLECTIONS/PLAYER/player_hand_hbox_container,0.3)

	return drawn_card

# Resets placed_on_field_this_turn to false for all pokemon on the specified player's field
func reset_field_pokemon_turn_flags(is_opponent: bool) -> void:
	var active = opponent_active_pokemon if is_opponent else player_active_pokemon
	var bench = opponent_bench if is_opponent else player_bench

	if active != null:
		active.placed_on_field_this_turn = false

	for bench_pokemon in bench:
		bench_pokemon.placed_on_field_this_turn = false

# Called at the start of the player's turn to perform mandatory actions
func player_start_turn_checks() -> void:
	$opponent_turn_input_blocker.visible = false
	show_floating_label("Start turn", Vector2(50, 180), false)
	turn_number += 1
	print("PLAYER'S TURN START. TURN NUMBER IS ", turn_number)
	var drawn_card = await draw_card_from_deck(false)
	
	opponents_turn_active = false
	update_main_screen_buttons()
	
	if drawn_card == null:
		return

	display_hand_cards_array(player_hand, $CARD_COLLECTIONS/PLAYER/player_hand_hbox_container, card_scales[11])
	update_deck_icon(false)
	
# Called when the player presses the end turn button to reset per-turn variables and begin next turn
func player_end_turn_checks() -> void:
	$opponent_turn_input_blocker.visible = true
	opponents_turn_active = true
	update_main_screen_buttons()
	show_floating_label("End turn", Vector2(1500, 880))
	
	await check_all_knockouts()
	
	reset_field_pokemon_turn_flags(false)
	await inbetween_turn_checks(true)

# Resets shared state between turns, processes status effects, and starts the next turn
func inbetween_turn_checks(player_turn_just_ended: bool = true) -> void:
	
	# Remove end-of-turn flags and status from the pokemon whose owner's turn just ended
	if player_turn_just_ended:
		clear_end_of_turn_statuses(player_active_pokemon, false)
		player_energy_played_this_turn = false
		player_retreated_this_turn = false
		reset_field_pokemon_turn_flags(false)
	else:
		clear_end_of_turn_statuses(opponent_active_pokemon, true)
		opponent_energy_played_this_turn = false
		opponent_retreated_this_turn = false
		reset_field_pokemon_turn_flags(true)

	# Process between-turn effects (poison, burn, sleep) for both active pokemon
	if player_active_pokemon != null:
		await process_status_between_turns(player_active_pokemon, false)
	if opponent_active_pokemon != null:
		await process_status_between_turns(opponent_active_pokemon, true)

	await check_all_knockouts()

	if player_turn_just_ended:
		opponent_start_turn_checks()
	else:
		player_start_turn_checks()

# Removes statuses that expire at the end of the affected player's own turn
func clear_end_of_turn_statuses(pokemon: card_object, is_opponent: bool) -> void:
	if pokemon == null:
		return

	var pokemon_name = pokemon.metadata.get("name", "Unknown")
	var changed = false

	if pokemon.special_condition == "Paralyzed":
		pokemon.special_condition = ""
		print("END OF TURN: ", pokemon_name, " is no longer Paralyzed")
		changed = true

	if pokemon.is_blind:
		pokemon.is_blind = false
		print("END OF TURN: ", pokemon_name, " is no longer Blind")
		changed = true

	if changed:
		update_status_icons(pokemon, is_opponent)

# Removes all status conditions from a pokemon (used when retreating or evolving)
func clear_all_statuses(pokemon: card_object, is_opponent: bool) -> void:
	if pokemon == null:
		return

	var had_status = false
	if pokemon.special_condition != "":
		had_status = true
	if pokemon.is_poisoned or pokemon.is_burned or pokemon.is_blind:
		had_status = true
	if pokemon.has_no_damage or pokemon.is_invincible or pokemon.has_destiny_bond:
		had_status = true

	pokemon.special_condition = ""
	pokemon.is_poisoned = false
	pokemon.poison_damage = 10
	pokemon.is_burned = false
	pokemon.is_blind = false
	pokemon.has_no_damage = false
	pokemon.is_invincible = false
	pokemon.has_destiny_bond = false

	if had_status:
		print("STATUSES CLEARED: ", pokemon.metadata.get("name", "Unknown"))
		update_status_icons(pokemon, is_opponent)

# Scans active and bench for Pokemon that the given evolution card can legally evolve from
func get_valid_evolution_targets(evolution_card: card_object, is_opponent: bool) -> Array:
	var active = opponent_active_pokemon if is_opponent else player_active_pokemon
	var bench = opponent_bench if is_opponent else player_bench
	var valid_targets = []
	
	if turn_number <= 2:
		return []
	
	for bench_pokemon in bench:
		if not bench_pokemon.placed_on_field_this_turn:
			if can_evolve_from(evolution_card, bench_pokemon):
				valid_targets.append(bench_pokemon)
	
	if active != null and not active.placed_on_field_this_turn:
		if can_evolve_from(evolution_card, active):
			valid_targets.append(active)
	
	return valid_targets

# Stores the evolution card and enters target selection mode for the player to pick which Pokemon to evolve
func start_evolution() -> void:
	if selected_card_for_action == null:
		print("Error: No evolution card selected")
		return
	
	evolution_card_awaiting_target = selected_card_for_action
	
	var valid_targets = get_valid_evolution_targets(evolution_card_awaiting_target, false)
	
	if valid_targets.size() == 0:
		print("Error: No valid evolution targets found")
		evolution_card_awaiting_target = null
		return
	
	evolution_mode_active = true
	show_enlarged_array_selection_mode(valid_targets)
	
	var evo_name = evolution_card_awaiting_target.metadata.get("name", "Unknown")
	$SCREEN_LABELS/MAIN_LABELS/large_header_text_label.text = "EVOLVING INTO " + evo_name.to_upper()
	$SCREEN_LABELS/MAIN_LABELS/small_hint_info_text_label.text = "Select a Pokémon to evolve into " + evo_name
	
	$BUTTONS/SELECTION_BUTTONS/card_action_button.text = "EVOLVE"
	$BUTTONS/SELECTION_BUTTONS/card_action_button.disabled = true
	$BUTTONS/SELECTION_BUTTONS/card_action_button.theme = load("res://uiresources/kenneyUI.tres")

# Replaces a Pokemon on the field with its evolution, transferring all attachments and damage
func perform_evolution(is_opponent: bool) -> void:
	if evolution_card_awaiting_target == null or selected_card_for_action == null:
		print("Error: Missing evolution card or target")
		return
	
	var evo_card = evolution_card_awaiting_target
	var target_card = selected_card_for_action
	
	# Calculate damage taken on the pre-evolution to carry over
	var max_hp_old = int(target_card.metadata.get("hp", "0"))
	var damage_taken = max_hp_old - target_card.current_hp
	
	# Set the new card's HP as its max minus the carried damage
	var max_hp_new = int(evo_card.metadata.get("hp", "0"))
	evo_card.current_hp = max(1, max_hp_new - damage_taken)
	
	# Transfer all attached energies from old card to new card
	evo_card.attached_energies = target_card.attached_energies.duplicate()
	target_card.attached_energies.clear()
	
	# Transfer existing pre-evolutions then add the old card itself to the chain
	evo_card.attached_pre_evolutions = target_card.attached_pre_evolutions.duplicate()
	target_card.attached_pre_evolutions.clear()
	evo_card.attached_pre_evolutions.append(target_card)
	
	# Mark as played this turn so it can't evolve again immediately
	evo_card.placed_on_field_this_turn = true
	
	# Remove evolution card from the correct hand
	var hand = opponent_hand if is_opponent else player_hand
	hand.erase(evo_card)
	
	# Replace the target card in its current location
	evo_card.current_location = target_card.current_location
	var active = opponent_active_pokemon if is_opponent else player_active_pokemon
	var bench = opponent_bench if is_opponent else player_bench
	
	if target_card == active:
		if is_opponent:
			opponent_active_pokemon = evo_card
		else:
			player_active_pokemon = evo_card
	else:
		var bench_index = bench.find(target_card)
		if bench_index != -1:
			bench[bench_index] = evo_card
	
	print(target_card.metadata["name"], " evolved into ", evo_card.metadata["name"], "! (Damage carried: ", damage_taken, ")")
	clear_all_statuses(evo_card, is_opponent)
	 
# Sends a card and all its attachments (energies, pre-evolutions, attached cards) to the discard pile
func send_card_to_discard(card: card_object, is_opponent: bool) -> void:
	var discard = opponent_discard_pile if is_opponent else player_discard_pile
	
	for energy in card.attached_energies:
		energy.current_location = "discard"
		discard.append(energy)
	card.attached_energies.clear()
	
	for pre_evo in card.attached_pre_evolutions:
		pre_evo.current_location = "discard"
		discard.append(pre_evo)
	card.attached_pre_evolutions.clear()
	
	for attached in card.attached_cards:
		attached.current_location = "discard"
		discard.append(attached)
	card.attached_cards.clear()
	
	card.current_location = "discard"
	discard.append(card)
	
	update_discard_pile_display(is_opponent)

# Removes a prize card from the specified player's prizes and adds it to their hand with animation
func take_prize_card(card: card_object, is_opponent: bool) -> void:
	var prizes = opponent_prize_cards if is_opponent else player_prize_cards
	var hand = opponent_hand if is_opponent else player_hand
	var prize_container = $CARD_COLLECTIONS/OPPONENT/opponent_prize_cards_container if is_opponent else $CARD_COLLECTIONS/PLAYER/player_prize_cards_container
	var hand_container = $CARD_COLLECTIONS/OPPONENT/opponent_hand_hbox_container if is_opponent else $CARD_COLLECTIONS/PLAYER/player_hand_hbox_container
	
	var card_ui = find_card_ui_for_object(card)
	var card_texture = get_card_texture(card)
	
	prizes.erase(card)
	card.current_location = "hand"
	hand.append(card)
	
	display_prize_cards(is_opponent)
	
	await animate_card_a_to_b(prize_container, hand_container, 0.3, card_texture, card_scales[11])
	
	var hand_scale = card_scales[11.55] if is_opponent else card_scales[11]
	display_hand_cards_array(hand, hand_container, hand_scale)

# Opens selection mode to choose a prize card and return that as the object to put into hand
func player_pick_prize_card() -> void:
	prize_card_selection_active = true
	$BUTTONS/SELECTION_BUTTONS/card_action_button.position.x += 210
	show_enlarged_array_selection_mode(player_prize_cards)
	$SCREEN_LABELS/MAIN_LABELS/large_header_text_label.text = "TAKE A PRIZE CARD"
	$SCREEN_LABELS/MAIN_LABELS/small_hint_info_text_label.text = "Select a prize card to add to your hand"
	$cancel_selection_mode_view_button.visible = false
	$BUTTONS/SELECTION_BUTTONS/card_action_button.text = "TAKE PRIZE"
	$BUTTONS/SELECTION_BUTTONS/card_action_button.disabled = true
	$BUTTONS/SELECTION_BUTTONS/card_action_button.theme = load("res://uiresources/kenneyUI.tres")

# Checks if a Pokemon can retreat, returning a dictionary with "can_retreat" and "reason" if blocked
func can_retreat(is_opponent: bool) -> Dictionary:
	var active = opponent_active_pokemon if is_opponent else player_active_pokemon
	var bench = opponent_bench if is_opponent else player_bench
	var is_disabled = opponent_retreat_disabled if is_opponent else player_retreat_disabled
	var already_retreated = opponent_retreated_this_turn if is_opponent else player_retreated_this_turn
	
	if already_retreated:
		return {"can_retreat": false, "reason": "You have already retreated this turn!"}
	if active == null:
		return {"can_retreat": false, "reason": "No active Pokemon!"}
	if bench.size() == 0:
		return {"can_retreat": false, "reason": "Cannot retreat with no Pokemon on your bench!"}
	if is_disabled:
		return {"can_retreat": false, "reason": "You have been prevented from retreating!"}
	if active.special_condition == "Paralyzed":
		return {"can_retreat": false, "reason": active.metadata.get("name", "") + " is Paralyzed and cannot retreat!"}
	if active.special_condition == "Asleep":
		return {"can_retreat": false, "reason": active.metadata.get("name", "") + " is Asleep and cannot retreat!"}
	if active.attached_energies.size() < get_retreat_cost(active):
		return {"can_retreat": false, "reason": "Not enough energy to retreat!"}
	
	return {"can_retreat": true, "reason": ""}

# Initiates the retreat flow: validates, then shows attached energies for the player to select for discarding
func start_retreat() -> void:
	var retreat_check = can_retreat(false)
	
	if not retreat_check["can_retreat"]:
		await show_message(retreat_check["reason"])
		return
	
	var cost = get_retreat_cost(player_active_pokemon)
	
	if cost == 0:
		start_retreat_bench_selection()
		return
	
	retreat_mode_active = true
	retreat_energies_selected.clear()
	retreat_cost_remaining = cost
	
	var display_array = player_active_pokemon.attached_energies.duplicate()
	display_array.append(player_active_pokemon)
	
	show_enlarged_array_selection_mode(display_array)
	
	$SCREEN_LABELS/MAIN_LABELS/large_header_text_label.text = "RETREAT - SELECT ENERGY TO DISCARD"
	$SCREEN_LABELS/MAIN_LABELS/small_hint_info_text_label.text = "Select " + str(retreat_cost_remaining) + " energy card(s) to discard"
	$BUTTONS/SELECTION_BUTTONS/card_action_button.text = str(retreat_cost_remaining) + " ENERGY REMAINING"
	$BUTTONS/SELECTION_BUTTONS/card_action_button.disabled = true
	$BUTTONS/SELECTION_BUTTONS/card_action_button.theme = load("res://uiresources/kenneyUI.tres")

# Shows the player's bench for selecting which Pokemon to swap into the active spot
func start_retreat_bench_selection() -> void:
	selected_card_for_action = null
	retreat_mode_active = false
	retreat_bench_selection_active = true
	
	show_enlarged_array_selection_mode(player_bench)
	
	$SCREEN_LABELS/MAIN_LABELS/large_header_text_label.text = "SELECT NEW ACTIVE POKEMON"
	$SCREEN_LABELS/MAIN_LABELS/small_hint_info_text_label.text = "Choose a bench Pokemon to switch into the active spot"
	$BUTTONS/SELECTION_BUTTONS/card_action_button.text = "MAKE ACTIVE"
	$BUTTONS/SELECTION_BUTTONS/card_action_button.disabled = true
	$BUTTONS/SELECTION_BUTTONS/card_action_button.theme = load("res://uiresources/kenneyUI.tres")

# Flips a coin with animation, blocks input, shows result message, returns true for heads
func flip_coin() -> bool:
	var result: bool = (randi() % 2 == 0)

	# Show the input-blocking overlay and set initial coin image to heads
	$coin_flip_container.visible = true
	var coin = $coin_flip_container/coin_flip_texture
	coin.texture = tex_heads
	coin.visible = true
	
	# Force coin to a fixed display size regardless of source image dimensions
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.custom_minimum_size = Vector2(129, 129)
	coin.size = Vector2(129, 129)
	
	# Set pivot to center so the squish effect scales from the middle, not the top edge
	coin.pivot_offset = coin.size / 2
	var start_y = coin.position.y
	var flip_count = 12
	var half_flip_time = 0.04
	var total_time = flip_count * half_flip_time * 1.5
	
	# Position tween: arc up then back down
	var pos_tween = create_tween()
	pos_tween.tween_property(coin, "position:y", start_y - 400, total_time / 1.5).set_ease(Tween.EASE_OUT)
	pos_tween.tween_property(coin, "position:y", start_y, total_time / 1.5).set_ease(Tween.EASE_IN)
	
	# Flip tween: squish scale.y to 0, swap texture, unsquish back to 1
	var flip_tween = create_tween()
	var textures = [tex_tails, tex_heads]
	for i in flip_count:
		flip_tween.tween_property(coin, "scale:y", 0.0, half_flip_time)
		flip_tween.tween_callback(coin.set.bind("texture", textures[i % 2]))
		flip_tween.tween_property(coin, "scale:y", 1.0, half_flip_time)
	
	await flip_tween.finished
	
	# Set the final coin face to match the actual result
	coin.texture = tex_heads if result else tex_tails
	var sparkles = null
	if result:
		sparkles = start_sparkle_effect(coin)
	coin.scale.y = 1.0
	
	# Show result message using existing message system
	var result_text = "HEADS" if result else "TAILS"
	await show_message("Coin landed on " + result_text + "!")
	
	# Clean up sparkles before hiding coin
	if sparkles:
		sparkles.queue_free()
	
	# Clean up: hide the coin overlay
	$coin_flip_container.visible = false
	coin.visible = false
	
	return result
	
########################################################## END CORE FUNCTIONALITY FUNCTIONS ##########################################################
######################################################################################################################################################

#	           ##    ########  #######     ##     ######  ##   ##
#             ####      ##       ##       ####    ##      ##  ##
#            ##  ##     ##       ##      ##  ##   ##      ####
#           ########    ##       ##     ########  ##      ##  ##
#          ##      ##   ##       ##    ##      ## ######  ##    ##

######################################################################################################################################################
############################################################ ATTACK AND DAMAGE FUNCTIONS #############################################################

# Returns the attacks array for any given card object.
func get_attacks_for_card(card: card_object) -> Array:
	
	# Guard against null being passed in (e.g. no active pokemon yet)
	if card == null:
		return []
	
	# Get the attacks if they exist
	var attacks = card.metadata.get("attacks", [])
	
	return attacks

# Read an energy card passed to this function and return what energies this card actually provides.
func get_energy_provided_by_card(energy_card: card_object) -> Array:
	if energy_card == null:
		return []
	
	var supertype = energy_card.metadata.get("supertype", "").to_lower()
	if supertype != "energy":
		return []
	
	var subtypes = energy_card.metadata.get("subtypes", [])
	var card_name = energy_card.metadata.get("name", "")
	
	# Basic energy: strip " Energy" from name to get the type string
	if "Basic" in subtypes:
		var energy_type = card_name.replace(" Energy", "").strip_edges()
		return [energy_type]
	
	# Special energy: explicit name-based lookup since JSON has no structured provision data
	if "Special" in subtypes:
		match card_name:
			"Double Colorless Energy":
				return ["Colorless", "Colorless"]
			"Double Rainbow Energy":
				return ["Any", "Any"]
			_:
				print("Warning: Unknown special energy card: ", card_name)
				return []
	
	return []

# Check energy requirements of any attack passed to it and return true if requirements are met
func check_attack_requirements(attack_dict: Dictionary, pokemon_card: card_object) -> bool:
	if pokemon_card == null:
		return false
	
	var required_cost: Array = attack_dict.get("cost", [])
	if required_cost.size() == 0:
		return true
	
	# Resolve all attached energy cards into a flat pool of type strings
	var pool: Array = []
	for attached in pokemon_card.attached_energies:
		pool.append_array(get_energy_provided_by_card(attached))
	
	# Pass 1: satisfy typed requirements first, protecting them from colorless consumption
	for requirement in required_cost:
		if requirement == "Colorless":
			continue
		var exact_index = pool.find(requirement)
		if exact_index != -1:
			pool.remove_at(exact_index)
			continue
		# Fall back to an "Any" token if no exact match
		var any_index = pool.find("Any")
		if any_index != -1:
			pool.remove_at(any_index)
			continue
		return false
	
	# Pass 2: colorless requirements consume whatever tokens remain
	for requirement in required_cost:
		if requirement != "Colorless":
			continue
		if pool.size() == 0:
			return false
		pool.remove_at(0)
	
	return true

# Applies damage from the chosen attack to the opponent's active pokemon and refreshes the HP display
func perform_attack(attack_index: int) -> void:
	if opponent_active_pokemon == null:
		print("Error: No opponent active pokemon to attack")
		return
	
	var attacks = get_attacks_for_card(player_active_pokemon)
	var attack = attacks[attack_index]
	
	var raw_damage = attack.get("damage", "0")
	var numeric_damage = ""
	for character in raw_damage:
		if character.is_valid_int():
			numeric_damage += character
	var base_damage = int(numeric_damage) if numeric_damage != "" else 0

	await show_message((player_active_pokemon.metadata["name"] + " USED " + attack.get("name", "")).to_upper())
	
	if player_active_pokemon.special_condition == "Confused":
		await show_message(player_active_pokemon.metadata["name"].to_upper() + " IS CONFUSED! FLIPPING COIN...")
		var coin = await flip_coin()
		if not coin:
			var self_damage = 20
			if confusion_rules == "modern_era_confusion_rules":
				self_damage = 30
			if confusion_rules == "base_set_confusion_rules":
				var self_types = player_active_pokemon.metadata.get("types", ["Colorless"])
				var result = calculate_final_damage(self_damage, self_types, player_active_pokemon)
				self_damage = result["damage"]
			player_active_pokemon.current_hp = max(0, player_active_pokemon.current_hp - self_damage)
			await show_message("THE ATTACK FAILED! " + player_active_pokemon.metadata["name"].to_upper() + " HURT ITSELF FOR " + str(self_damage) + " DAMAGE!")
			show_floating_label("-" + str(self_damage) + "HP", Vector2(530, 300))
			display_hp_circles_above_align(player_active_pokemon, false)
			print("CONFUSED: ", player_active_pokemon.metadata["name"], " hurt itself for ", self_damage)
			hide_attack_buttons()
			await check_all_knockouts()
			await get_tree().create_timer(0.5).timeout
			player_end_turn_checks()
			return
	
	var attacking_types = player_active_pokemon.metadata.get("types", ["Colorless"])
	var result = calculate_final_damage(base_damage, attacking_types, opponent_active_pokemon)
	var final_damage = result["damage"]

	for modifier in result["modifiers"]:
		show_floating_label(modifier, Vector2(1030, 300))
		await get_tree().create_timer(0.5).timeout

	show_floating_label("-"+str(final_damage) + "HP", Vector2(1030, 300))
	
	opponent_active_pokemon.current_hp = max(0, opponent_active_pokemon.current_hp - final_damage)
	
	print(player_active_pokemon.metadata["name"] + " used " + attack.get("name", "") + " for " + str(final_damage) + " damage!")
	print(opponent_active_pokemon.metadata["name"] + " HP remaining: " + str(opponent_active_pokemon.current_hp))
	
	display_hp_circles_above_align(opponent_active_pokemon, true)
	hide_attack_buttons()
	
	var attack_text = attack.get("text", "")
	var effects = parse_card_text_effects(attack_text, player_active_pokemon.metadata.get("name", ""))
	if effects.size() > 0:
		await apply_card_text_effects(effects, player_active_pokemon, opponent_active_pokemon, false)
	
	await check_all_knockouts()
	
	await get_tree().create_timer(0.5).timeout
	player_end_turn_checks()
	
# Returns final damage and a list of modifiers applied, for display purposes
func calculate_final_damage(base_damage: int, attacking_types: Array, defending_pokemon: card_object) -> Dictionary:
	var damage = base_damage
	var modifiers_applied = []
	
	for weakness in defending_pokemon.metadata.get("weaknesses", []):
		if weakness["type"] in attacking_types:
			var value = weakness["value"]
			if "×" in value:
				var multiplier = int(value.replace("×", "").strip_edges())
				damage = damage * multiplier
				modifiers_applied.append("WEAKNESS " + value)
			elif "+" in value:
				damage = damage + int(value.replace("+", "").strip_edges())
				modifiers_applied.append("WEAKNESS " + value)
	
	for resistance in defending_pokemon.metadata.get("resistances", []):
		if resistance["type"] in attacking_types:
			var value = int(resistance["value"])
			damage = max(0, damage + value)
			modifiers_applied.append("RESISTANCE " + resistance["value"])
	
	return {"damage": damage, "modifiers": modifiers_applied}

# Checks a single Pokemon's HP and if zero or below, animates KO and discards it
func check_and_handle_knockout(pokemon: card_object, is_opponent: bool) -> bool:
	if pokemon == null or pokemon.current_hp > 0:
		return false
	
	var ko_name = pokemon.metadata.get("name", "Unknown")
	var active = opponent_active_pokemon if is_opponent else player_active_pokemon
	var bench = opponent_bench if is_opponent else player_bench
	var discard_node = $CARD_COLLECTIONS/OPPONENT/opponent_discard_pile_icon if is_opponent else $CARD_COLLECTIONS/PLAYER/player_discard_pile_icon
	var active_container = $ACTIVE_POKEMON/OPPONENT/opponent_active_pokemon_container if is_opponent else $ACTIVE_POKEMON/PLAYER/player_active_pokemon_container
	
	await show_message(ko_name.to_upper() + " WAS KNOCKED OUT!")
	
	# Grab UI references before any animations that might free nodes
	var pokemon_ui = find_card_ui_for_object(pokemon)
	var pokemon_texture = get_card_texture(pokemon)
	
	# Animate energies before send_card_to_discard clears them
	if pokemon.attached_energies.size() > 0:
		await animate_energies_to_discard(pokemon.attached_energies.duplicate(), pokemon, is_opponent)
		display_active_pokemon_energies(is_opponent)
	
	# Use the container as fallback if pokemon_ui was freed
	var from_node = pokemon_ui if is_instance_valid(pokemon_ui) else active_container

	await animate_card_a_to_b(from_node, discard_node, 0.3, pokemon_texture, card_scales[10])
	
	if pokemon == active:
		if is_opponent:
			opponent_active_pokemon = null
		else:
			player_active_pokemon = null
	elif pokemon in bench:
		bench.erase(pokemon)
	
	display_pokemon(is_opponent)
	
	# Now do the actual array manipulation
	send_card_to_discard(pokemon, is_opponent)
	
	await get_tree().create_timer(0.3).timeout
	display_hp_circles_above_align(active if pokemon != active else null, is_opponent)
	
	return true

# Scans all Pokemon on the field for both players, handles each KO, and returns a summary of what was knocked out
func check_all_knockouts() -> Dictionary:
	var results = {"player_kos": 0, "opponent_kos": 0}
	
	var player_to_check = []
	if player_active_pokemon != null:
		player_to_check.append(player_active_pokemon)
	player_to_check.append_array(player_bench.duplicate())
	
	var opponent_to_check = []
	if opponent_active_pokemon != null:
		opponent_to_check.append(opponent_active_pokemon)
	opponent_to_check.append_array(opponent_bench.duplicate())
	
	for pokemon in opponent_to_check:
		if await check_and_handle_knockout(pokemon, true):
			results["opponent_kos"] += 1
	
	for pokemon in player_to_check:
		if await check_and_handle_knockout(pokemon, false):
			results["player_kos"] += 1
			
	for i in range(results["opponent_kos"]):
		if player_prize_cards.size() > 0:
			$opponent_turn_input_blocker.visible = false
			await player_pick_prize_card()
			await prize_card_taken
			$opponent_turn_input_blocker.visible = true
	
	# Opponent takes prizes for player KOs
	for i in range(results["player_kos"]):
		if opponent_prize_cards.size() > 0:
			await opponent_take_prize_card()
	
	if results["opponent_kos"] > 0:
		await handle_post_knockout(true)
	
	if results["player_kos"] > 0:
		await handle_post_knockout(false)
	
	# Check win condition: all prize cards taken
	if player_prize_cards.size() == 0 and results["opponent_kos"] > 0:
		await show_message("YOU TOOK YOUR LAST PRIZE CARD!")
		game_end_logic(false)  # false = opponent loses
	if opponent_prize_cards.size() == 0 and results["player_kos"] > 0:
		await show_message("OPPONENT TOOK THEIR LAST PRIZE CARD!")
		game_end_logic(true)  # true = player loses

	return results

# After KOs are processed, animates a bench Pokemon moving to the active spot or ends the game
func handle_post_knockout(is_opponent: bool) -> void:
	var active = opponent_active_pokemon if is_opponent else player_active_pokemon
	var bench = opponent_bench if is_opponent else player_bench
	var active_container = $ACTIVE_POKEMON/OPPONENT/opponent_active_pokemon_container if is_opponent else $ACTIVE_POKEMON/PLAYER/player_active_pokemon_container
	var bench_container = $CARD_COLLECTIONS/OPPONENT/opponent_bench_container if is_opponent else $CARD_COLLECTIONS/PLAYER/player_bench_container
	
	if active != null:
		return
	
	if bench.size() == 0:
		await show_message("NO POKEMON REMAINING!")
		game_end_logic(not is_opponent)
		return
	
	if is_opponent:
		var cpu_eval = build_cpu_evaluation()
		var new_active = pick_best_bench_replacement(opponent_bench, player_active_pokemon, cpu_eval)
		if new_active == null:
			new_active = bench[0]

		bench.erase(new_active)
		var new_texture = get_card_texture(new_active)
		
		await animate_card_a_to_b(bench_container, active_container, 0.3, new_texture, card_scales[9])
		
		new_active.current_location = "active"
		opponent_active_pokemon = new_active
		display_pokemon(true)
		await show_message("OPPONENT SET " + new_active.metadata["name"].to_upper() + " AS THEIR ACTIVE POKEMON!")
	else:
		knockout_bench_selection_active = true
		show_enlarged_array_selection_mode(player_bench)
		$cancel_selection_mode_view_button.visible = false
		$SCREEN_LABELS/MAIN_LABELS/large_header_text_label.text = "YOUR ACTIVE POKEMON WAS KNOCKED OUT"
		$SCREEN_LABELS/MAIN_LABELS/small_hint_info_text_label.text = "Choose a bench Pokemon to set as your new active"
		$BUTTONS/SELECTION_BUTTONS/card_action_button.text = "SELECT POKEMON"
		$BUTTONS/SELECTION_BUTTONS/card_action_button.disabled = true
		$opponent_turn_input_blocker.visible = false
		$BUTTONS/SELECTION_BUTTONS/card_action_button.theme = load("res://uiresources/kenneyUI.tres")
		await knockout_replacement_chosen
		$opponent_turn_input_blocker.visible = true
	
########################################################## END ATTACK AND DAMAGE FUNCTIONS ###########################################################
######################################################################################################################################################
#
#         ########  ########  #######  ########  #######  ########
#         ##        ##        ##       ##        ##          ##
#         ########  ########  #######  ########  ##          ##
#         ##        ##        ##       ##        ##          ##
#         ########  ##        ##       ########  #######     ##
#

######################################################################################################################################################
############################################################# EFFECT PARSING FUNCTIONS ###############################################################

# Looks backwards from an effect's position to find the nearest coin flip condition
func get_flip_context(text: String, effect_pos: int) -> String:
	var before = text.substr(0, effect_pos)
	var heads_pos = before.rfind("if heads")
	var tails_pos = before.rfind("if tails")
	if heads_pos == -1 and tails_pos == -1:
		return "none"
	if heads_pos > tails_pos:
		return "heads"
	return "tails"
		
# Searches for a defender status across three text patterns, returns position or -1
func find_defender_status_pos(text: String, status: String, has_defender_prefix: bool) -> int:
	var direct_pos = text.find("the defending pokémon is now " + status)
	if direct_pos != -1:
		return direct_pos
	if has_defender_prefix:
		var and_pos = text.find("and " + status)
		if and_pos != -1:
			return and_pos
		var it_pos = text.find("it is now " + status)
		if it_pos != -1:
			return it_pos
	return -1
	
# Parses attack effect text and returns an array of effect dictionaries for evaluation or application
func parse_card_text_effects(attack_text: String, attacker_name: String) -> Array:
	if attack_text == "":
		return []
	
	var effects: Array = []
	var text = attack_text.to_lower()
	var lower_name = attacker_name.to_lower()
	var has_defender_prefix = "the defending pokémon is now" in text
	
	# --- STATUS: Defender status conditions ---
	var defender_statuses = ["paralyzed", "asleep", "poisoned", "confused", "burned"]
	for status in defender_statuses:
		var pos = find_defender_status_pos(text, status, has_defender_prefix)
		if pos != -1:
			var flip = get_flip_context(text, pos)
			effects.append({"type": "status", "target": "defender", "status": status.capitalize(), "flip": flip})
			print("EFFECT PARSED: Status -> Defender ", status.capitalize(), " | Flip: ", flip)
	
	# --- STATUS: Self-inflicted status (attacker name used instead of "defending") ---
	var self_statuses = ["confused", "asleep", "poisoned", "paralyzed", "burned"]
	for status in self_statuses:
		if lower_name + " is now " + status in text:
			var pos = text.find(lower_name + " is now " + status)
			var flip = get_flip_context(text, pos)
			effects.append({"type": "status", "target": "self", "status": status.capitalize(), "flip": flip})
			print("EFFECT PARSED: Status -> Self ", status.capitalize(), " | Flip: ", flip)
	
	if effects.size() == 0:
		print("EFFECT PARSED: No recognised effects in: ", text.left(80))
	
	return effects

# Applies parsed effect dictionaries to the game state with coin flip gating
func apply_card_text_effects(effects: Array, attacker: card_object, defender: card_object, is_opponent_attacking: bool) -> void:
	var flip_result: String = ""
	var needs_flip: bool = false
	for effect in effects:
		if effect.get("flip", "none") != "none":
			needs_flip = true
			break

	if needs_flip:
		var coin = await flip_coin()
		flip_result = "heads" if coin else "tails"

	for effect in effects:
		var required_flip = effect.get("flip", "none")
		if required_flip != "none" and flip_result != required_flip:
			print("EFFECT SKIPPED: Needed ", required_flip, " but got ", flip_result)
			continue

		if effect["type"] == "status":
			await apply_status_effect(effect, attacker, defender, is_opponent_attacking)

# Applies a single parsed status effect to the correct pokemon and updates the UI
func apply_status_effect(effect: Dictionary, attacker: card_object, defender: card_object, is_opponent_attacking: bool) -> void:
	var target_pokemon: card_object
	var is_target_opponent: bool
	if effect["target"] == "defender":
		target_pokemon = defender
		is_target_opponent = !is_opponent_attacking
	else:
		target_pokemon = attacker
		is_target_opponent = is_opponent_attacking

	var status = effect["status"]
	var mutually_exclusive = ["Paralyzed", "Asleep", "Confused"]

	if status in mutually_exclusive:
		target_pokemon.special_condition = status
	if status == "Poisoned":
		target_pokemon.is_poisoned = true
		target_pokemon.poison_damage = 10
	if status == "Burned":
		target_pokemon.is_burned = true

	await show_message(target_pokemon.metadata["name"].to_upper() + " IS NOW " + status.to_upper() + "!")
	print("STATUS APPLIED: ", target_pokemon.metadata["name"], " is now ", status)
	update_status_icons(target_pokemon, is_target_opponent)

# Processes poison damage, burn damage/flip, and sleep wake-up between turns for one pokemon
func process_status_between_turns(pokemon: card_object, is_opponent: bool) -> void:
	if pokemon == null:
		return

	var pokemon_name = pokemon.metadata.get("name", "Unknown")

	if pokemon.is_poisoned:
		pokemon.current_hp = max(0, pokemon.current_hp - pokemon.poison_damage)
		var label = "TOXIC" if pokemon.poison_damage == 20 else "POISON"
		await show_message(pokemon_name.to_upper() + " TAKES " + str(pokemon.poison_damage) + " " + label + " DAMAGE!")
		show_floating_label("-" + str(pokemon.poison_damage) + "HP", Vector2(530 if !is_opponent else 1030, 300), is_opponent)
		display_hp_circles_above_align(pokemon, is_opponent)
		print("BETWEEN TURNS: ", pokemon_name, " took ", pokemon.poison_damage, " poison damage. HP: ", pokemon.current_hp)

	if pokemon.is_burned:
		if burn_rules == "base_set_burn_rules":
			await show_message(pokemon_name.to_upper() + " IS BURNED! FLIPPING COIN...")
			var coin = await flip_coin()
			if not coin:
				pokemon.current_hp = max(0, pokemon.current_hp - 20)
				await show_message(pokemon_name.to_upper() + " TAKES 20 BURN DAMAGE!")
				show_floating_label("-20HP", Vector2(530 if !is_opponent else 1030, 300), is_opponent)
				display_hp_circles_above_align(pokemon, is_opponent)
				print("BETWEEN TURNS: ", pokemon_name, " took 20 burn damage. HP: ", pokemon.current_hp)
			else:
				await show_message(pokemon_name.to_upper() + " AVOIDED BURN DAMAGE!")
				print("BETWEEN TURNS: ", pokemon_name, " avoided burn damage (heads)")
		elif burn_rules == "modern_era_burn_rules":
			pokemon.current_hp = max(0, pokemon.current_hp - 20)
			await show_message(pokemon_name.to_upper() + " TAKES 20 BURN DAMAGE!")
			show_floating_label("-20HP", Vector2(530 if !is_opponent else 1030, 300), is_opponent)
			display_hp_circles_above_align(pokemon, is_opponent)
			print("BETWEEN TURNS: ", pokemon_name, " took 20 burn damage. HP: ", pokemon.current_hp)
			await show_message("FLIPPING COIN TO CURE BURN...")
			var coin = await flip_coin()
			if coin:
				pokemon.is_burned = false
				await show_message(pokemon_name.to_upper() + " IS NO LONGER BURNED!")
				update_status_icons(pokemon, is_opponent)
				print("BETWEEN TURNS: ", pokemon_name, " cured of burn (heads)")

	if pokemon.special_condition == "Asleep":
		await show_message(pokemon_name.to_upper() + " IS ASLEEP! FLIPPING COIN...")
		var coin = await flip_coin()
		if coin:
			pokemon.special_condition = ""
			await show_message(pokemon_name.to_upper() + " WOKE UP!")
			update_status_icons(pokemon, is_opponent)
			print("BETWEEN TURNS: ", pokemon_name, " woke up (heads)")
		else:
			await show_message(pokemon_name.to_upper() + " IS STILL ASLEEP!")
			print("BETWEEN TURNS: ", pokemon_name, " still asleep (tails)")

# Checks confusion retreat rules at the given phase, returns true if retreat should proceed
func check_confused_retreat(pokemon: card_object, is_opponent: bool, phase: String) -> bool:
	if pokemon.special_condition != "Confused":
		return true
	if confusion_rules == "modern_era_confusion_rules":
		return true

	var pokemon_name = pokemon.metadata.get("name", "Unknown")

	if confusion_rules == "fairer_confusion_rules" and phase == "pre_energy":
		await show_message(pokemon_name.to_upper() + " IS CONFUSED! FLIPPING COIN TO RETREAT...")
		var coin = await flip_coin()
		if not coin:
			pokemon.current_hp = max(0, pokemon.current_hp - 20)
			await show_message("RETREAT FAILED! " + pokemon_name.to_upper() + " HURT ITSELF FOR 20 DAMAGE!")
			var label_x = 1030 if is_opponent else 530
			show_floating_label("-20HP", Vector2(label_x, 300), is_opponent)
			display_hp_circles_above_align(pokemon, is_opponent)
			if is_opponent:
				opponent_retreated_this_turn = true
			else:
				player_retreated_this_turn = true
			print("CONFUSED RETREAT FAILED: ", pokemon_name, " took 20 damage (fairer rules)")
			return false
		print("CONFUSED RETREAT PASSED: ", pokemon_name, " can retreat (fairer rules)")
		return true

	if confusion_rules == "base_set_confusion_rules" and phase == "post_energy":
		await show_message(pokemon_name.to_upper() + " IS CONFUSED! FLIPPING COIN TO RETREAT...")
		var coin = await flip_coin()
		if not coin:
			await show_message("RETREAT FAILED! ENERGY WAS STILL DISCARDED!")
			if is_opponent:
				opponent_retreated_this_turn = true
			else:
				player_retreated_this_turn = true
			print("CONFUSED RETREAT FAILED: ", pokemon_name, " lost energy but stayed (base set rules)")
			return false
		print("CONFUSED RETREAT PASSED: ", pokemon_name, " can retreat (base set rules)")
		return true

	return true

########################################################### END EFFECT PARSING FUNCTIONS #############################################################
######################################################################################################################################################

#                ##      ##      ########  ####    ##  ########
#               ####    ####        ##     ## ##   ##     ##
#              ##  ##  ##  ##       ##     ##  ##  ##     ##
#             ##    ####    ##      ##     ##   ## ##     ##
#            ##      ##      ##  ########  ##    ####   #######

######################################################################################################################################################
################################################### SMALL FUNCTIONS TO HELP WITH CODE READABILITY ####################################################

# Function to get all basic pokemon from a given array of cards
func get_all_basic_pokemon(card_array: Array) -> Array:
	var basic_pokemon = []
	for card in card_array:
		if card.metadata.get("supertype") == "Pokémon" and card.metadata.has("subtypes") and card.metadata["subtypes"].has("Basic"):
			basic_pokemon.append(card)
	return basic_pokemon

# Function mainly just for readability in the code to check if a pokemon can evolve from another pokemon by checking the evolving pokemon's "evolvesFrom" metadata
func can_evolve_from(evolving_pokemon: card_object, base_pokemon: card_object) -> bool:
	if evolving_pokemon.metadata.has("evolvesFrom"):
		return evolving_pokemon.metadata["evolvesFrom"] == base_pokemon.metadata.get("name", "")
	return false

# Function to check if a card is a basic energy card (not special energy like Double Colorless)
func is_basic_energy_card(card: card_object) -> bool:
	if card.metadata.get("supertype") != "Energy":
		return false
	
	if card.metadata.has("subtypes") and card.metadata["subtypes"].has("Basic"):
		return true
	
	return false

# Function to get the energy type from an energy card name
func get_energy_type_from_card(energy_card: card_object) -> String:
	var energy_name = energy_card.metadata.get("name", "")
	return energy_name.trim_suffix(" Energy")

# Function mainly just for readability to get the pokemon type from a pokemon card
func get_pokemon_type(pokemon_card: card_object) -> String:
	if pokemon_card.metadata.has("types") and pokemon_card.metadata["types"].size() > 0:
		return pokemon_card.metadata["types"][0]
	return "Colorless"
	
# Function to get the HP of a pokemon
func get_pokemon_hp(pokemon_card: card_object) -> int:
	if pokemon_card.metadata.has("hp"):
		return int(pokemon_card.metadata["hp"])
	return 0
	
# Function to check if a basic pokemon has any Stage 1 evolution in the given card array
func has_evolution(base_pokemon: card_object, card_array: Array, stage_type: String) -> bool:
	for card in card_array:
		if card.metadata.has("subtypes") and card.metadata["subtypes"].has(stage_type):
			if can_evolve_from(card, base_pokemon):
				return true
	return false

# Returns the retreat cost count for a Pokemon, or 0 if no retreat cost exists
func get_retreat_cost(pokemon: card_object) -> int:
	if pokemon == null:
		return 0
	return pokemon.metadata.get("retreatCost", []).size()

# Loads the small card image texture for any card object by its UID
func get_card_texture(card: card_object) -> Texture2D:
	var card_set = card.uid.split("-")[0]
	return load("res://cardimages/" + card_set + "/Small/" + card.uid + ".png")	

# Returns a colour based on a Pokemon's primary type
func get_pokemon_type_colour(pokemon: card_object) -> Color:
	var types = pokemon.metadata.get("types", ["Colorless"])
	return get_type_colour(types[0])

################################################# END SMALL FUNCTIONS TO HELP WITH CODE READABILITY ##################################################
######################################################################################################################################################

# #######  ######   ##   ##        #######  ##   ##    ######    ########  #######  #######
# ##       ##   ##  ##   ##        ##       ##   ##  ##      ##     ##     ##       ## 
# ##       ######   ##   ##  ##### ##       #######  ##      ##     ##     ##       #######
# ##       ##       ##   ##        ##       ##   ##  ##      ##     ##     ##       ##
# #######  ##       #######        #######  ##   ##    ######     #######  #######  #######

######################################################################################################################################################
#################################################### OPPONENT PRIORITISE FUNCTIONALITY FUNCTIONS #####################################################

# Function to get lowest cost attack for a pokemon by looping through all attacks. Returns a dictionary with "cost" (convertedEnergyCost), "damage" (as int), and "attack_name"
func get_minimum_cost_attack(pokemon_card: card_object) -> Dictionary:
	if not pokemon_card.metadata.has("attacks") or pokemon_card.metadata["attacks"].size() == 0:
		return {}
	
	var min_cost_attack = null
	var min_cost = 999
	
	# Loop through all attacks to find the one with lowest converted energy cost
	for attack in pokemon_card.metadata["attacks"]:
		var cost = int(attack.get("convertedEnergyCost", 999))
		if cost < min_cost:
			min_cost = cost
			min_cost_attack = attack
	
	if min_cost_attack == null:
		return {}
	
	# Extract damage value - damage can be "30", "40+", "50x", "60-" or other formats
	var damage_str = min_cost_attack.get("damage", "0")
	var damage = 0
	
	# Only parse the number part, ignoring any suffixes like +, -, or x
	if damage_str != "" and damage_str[0].is_valid_int():
		var numeric_part = ""
		for numberchar in damage_str:
			if numberchar.is_valid_int():
				numeric_part += numberchar
			else:
				break
		if numeric_part != "":
			damage = int(numeric_part)
	
		#print("COST: ", min_cost)
		#print("damage: ", damage)
		#print("attack_name: ", min_cost_attack.get("name", ""))
	
	return {
		"cost": min_cost,
		"damage": damage,
		"attack_name": min_cost_attack.get("name", ""),
		"text": min_cost_attack.get("text", "")
	}
	
# Helper function to get the highest damage attack and return all its data
func get_maximum_damage_attack(pokemon_card: card_object) -> Dictionary:
	if not pokemon_card.metadata.has("attacks") or pokemon_card.metadata["attacks"].size() == 0:
		return {}
	
	var max_damage = 0
	var max_damage_attack = null
	
	for attack in pokemon_card.metadata["attacks"]:
		var damage_str = attack.get("damage", "")
		
		# Skip attacks with no damage value
		if damage_str == "" or damage_str[0].is_valid_int() == false:
			continue
		
		var numeric_part = ""
		for numericchar in damage_str:
			if numericchar.is_valid_int():
				numeric_part += numericchar
			else:
				break
		
		if numeric_part != "":
			var damage = int(numeric_part)
			if damage > max_damage:
				max_damage = damage
				max_damage_attack = attack
	
	if max_damage_attack == null:
		return {}
	
	return {
		"damage": max_damage,
		"cost": int(max_damage_attack.get("convertedEnergyCost", 1)),
		"text": max_damage_attack.get("text", ""),
		"attack_name": max_damage_attack.get("name", "")
	}

# Main function to evaluate a basic pokemon and return a score by calling criterion 1-5 and returns the total score with breakdown reasoning
func evaluate_opponents_start_setup_pokemon_choices(basic_pokemon: card_object, hand: Array) -> Dictionary:
	var total_score = 0.0
	var score_breakdown = []
	
	# Apply all 5 criteria
	var criterion_1 = criterion_1_single_energy_attack(basic_pokemon)
	total_score += criterion_1.get("score_change", 0)
	score_breakdown.append(criterion_1.get("reason", ""))
	
	var criterion_2 = criterion_2_evolution_available(basic_pokemon, hand)
	total_score += criterion_2.get("score_change", 0)
	score_breakdown.append(criterion_2.get("reason", ""))
	
	var criterion_3 = criterion_3_energy_type_match(basic_pokemon, hand)
	total_score += criterion_3.get("score_change", 0)
	score_breakdown.append(criterion_3.get("reason", ""))
	
	var criterion_4 = criterion_4_pokemon_hp(basic_pokemon)
	total_score += criterion_4.get("score_change", 0)
	score_breakdown.append(criterion_4.get("reason", ""))
	
	var criterion_5 = criterion_5_attack_damage(basic_pokemon)
	total_score += criterion_5.get("score_change", 0)
	score_breakdown.append(criterion_5.get("reason", ""))
	
	return {
		"pokemon_name": basic_pokemon.metadata.get("name", "Unknown"),
		"total_score": total_score,
		"breakdown": score_breakdown
	}

# Evaluates all basic pokemon, returns highest scorer as active and next 3 as bench
func select_opponent_pokemon_for_setup(hand: Array) -> Dictionary:
	var all_basic_pokemon = get_all_basic_pokemon(hand)
	
	if all_basic_pokemon.size() == 0:
		print("Error: No basic pokemon found in hand")
		return {"active": null, "bench": []}
	
	# Score all basic pokemon
	var scored_pokemon = []
	for pokemon in all_basic_pokemon:
		var evaluation = evaluate_opponents_start_setup_pokemon_choices(pokemon, hand)
		scored_pokemon.append({
			"pokemon": pokemon,
			"score": evaluation.get("total_score", 0),
			"breakdown": evaluation.get("breakdown", [])
		})
	
	# Sort by score (highest first)
	scored_pokemon.sort_custom(func(a, b): return a["score"] > b["score"])
	
	# First is active, next up to 3 are bench
	var active_pokemon = scored_pokemon[0]["pokemon"]
	var bench_pokemon = []
	for i in range(1, min(4, scored_pokemon.size())):
		bench_pokemon.append(scored_pokemon[i]["pokemon"])
	
	# Print results
	print("Opponent AI selected active: " + active_pokemon.metadata.get("name", "Unknown") + " (Score: " + str(int(scored_pokemon[0]["score"])) + ")")
	for reason in scored_pokemon[0]["breakdown"]:
		print("  - " + reason)
		
	print("__________________________________________________________________")
	
	print("Opponent AI selected " + str(bench_pokemon.size()) + " bench pokemon")
	for i in range(bench_pokemon.size()):
		print("  " + str(i + 1) + ". " + bench_pokemon[i].metadata.get("name", "Unknown") + " (Score: " + str(int(scored_pokemon[i + 1]["score"])) + ")")
		for reason in scored_pokemon[i+1]["breakdown"]:
			print("  - " + reason)
			
		print("__________________________________________________________________")
		
	return {
		"active": active_pokemon,
		"bench": bench_pokemon
	}

# PRIORITY CRITERION #1: Single energy attack check
# If pokemon can attack for only 1 energy: big boost (+100)
# If all attacks need 2+ energy: penalty (-50)
func criterion_1_single_energy_attack(basic_pokemon: card_object) -> Dictionary:
	var min_cost_attack = get_minimum_cost_attack(basic_pokemon)
	
	if min_cost_attack.is_empty():
		return {"score_change": 0, "reason": "No attacks found"}
	
	var min_cost = min_cost_attack.get("cost", 999)
	
	if min_cost == 1:
		return {
			"score_change": 100.0,
			"reason": "Can attack for only 1 energy. (+100 points)"
		}
	else:
		return {
			"score_change": -50.0,
			"reason": "Minimum attack cost is " + str(min_cost) + " energy. (-50 points)"
		}

# PRIORITY CRITERION #2: Check for evolution paths (Stage 1 and Stage 2)
# For Each Stage 1 evolution in hand that can evolve from the basic (+100)
# If there is a stage 1 that then also has a Stage 2 evolution then additional (+100)
func criterion_2_evolution_available(basic_pokemon: card_object, hand: Array) -> Dictionary:
	var score_change = 0.0
	var reason = "No evolutions in hand (+0)"
	var stage_1_list = []
	var has_stage_2_chain = false
	
	# Find all Stage 1 evolutions for this basic pokemon
	for card in hand:
		if card.metadata.has("subtypes") and card.metadata["subtypes"].has("Stage 1"):
			if can_evolve_from(card, basic_pokemon):
				stage_1_list.append(card)
				score_change += 100.0
	
	# Check if ANY of the Stage 1s has a Stage 2 evolution (only count once)
	if stage_1_list.size() > 0:
		for stage_1 in stage_1_list:
			if has_evolution(stage_1, hand, "Stage 2"):
				has_stage_2_chain = true
				break
		
		if has_stage_2_chain:
			score_change += 100.0
			reason = "Has " + str(stage_1_list.size()) + " Stage 1(s) with Stage 2 chain. (+"+str(score_change) +" points)"
		else:
			reason = "Has " + str(stage_1_list.size()) + " Stage 1 evolution(s) (+"+str(score_change) +" points)"
	
	return {
		"score_change": score_change,
		"reason": reason
	}
	
# PRIORITY CRITERION #3: Check if basic energy types in hand match pokemon type
# Pokemon type matches available basic energy: +30 per matching energy card
# Colorless pokemon: +15 per basic energy card in hand (flexible but lower priority)
# Pokemon type does NOT match available basic energy: -150
func criterion_3_energy_type_match(basic_pokemon: card_object, hand: Array) -> Dictionary:
	var pokemon_type = get_pokemon_type(basic_pokemon)
	
	# Count basic energy cards in hand
	var basic_energies_in_hand = []
	for card in hand:
		if is_basic_energy_card(card):
			basic_energies_in_hand.append(card)
	
	# If no basic energies at all, no match possible
	if basic_energies_in_hand.is_empty():
		return {
			"score_change": 0,
			"reason": "No basic energy cards in hand"
		}
	
	# Handle Colorless pokemon - gets +20 per basic energy available
	if pokemon_type == "Colorless":
		var score_bonus = 15.0 * basic_energies_in_hand.size()
		return {
			"score_change": score_bonus,
			"reason": "Colorless type - " + str(basic_energies_in_hand.size()) + " basic energies available (+"+str(score_bonus) +" points)"
		}
	
	# For typed pokemon, count matching energies
	var matching_energy_count = 0
	for energy_card in basic_energies_in_hand:
		var energy_type = get_energy_type_from_card(energy_card)
		if energy_type == pokemon_type:
			matching_energy_count += 1
	
	# If matching energies found
	if matching_energy_count > 0:
		var score_bonus = 30.0 * matching_energy_count
		return {
			"score_change": score_bonus,
			"reason": "Has " + str(matching_energy_count) + " " + pokemon_type + " energy card(s) (+"+str(score_bonus) +" points)"
		}
	
	# No matching energy found
	return {
		"score_change": -150.0,
		"reason": "No matching " + pokemon_type + " energy in hand (-150 points)"
	}	
	
# PRIORITY CRITERION #4: Higher HP is more durable and valuable
# Score = HP * 2
# e.g 50HP = +60
# e.g 100HP = +150
func criterion_4_pokemon_hp(basic_pokemon: card_object) -> Dictionary:
	var hp = get_pokemon_hp(basic_pokemon)
	var score_bonus = hp * 2
	
	return {
		"score_change": score_bonus,
		"reason": "HP: " + str(hp) + " (+" + str(int(score_bonus)) + " points)"
	}
	
# PRIORITY CRITERION #5: Damage output potential (either 1 bonus or 2 bonuses if more than 1 attack)
# 1-energy attack damage: damage * 3 (immediate threat). e.g 10 = +30, 20 = +60, 30 = +90
# Efficiency bonus (only if 2+ attacks): (highest_damage / energy_cost) * 3. e.g 4*Energy for 80 damage = +60
func criterion_5_attack_damage(basic_pokemon: card_object) -> Dictionary:
	if not basic_pokemon.metadata.has("attacks") or basic_pokemon.metadata["attacks"].size() == 0:
		return {
			"score_change": 0,
			"reason": "No attacks available"
		}
	
	var attack_count = basic_pokemon.metadata["attacks"].size()
	var score_bonus = 0.0
	var reason_parts = []
	
	# Check for 1-energy attack damage
	var min_cost_attack = get_minimum_cost_attack(basic_pokemon)
	if not min_cost_attack.is_empty() and min_cost_attack.get("cost") == 1:
		var one_energy_damage = min_cost_attack.get("damage", 0)
		var one_energy_bonus = one_energy_damage * 3
		score_bonus += one_energy_bonus
		reason_parts.append(str(one_energy_damage) + " damage at 1 energy (+" + str(one_energy_bonus) + " points)")
		
		# Check if the lowest cost attack has an effect (additional text)
		var attack_text = min_cost_attack.get("text", "")
		var attack_penalty = get_attack_text_penalty(attack_text, basic_pokemon.metadata.get("name", ""))
		
		if attack_penalty < 0:
			score_bonus += attack_penalty
			reason_parts.append("1-energy attack has penalty (" + str(attack_penalty) + " points)")
		elif attack_text != "":
			score_bonus += 20.0
			reason_parts.append("1-energy attack has beneficial effect (+20 points)")
	

	# Check if the lowest cost attack has an effect (additional text)	
	# Only add efficiency bonus if pokemon has 2+ attacks
	if attack_count >= 2:
		var max_attack = get_maximum_damage_attack(basic_pokemon)
		var max_damage = max_attack.get("damage", 0)
		var max_cost = max_attack.get("cost", 1)
		var attack_text = max_attack.get("text", "")
		
		# Check if highest damage attack has an effect
		var attack_penalty = get_attack_text_penalty(attack_text, basic_pokemon.metadata.get("name", ""))
		
		if attack_penalty < 0:
			score_bonus += attack_penalty
			reason_parts.append("Highest damage attack has penalty (" + str(attack_penalty) + " points)")
		elif attack_text != "":
			score_bonus += 20.0
			reason_parts.append("Highest damage attack has beneficial effect (+20 points)")
		
		# Only calculate efficiency if there's actual damage
		if max_damage > 0:
			var efficiency = float(max_damage) / float(max_cost)
			var efficiency_bonus = efficiency * 3.0
			score_bonus += efficiency_bonus
			reason_parts.append("highest damage efficiency " + str(max_damage) + "/" + str(max_cost) + " energy (+" + str(efficiency_bonus) + " points)")
	
	var reason = "Damage: " + ", ".join(reason_parts)
	
	return {
		"score_change": score_bonus,
		"reason": reason
	}	

# Helper function to check attack text for negative self-inflicted effects
# Only penalizes exact patterns where energy is discarded from the attacking pokemon
# Returns the penalty score (negative value) if found, 0 if no penalty
func get_attack_text_penalty(attack_text: String, pokemon_name: String) -> int:
	if attack_text == "":
		return 0
	
	var text = attack_text
	
	# Check for "discard all" attached to THIS pokemon (-70)
	if ("Discard all Energy cards attached to " + pokemon_name in text) or \
	   ("Discard all basic Energy cards attached to " + pokemon_name in text) or \
	   ("Discard all" in text and "Energy cards attached to " + pokemon_name in text):
		return -70
	
	# Check for "discard 3" attached to THIS pokemon (-50)
	if ("Discard 3 Energy cards attached to " + pokemon_name in text) or \
	   ("Discard 3 basic Energy cards attached to " + pokemon_name in text) or \
	   ("Discard 3" in text and "Energy cards attached to " + pokemon_name in text):
		return -50
	
	# Check for "discard 2" attached to THIS pokemon (-30)
	if ("Discard 2 Energy cards attached to " + pokemon_name in text) or \
	   ("Discard 2 basic Energy cards attached to " + pokemon_name in text) or \
	   ("Discard 2" in text and "Energy cards attached to " + pokemon_name in text):
		return -30
	
	# Check for "discard 1" or "discard a" attached to THIS pokemon (-10)
	if ("Discard 1" in text and "Energy card attached to " + pokemon_name in text) or \
	   ("Discard a" in text and "Energy card attached to " + pokemon_name in text) or \
	   ("Discard a basic Energy card attached to " + pokemon_name in text):
		return -10
	
	# Check for damage reduction effects (-20)
	if "damage minus" in text.to_lower():
		return -20
	
	# Check for self-damage effects (X damage to itself = -X*0.5)
	if pokemon_name in text and "damage to itself" in text.to_lower():
		var pattern = "does "
		var lower_text = text.to_lower()
		var start_index = lower_text.find(pattern)
		
		if start_index != -1:
			start_index += pattern.length()
			var number_str = ""
			for i in range(start_index, lower_text.length()):
				var numericalchar = lower_text[i]
				if numericalchar.is_valid_int():
					number_str += numericalchar
				elif number_str != "":
					break
			
			if number_str != "":
				var damage = int(number_str)
				var penalty = int(damage * 0.5)
				return -penalty
	
	return 0

# Criterion 2 is used simply just to check which cards have an evolution available at all. However,
# This scores each pairing (evolution_card, target_pokemon) for CPU evolution decisions, not just to check if there is one at all.
func evaluate_evolution_pair(evo_card: card_object, target: card_object) -> Dictionary:
	var score = 0.0
	var reasons = []

	# HP improvement: new max HP minus target's CURRENT HP (accounts for damage taken)
	var current_hp = target.current_hp
	var new_max_hp = int(evo_card.metadata.get("hp", "0"))
	var hp_gain = new_max_hp - current_hp
	score += hp_gain * 1.5
	reasons.append("HP gain: +" + str(hp_gain) + " (+" + str(hp_gain * 1.5) + " pts)")

	# Attack improvement: compare best damage output
	var old_best = get_maximum_damage_attack(target)
	var new_best = get_maximum_damage_attack(evo_card)
	var old_damage = old_best.get("damage", 0)
	var new_damage = new_best.get("damage", 0)
	var damage_gain = new_damage - old_damage
	score += damage_gain * 2.0
	reasons.append("Damage gain: +" + str(damage_gain) + " (+" + str(damage_gain * 2.0) + " pts)")

	# Energy compatibility: does target's attached energy satisfy any of the evolved form's attack costs
	var has_usable_attack_after = false
	for attack in evo_card.metadata.get("attacks", []):
		if check_attack_requirements(attack, target):
			has_usable_attack_after = true
			break
	if has_usable_attack_after:
		score += 150.0
		reasons.append("Can attack immediately after evolving (+150 pts)")

	# Active pokemon bonus: evolving the active is more urgent
	if target.current_location == "active":
		score += 75.0
		reasons.append("Target is active pokemon (+75 pts)")

	# Existing energy investment: more attached energy means more value preserved
	var energy_count = target.attached_energies.size()
	if energy_count > 0:
		score += energy_count * 25.0
		reasons.append("Target has " + str(energy_count) + " energy attached (+" + str(energy_count * 25.0) + " pts)")

	# Future evolution chain: check hand, deck, and prize cards
	var has_next_stage_in_hand = false
	var has_next_stage_in_deck_or_prizes = false
	for card in opponent_hand:
		if card != evo_card and can_evolve_from(card, evo_card):
			has_next_stage_in_hand = true
			break
	if not has_next_stage_in_hand:
		for card in opponent_deck + opponent_prize_cards:
			if can_evolve_from(card, evo_card):
				has_next_stage_in_deck_or_prizes = true
				break
	if has_next_stage_in_hand:
		score += 120.0
		reasons.append("Next evolution stage in hand (+120 pts)")
	elif has_next_stage_in_deck_or_prizes:
		score += 40.0
		reasons.append("Next evolution stage in deck or prizes (+40 pts)")

	return {
		"score": score,
		"evo_card": evo_card,
		"target": target,
		"reasons": reasons
	}
			
# Computes all Phase 1 helper evaluations and returns them as a dictionary
func build_cpu_evaluation() -> Dictionary:
	var eval = {}

	# Game state context (1.14, 1.15)
	eval["cpu_prizes_remaining"] = opponent_prize_cards.size()
	eval["player_prizes_remaining"] = player_prize_cards.size()
	eval["game_phase"] = "late" if (eval["cpu_prizes_remaining"] <= 2 or eval["player_prizes_remaining"] <= 2) else "early"

	# KO threat assessment (1.1, 1.2, 1.3)
	eval.merge(evaluate_ko_threats())

	# Per-pokemon data: energy requirements, evolution potential, attack readiness
	eval["pokemon_data"] = {}
	var all_cpu_pokemon = get_all_cpu_field_pokemon()
	for pokemon in all_cpu_pokemon:
		var key = pokemon.get_instance_id()
		eval["pokemon_data"][key] = evaluate_single_pokemon(pokemon)

	# CPU offensive capability (1.11, 1.13)
	eval["cpu_can_ko_player_active"] = can_cpu_ko_player_active()
	eval["has_viable_bench_attacker"] = check_viable_bench_attacker()

	return eval

# Returns an array of all CPU pokemon currently on the field (active + bench)
func get_all_cpu_field_pokemon() -> Array:
	var pokemon = []
	if opponent_active_pokemon != null:
		pokemon.append(opponent_active_pokemon)
	pokemon.append_array(opponent_bench)
	return pokemon

# Evaluates a single pokemon's energy requirements, attack readiness, and evolution potential
func evaluate_single_pokemon(pokemon: card_object) -> Dictionary:
	var data = {}

	# 1.4 and 1.5: Per-attack unmet energy and overall attack readiness
	var attack_data = []
	var can_attack = false
	for attack in pokemon.metadata.get("attacks", []):
		var unmet = get_unmet_energy_count(attack, pokemon)
		var damage_range = get_attack_damage_range(attack)
		attack_data.append({
			"name": attack.get("name", ""),
			"cost": attack.get("cost", []),
			"unmet": unmet,
			"damage_min": damage_range["min"],
			"damage_max": damage_range["max"],
			"text": attack.get("text", "")
		})
		if unmet == 0:
			can_attack = true
	data["attack_data"] = attack_data
	data["can_attack"] = can_attack

	# 1.7: Evolution in hand
	data["evolution_in_hand"] = null
	for card in opponent_hand:
		if can_evolve_from(card, pokemon):
			data["evolution_in_hand"] = card
			break

	# 1.8: Evolution in deck or prize cards
	data["evolution_in_deck_or_prizes"] = false
	if data["evolution_in_hand"] == null:
		for card in opponent_deck + opponent_prize_cards:
			if can_evolve_from(card, pokemon):
				data["evolution_in_deck_or_prizes"] = true
				break

	# 1.10: Can evolve further (check all sources)
	data["can_evolve_further"] = data["evolution_in_hand"] != null or data["evolution_in_deck_or_prizes"]

	# 1.9: If evolution exists, does the evolved form need more energy than currently attached
	data["evolved_form_needs_energy"] = false
	var evo_card = data["evolution_in_hand"]
	if evo_card == null:
		# Check deck/prizes for the actual card data to inspect attacks
		for card in opponent_deck + opponent_prize_cards:
			if can_evolve_from(card, pokemon):
				evo_card = card
				break
	if evo_card != null:
		for attack in evo_card.metadata.get("attacks", []):
			if get_unmet_energy_count(attack, pokemon) > 0:
				data["evolved_form_needs_energy"] = true
				break

	return data

# Parses an attack's damage string and returns min/max estimate (placeholder until full effect parsing)
func get_attack_damage_range(attack: Dictionary) -> Dictionary:
	var damage_str = str(attack.get("damage", "0"))

	var numeric_part = ""
	for character in damage_str:
		if character.is_valid_int():
			numeric_part += character
		else:
			break
	var base_damage = int(numeric_part) if numeric_part != "" else 0

	# Fixed damage: no suffix
	if damage_str == numeric_part or damage_str == "":
		return {"min": base_damage, "max": base_damage}

	# "x" suffix: assume min 0, max double base as rough estimate
	if "x" in damage_str or "×" in damage_str:
		return {"min": 0, "max": base_damage * 2}

	# "+" suffix: base is guaranteed, estimate +10 bonus
	if "+" in damage_str:
		return {"min": base_damage, "max": base_damage + 10}

	# "-" suffix: could be reduced to 0, base is max
	if "-" in damage_str:
		return {"min": 0, "max": base_damage}

	# TODO: Replace estimates above with parsed_effect_total_damage() call

	return {"min": base_damage, "max": base_damage}

# Evaluates KO threats from the player against the CPU's active pokemon (1.1, 1.2, 1.3)
func evaluate_ko_threats() -> Dictionary:
	var result = {
		"cpu_active_guaranteed_ko": false,
		"cpu_active_potential_ko": false,
		"player_bench_ko_threat": false
	}

	if opponent_active_pokemon == null or player_active_pokemon == null:
		return result

	var cpu_active_hp = opponent_active_pokemon.current_hp
	var player_types = player_active_pokemon.metadata.get("types", ["Colorless"])

	# 1.1 and 1.2: Check each attack on the player's active pokemon
	for attack in player_active_pokemon.metadata.get("attacks", []):
		var unmet = get_unmet_energy_count(attack, player_active_pokemon)
		# Skip if player can't use this attack even with one more energy
		if unmet > 1:
			continue
		var damage_range = get_attack_damage_range(attack)
		var min_result = calculate_final_damage(damage_range["min"], player_types, opponent_active_pokemon)
		var max_result = calculate_final_damage(damage_range["max"], player_types, opponent_active_pokemon)

		if unmet == 0:
			# Attack is usable right now
			if min_result["damage"] >= cpu_active_hp:
				result["cpu_active_guaranteed_ko"] = true
			elif max_result["damage"] >= cpu_active_hp:
				result["cpu_active_potential_ko"] = true
		else:
			# Attack is 1 energy away — treat as potential since player will likely attach
			if min_result["damage"] >= cpu_active_hp:
				result["cpu_active_potential_ko"] = true

	# 1.3: Check if player could retreat into a bench KO threat
	var retreat_cost = get_retreat_cost(player_active_pokemon)
	var current_energy = player_active_pokemon.attached_energies.size()
	# Player can retreat now, or is 1 energy away from retreating
	var player_can_retreat = current_energy >= retreat_cost or current_energy >= (retreat_cost - 1)

	if player_can_retreat:
		for bench_pokemon in player_bench:
			var bench_types = bench_pokemon.metadata.get("types", ["Colorless"])
			for attack in bench_pokemon.metadata.get("attacks", []):
				var unmet = get_unmet_energy_count(attack, bench_pokemon)
				# Bench pokemon needs to be ready now — player can only attach 1 energy total
				# If they spend it on retreat cost they can't also power up the bench attacker
				if unmet > 0:
					continue
				var damage_range = get_attack_damage_range(attack)
				var min_result = calculate_final_damage(damage_range["min"], bench_types, opponent_active_pokemon)
				if min_result["damage"] >= cpu_active_hp:
					result["player_bench_ko_threat"] = true
					break
			if result["player_bench_ko_threat"]:
				break

	return result

# Returns how many energy cards a pokemon still needs to use a specific attack
func get_unmet_energy_count(attack: Dictionary, pokemon: card_object) -> int:
	var required_cost = attack.get("cost", [])
	if required_cost.size() == 0:
		return 0

	var pool = []
	for attached in pokemon.attached_energies:
		pool.append_array(get_energy_provided_by_card(attached))

	var unmet = 0

	# Pass 1: typed requirements first
	for requirement in required_cost:
		if requirement == "Colorless":
			continue
		var exact_index = pool.find(requirement)
		if exact_index != -1:
			pool.remove_at(exact_index)
		else:
			var any_index = pool.find("Any")
			if any_index != -1:
				pool.remove_at(any_index)
			else:
				unmet += 1

	# Pass 2: colorless requirements consume whatever remains
	for requirement in required_cost:
		if requirement != "Colorless":
			continue
		if pool.size() > 0:
			pool.remove_at(0)
		else:
			unmet += 1

	return unmet

# Checks if the CPU's active can KO the player's active with currently usable attacks (1.11)
func can_cpu_ko_player_active() -> bool:
	if opponent_active_pokemon == null or player_active_pokemon == null:
		return false

	var cpu_types = opponent_active_pokemon.metadata.get("types", ["Colorless"])
	var player_hp = player_active_pokemon.current_hp

	for attack in opponent_active_pokemon.metadata.get("attacks", []):
		if get_unmet_energy_count(attack, opponent_active_pokemon) > 0:
			continue
		var damage_range = get_attack_damage_range(attack)
		var result = calculate_final_damage(damage_range["min"], cpu_types, player_active_pokemon)
		if result["damage"] >= player_hp:
			return true

	return false

# Checks if any bench pokemon is ready or near-ready to attack and can survive a hit (1.13)
func check_viable_bench_attacker() -> bool:
	if player_active_pokemon == null:
		return false

	var player_types = player_active_pokemon.metadata.get("types", ["Colorless"])

	# Find the player's strongest currently usable attack damage
	var player_max_damage = 0
	for attack in player_active_pokemon.metadata.get("attacks", []):
		if get_unmet_energy_count(attack, player_active_pokemon) > 0:
			continue
		var damage_range = get_attack_damage_range(attack)
		var result = calculate_final_damage(damage_range["max"], player_types, opponent_active_pokemon)
		player_max_damage = max(player_max_damage, result["damage"])

	for bench_pokemon in opponent_bench:
		var is_ready = false
		for attack in bench_pokemon.metadata.get("attacks", []):
			var unmet = get_unmet_energy_count(attack, bench_pokemon)
			if unmet > 1:
				continue
			# Ready now, or 1 energy away with a matching energy in hand
			if unmet == 0:
				is_ready = true
				break
			for card in opponent_hand:
				if card.metadata.get("supertype", "").to_lower() != "energy":
					continue
				var energy_types = get_energy_provided_by_card(card)
				var cost = attack.get("cost", [])
				for req in cost:
					if req in energy_types or req == "Colorless":
						is_ready = true
						break
				if is_ready:
					break
			if is_ready:
				break

		if not is_ready:
			continue

		# Check if this bench pokemon would survive the player's strongest attack
		var bench_types = bench_pokemon.metadata.get("types", ["Colorless"])
		var damage_to_bench = calculate_final_damage(player_max_damage, player_types, bench_pokemon)
		if bench_pokemon.current_hp > damage_to_bench["damage"]:
			return true

	return false

# R.2, R.4: Evaluates whether the energy cost of retreating is worth paying
func is_retreat_cost_worthwhile(cpu_eval: Dictionary) -> bool:
	var active = opponent_active_pokemon
	var retreat_cost = get_retreat_cost(active)
	var active_key = active.get_instance_id()
	var active_data = cpu_eval["pokemon_data"].get(active_key, {})

	# Free retreat is always worthwhile
	if retreat_cost == 0:
		return true

	# Check what state the active ends up in after losing retreat cost energy
	var energy_after_retreat = active.attached_energies.size() - retreat_cost
	var can_attack_after = false
	for attack in active.metadata.get("attacks", []):
		# Simulate the energy pool after discarding retreat cost
		var simulated_pool = []
		for i in range(energy_after_retreat):
			simulated_pool.append_array(get_energy_provided_by_card(active.attached_energies[i]))
		var required = attack.get("cost", [])
		if simulated_pool.size() >= required.size():
			can_attack_after = true
			break

	# R.2 rule of thumb: if retreat strips more than half the energy needed for primary attack
	var max_attack = get_maximum_damage_attack(active)
	var primary_attack_cost = max_attack.get("cost", 1)
	var energy_lost_ratio = float(retreat_cost) / float(max(primary_attack_cost, 1))

	# R.4: High-investment pokemon preservation overrides the ratio check
	var guaranteed_ko = cpu_eval.get("cpu_active_guaranteed_ko", false)
	var has_evo = active_data.get("can_evolve_further", false)
	var high_investment = active.attached_energies.size() >= 3 or has_evo
	var high_hp = active.current_hp > int(active.metadata.get("hp", "0")) * 0.5

	if guaranteed_ko and high_investment and high_hp:
		print("CPU retreat worthwhile: preserving high-investment pokemon")
		return true

	# Losing more than half the energy for primary attack is generally bad
	if energy_lost_ratio > 0.5 and not can_attack_after:
		print("CPU retreat not worthwhile: would lose " + str(retreat_cost) + " energy and cannot attack from bench")
		return false

	# If active can still contribute from the bench after retreating, it's worthwhile
	if can_attack_after:
		print("CPU retreat worthwhile: active retains enough energy to attack from bench")
		return true

	# Default: retreat is worthwhile if there's a real threat
	if guaranteed_ko:
		return true

	return false

# Evaluates whether active should retreat before energy attachment (R.1-R.4)
func cpu_phase_retreat_first_pass(cpu_eval: Dictionary) -> bool:
	if opponent_active_pokemon == null or opponent_bench.size() == 0:
		return false
	if opponent_retreated_this_turn:
		return false
	if opponent_active_pokemon.special_condition in ["Paralyzed", "Asleep"]:
		print("CPU cannot retreat: active is ", opponent_active_pokemon.special_condition)
		return false

	# R.1: Should the active pokemon retreat?
	var should_consider = evaluate_retreat_reasons(cpu_eval)
	if not should_consider:
		return false

	var retreat_cost = get_retreat_cost(opponent_active_pokemon)
	var current_energy = opponent_active_pokemon.attached_energies.size()

	# R.3: Exactly 1 energy short — defer to after energy attachment
	if current_energy == retreat_cost - 1 and not opponent_energy_played_this_turn:
		print("CPU retreat deferred: 1 energy short, will re-evaluate after attachment")
		return true

	# R.2: Can the active actually pay retreat cost right now?
	if current_energy < retreat_cost:
		print("CPU cannot retreat: not enough energy (" + str(current_energy) + "/" + str(retreat_cost) + ")")
		return false

	# R.2 continued: Is paying the retreat cost worth the energy loss?
	if not is_retreat_cost_worthwhile(cpu_eval):
		print("CPU retreat not worthwhile: energy loss too high")
		return false

	# R.5: Pick the best replacement and execute
	await execute_cpu_retreat(cpu_eval)
	return false

# Re-evaluates retreat after energy attachment if first pass deferred (R.3)
func cpu_phase_retreat_second_pass(cpu_eval: Dictionary) -> void:
	if opponent_active_pokemon == null or opponent_bench.size() == 0:
		return
	if opponent_retreated_this_turn:
		return
	if opponent_active_pokemon.special_condition in ["Paralyzed", "Asleep"]:
		print("CPU retreat second pass: active is ", opponent_active_pokemon.special_condition)
		return

	var retreat_cost = get_retreat_cost(opponent_active_pokemon)
	var current_energy = opponent_active_pokemon.attached_energies.size()

	# Verify retreat is now mechanically possible after energy attachment
	if current_energy < retreat_cost:
		print("CPU retreat second pass: still cannot pay retreat cost")
		return

	# Re-check if retreat reasons still apply with updated board state
	if not evaluate_retreat_reasons(cpu_eval):
		print("CPU retreat second pass: reasons no longer apply")
		return

	# Re-check if the cost is worthwhile
	if not is_retreat_cost_worthwhile(cpu_eval):
		print("CPU retreat second pass: cost not worthwhile")
		return

	await execute_cpu_retreat(cpu_eval)
	
# Scores each bench pokemon as a potential active replacement, returns the best choice
func pick_best_bench_replacement(bench: Array, against_pokemon: card_object, cpu_eval: Dictionary) -> card_object:
	var best_replacement: card_object = null
	var best_score: float = -999.0

	for bench_pokemon in bench:
		var score = score_bench_as_replacement(bench_pokemon, against_pokemon, cpu_eval)
		if score > best_score:
			best_score = score
			best_replacement = bench_pokemon

	return best_replacement

# Scores a single bench pokemon as a potential active replacement considering attacks, survivability, and type matchups
func score_bench_as_replacement(bench_pokemon: card_object, against_pokemon: card_object, cpu_eval: Dictionary) -> float:
	var score = 0.0
	var bench_key = bench_pokemon.get_instance_id()
	var bench_data = cpu_eval["pokemon_data"].get(bench_key, {})
	if bench_data.is_empty():
		bench_data = evaluate_single_pokemon(bench_pokemon)

	var bench_types = bench_pokemon.metadata.get("types", ["Colorless"])

	# Can already attack: strong preference
	if bench_data.get("can_attack", false):
		score += 200.0

	# Among attackers, prefer one that can KO the opposing active
	if bench_data.get("can_attack", false) and against_pokemon != null:
		for attack in bench_data.get("attack_data", []):
			if attack["unmet"] > 0:
				continue
			var result = calculate_final_damage(attack["damage_min"], bench_types, against_pokemon)
			if result["damage"] >= against_pokemon.current_hp:
				score += 150.0
				break

	# Closest to attacking if can't attack yet
	if not bench_data.get("can_attack", false):
		var lowest_unmet = 999
		for attack in bench_data.get("attack_data", []):
			if attack["unmet"] < lowest_unmet:
				lowest_unmet = attack["unmet"]
		if lowest_unmet < 999:
			score += max(0.0, 80.0 - (lowest_unmet * 25.0))

	# Survivability: can this pokemon take a hit from the opposing active
	if against_pokemon != null:
		var enemy_types = against_pokemon.metadata.get("types", ["Colorless"])
		var enemy_max_damage = 0
		for attack in against_pokemon.metadata.get("attacks", []):
			if get_unmet_energy_count(attack, against_pokemon) > 0:
				continue
			var damage_range = get_attack_damage_range(attack)
			var result = calculate_final_damage(damage_range["max"], enemy_types, bench_pokemon)
			enemy_max_damage = max(enemy_max_damage, result["damage"])
		if bench_pokemon.current_hp > enemy_max_damage:
			score += 100.0

	# Type advantage: our attacks hit the opponent's weakness
	if against_pokemon != null:
		for weakness in against_pokemon.metadata.get("weaknesses", []):
			if weakness["type"] in bench_types:
				score += 75.0
				break

	# Type disadvantage: opponent's attacks hit our weakness
	if against_pokemon != null:
		var enemy_types = against_pokemon.metadata.get("types", ["Colorless"])
		for weakness in bench_pokemon.metadata.get("weaknesses", []):
			if weakness["type"] in enemy_types:
				score -= 60.0
				break

	# Resistance bonus: we resist the opponent's type
	if against_pokemon != null:
		var enemy_types = against_pokemon.metadata.get("types", ["Colorless"])
		for resistance in bench_pokemon.metadata.get("resistances", []):
			if resistance["type"] in enemy_types:
				score += 50.0
				break

	# HP tiebreaker
	score += bench_pokemon.current_hp * 0.1

	return score

# Scores a single (pokemon, energy_card) pair using all Phase 2 rules
func score_energy_pair(pokemon: card_object, energy_card: card_object, cpu_eval: Dictionary, pokemon_data: Dictionary) -> float:
	var score = 0.0
	var is_active = (pokemon == opponent_active_pokemon)
	var energy_types = get_energy_provided_by_card(energy_card)
	
	# Flat active/bench modifier: active pokemon almost always takes priority
	if is_active:
		score += 40.0
	else:
		score -= 20.0
	
	# 2.1, 2.2, 2.3: Energy type matching (can disqualify a pair)
	score += score_energy_type_match(pokemon, energy_types, pokemon_data, is_active)

	# 2.4, 2.5: Active pokemon needs energy
	if is_active:
		score += score_active_needs_energy(pokemon, energy_types, pokemon_data)

	# 2.6: Active pokemon already fully powered
	if is_active:
		score += score_active_overpowered(pokemon_data, cpu_eval)

	# 2.7, 2.8, 2.9: Active pokemon under KO threat
	if is_active:
		score += score_active_ko_threat(pokemon, energy_types, pokemon_data, cpu_eval)

	# 2.10, 2.11: Evolution potential
	score += score_evolution_potential(pokemon, pokemon_data, cpu_eval, is_active)

	# 2.12, 2.13, 2.14: Bench pokemon scoring
	if not is_active:
		score += score_bench_candidate(pokemon, pokemon_data, cpu_eval)

	# 2.15: Attack self-discard consideration
	score += score_self_discard_penalty(pokemon)

	return score
	
# 2.1, 2.2, 2.3: Checks if energy type is useful for this pokemon
func score_energy_type_match(pokemon: card_object, energy_types: Array, pokemon_data: Dictionary, is_active: bool) -> float:
	var score = 0.0
	var attack_data = pokemon_data.get("attack_data", [])

	# Gather all specific (non-colorless) energy types needed across all attacks
	var needed_types = []
	for attack in attack_data:
		for req in attack.get("cost", []):
			if req != "Colorless" and req not in needed_types:
				needed_types.append(req)

	# Check if this energy provides a type that matches any attack cost
	var has_type_match = false
	for provided in energy_types:
		if provided in needed_types or provided == "Any":
			has_type_match = true
			break

	# Direct type match — this energy is exactly what the pokemon wants
	if has_type_match:
		score += 80.0 if is_active else 60.0
		return score

	# Check if this pokemon has any attacks with unmet colorless slots
	var has_unmet_colorless_slots = false
	for attack in attack_data:
		if attack["unmet"] <= 0:
			continue
		# Count how many colorless slots exist in this attack's cost
		var colorless_in_cost = attack["cost"].count("Colorless")
		if colorless_in_cost > 0:
			has_unmet_colorless_slots = true
			break

	# Any energy can fill colorless slots — moderate positive match
	if has_unmet_colorless_slots:
		score += 50.0 if is_active else 35.0
		return score

	# 2.2: Does attaching this energy fill a colorless slot and unlock an attack?
	var unlocks_via_colorless = false
	for attack in attack_data:
		if attack["unmet"] <= 0:
			continue
		var colorless_in_cost = attack["cost"].count("Colorless")
		if colorless_in_cost == 0:
			continue
		if attack["unmet"] == 1:
			var typed_unmet = attack["unmet"] - colorless_in_cost
			if typed_unmet <= 0:
				unlocks_via_colorless = true
				break

	if unlocks_via_colorless:
		score += 40.0 if is_active else 30.0
		return score

	# 2.3: Check if ANY pokemon in play needs this energy type specifically
	var any_pokemon_needs_type = false
	for field_pokemon in get_all_cpu_field_pokemon():
		if field_pokemon == pokemon:
			continue
		for attack in field_pokemon.metadata.get("attacks", []):
			for req in attack.get("cost", []):
				if req != "Colorless":
					for provided in energy_types:
						if provided == req or provided == "Any":
							any_pokemon_needs_type = true

	if any_pokemon_needs_type:
		score -= 200.0
		return score

	# Nobody needs this type — colorless fallback scoring
	var total_unmet_colorless = 0
	for attack in attack_data:
		if attack["unmet"] > 0:
			total_unmet_colorless += attack["cost"].count("Colorless")

	if total_unmet_colorless > 0:
		score += total_unmet_colorless * 5.0
		if is_active:
			score += 10.0
		return score

	score -= 200.0
	return score
	
# 2.4, 2.5: Active pokemon has unmet energy requirements
func score_active_needs_energy(pokemon: card_object, energy_types: Array, pokemon_data: Dictionary) -> float:
	var score = 0.0
	var attack_data = pokemon_data.get("attack_data", [])

	# 2.4: Active has at least one attack with unmet energy
	var has_unmet = false
	var lowest_unmet = 999
	for attack in attack_data:
		if attack["unmet"] > 0:
			has_unmet = true
			if attack["unmet"] < lowest_unmet:
				lowest_unmet = attack["unmet"]

	if has_unmet:
		score += 80.0
		# Progress bonus: the closer to unlocking, the more valuable each energy is
		if lowest_unmet <= 3:
			score += max(0.0, 80.0 - (lowest_unmet * 20.0))

	# 2.5: Would this specific energy unlock a currently unusable attack?
	for attack in attack_data:
		if attack["unmet"] != 1:
			continue
		var remaining_type = get_remaining_requirement(attack, pokemon)
		if remaining_type == null:
			continue
		if remaining_type == "Colorless":
			score += 100.0
			break
		for provided in energy_types:
			if provided == remaining_type or provided == "Any":
				score += 100.0
				break

	return score
	
# Returns the energy type of the single remaining unmet requirement, or null if not exactly 1 unmet
func get_remaining_requirement(attack_info: Dictionary, pokemon: card_object) -> String:
	if attack_info["unmet"] != 1:
		return ""
	var cost = attack_info["cost"].duplicate()

	# Build the available energy pool from attached energies
	var pool = []
	for attached in pokemon.attached_energies:
		pool.append_array(get_energy_provided_by_card(attached))

	# Remove typed requirements that are already satisfied
	for req in cost:
		if req == "Colorless":
			continue
		var idx = pool.find(req)
		if idx != -1:
			pool.remove_at(idx)
			cost[cost.find(req)] = "_SATISFIED_"
		else:
			var any_idx = pool.find("Any")
			if any_idx != -1:
				pool.remove_at(any_idx)
				cost[cost.find(req)] = "_SATISFIED_"
			else:
				return req

	# All typed requirements met — remaining must be colorless
	for req in cost:
		if req == "Colorless":
			if pool.size() > 0:
				pool.remove_at(0)
			else:
				return "Colorless"

	return ""

# 2.6: Penalises over-investment when active is already fully powered
func score_active_overpowered(pokemon_data: Dictionary, cpu_eval: Dictionary) -> float:
	var attack_data = pokemon_data.get("attack_data", [])

	# Check if all attacks already have energy requirements met
	var all_attacks_met = true
	for attack in attack_data:
		if attack["unmet"] > 0:
			all_attacks_met = false
			break

	if not all_attacks_met:
		return 0.0

	# Exception: if this pokemon can evolve and the evolved form needs more energy
	if pokemon_data.get("can_evolve_further", false) and pokemon_data.get("evolved_form_needs_energy", false):
		return 0.0

	return -100.0

# 2.7, 2.8, 2.9: Adjusts score when active is threatened with KO
func score_active_ko_threat(pokemon: card_object, energy_types: Array, pokemon_data: Dictionary, cpu_eval: Dictionary) -> float:
	var score = 0.0
	var can_attack = pokemon_data.get("can_attack", false)
	var guaranteed_ko = cpu_eval.get("cpu_active_guaranteed_ko", false)
	var potential_ko = cpu_eval.get("cpu_active_potential_ko", false)
	var bench_ko_threat = cpu_eval.get("player_bench_ko_threat", false)

	if not guaranteed_ko and not potential_ko and not bench_ko_threat:
		return 0.0

	# 2.8: Check if attaching this energy would enable a KO on the player's active
	var enables_ko = false
	if player_active_pokemon != null:
		var cpu_types = pokemon.metadata.get("types", ["Colorless"])
		var player_hp = player_active_pokemon.current_hp
		var attack_data = pokemon_data.get("attack_data", [])

		for attack in attack_data:
			if attack["unmet"] != 1:
				continue
			var remaining = get_remaining_requirement(attack, pokemon)
			if remaining == "":
				continue
			var type_matches = remaining == "Colorless"
			if not type_matches:
				for provided in energy_types:
					if provided == remaining or provided == "Any":
						type_matches = true
						break
			if not type_matches:
				continue
			var result = calculate_final_damage(attack["damage_min"], cpu_types, player_active_pokemon)
			if result["damage"] >= player_hp:
				enables_ko = true
				break

	if enables_ko:
		# Striking first is extremely valuable — override KO threat penalties
		if cpu_eval.get("cpu_prizes_remaining", 6) == 1:
			return 500.0
		return 250.0

	# 2.7a: Guaranteed KO and active can already attack — don't invest further
	if guaranteed_ko and can_attack:
		# 2.9: Partial override — extra damage before going down if bench backup exists
		if cpu_eval.get("has_viable_bench_attacker", false):
			var unlocks_stronger = false
			for attack in pokemon_data.get("attack_data", []):
				if attack["unmet"] == 1:
					unlocks_stronger = true
					break
			if unlocks_stronger:
				return -80.0
		return -150.0

	# 2.7c: Guaranteed KO and cannot attack yet
	if guaranteed_ko and not can_attack:
		var would_enable_attack = false
		for attack in pokemon_data.get("attack_data", []):
			if attack["unmet"] == 1:
				would_enable_attack = true
				break
		
		if not would_enable_attack:
			return -200.0
		else:
			return -100.0
			
	return 0.0

# 2.10, 2.11: Scores evolution potential for energy investment
func score_evolution_potential(pokemon: card_object, pokemon_data: Dictionary, cpu_eval: Dictionary, is_active: bool) -> float:
	var score = 0.0
	var has_evo_in_hand = pokemon_data.get("evolution_in_hand", null) != null
	var has_evo_in_deck = pokemon_data.get("evolution_in_deck_or_prizes", false)
	var needs_energy = pokemon_data.get("evolved_form_needs_energy", false)

	# 2.10a: Evolution in hand and evolved form needs more energy
	if has_evo_in_hand and needs_energy:
		score += 100.0

	# 2.10b: Evolution in deck/prizes only — less certain
	elif has_evo_in_deck and needs_energy:
		score += 50.0

	# 2.11: Active already doing its job — redirect to evolving bench pokemon
	if is_active and cpu_eval.get("cpu_can_ko_player_active", false):
		var dominated_by_bench_evo = false
		for bench_pokemon in opponent_bench:
			var bench_key = bench_pokemon.get_instance_id()
			var bench_data = cpu_eval["pokemon_data"].get(bench_key, {})
			var bench_has_evo = bench_data.get("evolution_in_hand", null) != null or bench_data.get("evolution_in_deck_or_prizes", false)
			var bench_needs_energy = bench_data.get("evolved_form_needs_energy", false)
			if bench_has_evo and bench_needs_energy:
				dominated_by_bench_evo = true
				break

		if dominated_by_bench_evo:
			score -= 70.0

	return score

# 2.12, 2.13, 2.14: Scores bench pokemon as energy targets
func score_bench_candidate(pokemon: card_object, pokemon_data: Dictionary, cpu_eval: Dictionary) -> float:
	var score = 0.0
	var attack_data = pokemon_data.get("attack_data", [])

	# 2.12: Base score for bench pokemon with unmet energy
	var has_unmet = false
	for attack in attack_data:
		if attack["unmet"] > 0:
			has_unmet = true
			break

	if has_unmet:
		score += 50.0

	# 2.13: Boost bench when active is doomed and can already attack
	var active_doomed = cpu_eval.get("cpu_active_guaranteed_ko", false)
	var active_key = opponent_active_pokemon.get_instance_id() if opponent_active_pokemon != null else -1
	var active_data = cpu_eval["pokemon_data"].get(active_key, {})
	var active_can_attack = active_data.get("can_attack", false)

	if active_doomed and active_can_attack:
		score += 100.0

		# Prefer bench pokemon that can survive the player's strongest usable attack
		if player_active_pokemon != null:
			var player_types = player_active_pokemon.metadata.get("types", ["Colorless"])
			var player_max_damage = 0
			for attack in player_active_pokemon.metadata.get("attacks", []):
				if get_unmet_energy_count(attack, player_active_pokemon) > 0:
					continue
				var damage_range = get_attack_damage_range(attack)
				var result = calculate_final_damage(damage_range["max"], player_types, pokemon)
				player_max_damage = max(player_max_damage, result["damage"])

			if pokemon.current_hp > player_max_damage:
				score += 40.0

	# 2.14: Proximity bonus — fewer unmet energy means closer to attacking
	var lowest_unmet = 999
	for attack in attack_data:
		if attack["unmet"] > 0 and attack["unmet"] < lowest_unmet:
			lowest_unmet = attack["unmet"]

	if lowest_unmet < 999:
		score += max(0.0, 60.0 - (lowest_unmet * 20.0))

	return score

# 2.15: Penalises pokemon whose preferred attack discards attached energy
func score_self_discard_penalty(pokemon: card_object) -> float:
	var pokemon_name = pokemon.metadata.get("name", "")
	var max_attack = get_maximum_damage_attack(pokemon)

	if max_attack.is_empty():
		return 0.0

	var penalty = get_attack_text_penalty(max_attack.get("text", ""), pokemon_name)

	# Scale down — this is a tiebreaker, not a dealbreaker
	return penalty * 0.3

# Resolves tiebreaks when multiple pairs share the highest score (3.3)
func resolve_energy_tiebreak(scored_pairs: Array, cpu_eval: Dictionary) -> Dictionary:
	var best_score = scored_pairs[0]["score"]

	# Collect all pairs that share the top score
	var tied = []
	for pair in scored_pairs:
		if pair["score"] == best_score:
			tied.append(pair)
		else:
			break

	if tied.size() == 1:
		return tied[0]

	# Tiebreak 1: Prefer active pokemon over bench
	var active_only = tied.filter(func(p): return p["pokemon"] == opponent_active_pokemon)
	if active_only.size() == 1:
		return active_only[0]
	if active_only.size() > 1:
		tied = active_only

	# Tiebreak 2: Prefer pokemon closer to having a usable attack (lowest unmet)
	var best_unmet = 999
	for pair in tied:
		var key = pair["pokemon"].get_instance_id()
		var pokemon_data = cpu_eval["pokemon_data"].get(key, {})
		for attack in pokemon_data.get("attack_data", []):
			if attack["unmet"] > 0 and attack["unmet"] < best_unmet:
				best_unmet = attack["unmet"]

	var closest = tied.filter(func(p):
		var key = p["pokemon"].get_instance_id()
		var pd = cpu_eval["pokemon_data"].get(key, {})
		var lowest = 999
		for attack in pd.get("attack_data", []):
			if attack["unmet"] > 0 and attack["unmet"] < lowest:
				lowest = attack["unmet"]
		return lowest == best_unmet
	)
	if closest.size() == 1:
		return closest[0]
	if closest.size() > 1:
		tied = closest

	# Tiebreak 3: Prefer pokemon with higher remaining HP
	var best_hp = -1
	for pair in tied:
		if pair["pokemon"].current_hp > best_hp:
			best_hp = pair["pokemon"].current_hp

	for pair in tied:
		if pair["pokemon"].current_hp == best_hp:
			return pair

	return tied[0]


################################################### END OPPONENT PRIORITISE FUNCTIONALITY FUNCTIONS ##################################################
######################################################################################################################################################
 
# #######  ######   ##   ##        ######   #######    ####### #######
# ##       ##   ##  ##   ##        ##      ##     ##  ##       ##
# ##       ######   ##   ##  ##### ##      ##     ##  ##       #######
# ##       ##       ##   ##        ##      ##     ##  ##       ##
# #######  ##       #######        #######  #######   ##       #######

######################################################################################################################################################
###################################################### OPPONENT GENERAL FUNCTIONALITY FUNCTIONS ######################################################

# Function to set up opponent's active and bench pokemon using the priority condition criteria scoring selection
func opponent_setup_pokemon_from_hand() -> void:
	var selected_pokemon = select_opponent_pokemon_for_setup(opponent_hand)
	var active_pokemon = selected_pokemon.get("active")
	var bench_pokemon_list = selected_pokemon.get("bench", [])
	
	# Remove active pokemon from hand and set it as active
	opponent_hand.erase(active_pokemon)
	opponent_active_pokemon = active_pokemon
	opponent_active_pokemon.current_location = "active"
	opponent_active_pokemon.placed_on_field_this_turn = true
	
	# Remove bench pokemon from hand and add to bench
	for bench_pokemon in bench_pokemon_list:
		opponent_hand.erase(bench_pokemon)
		bench_pokemon.current_location = "bench"
		bench_pokemon.placed_on_field_this_turn = true
		opponent_bench.append(bench_pokemon)
	
	# Update displays
	display_pokemon(true)  # true = opponent
	display_hand_cards_array(opponent_hand, $CARD_COLLECTIONS/OPPONENT/opponent_hand_hbox_container, card_scales[11.55], hide_hidden_cards, 500,6)

# Handles start-of-turn duties then hands off to the CPU decision orchestrator
func opponent_start_turn_checks() -> void:
	turn_number += 1
	print("OPPONENT'S TURN START. TURN NUMBER IS ", turn_number)
	await get_tree().create_timer(0.5).timeout
	opponents_turn_active = true
	reset_field_pokemon_turn_flags(true)

	await show_message("Your opponent draws a card")
	var drawn_card = await draw_card_from_deck(true)

	if drawn_card == null:
		return

	display_hand_cards_array(opponent_hand, $CARD_COLLECTIONS/OPPONENT/opponent_hand_hbox_container, card_scales[11.55], hide_hidden_cards, 500, 6)
	update_deck_icon(true)

	# Future: resolve any start-of-turn triggered effects here

	await cpu_turn_orchestrator()

# Orchestrates all CPU decision phases in the correct order
func cpu_turn_orchestrator() -> void:
	# Phase 1: Trainer card plays (not yet implemented - reserve this slot)

	# Phase 2: Evolution plays
	await cpu_phase_evolution()

	# Phase 3: Bench pokemon plays (uses existing priority scoring)
	await cpu_phase_bench_play()

	# Phase 4: Build evaluation AFTER all board-altering plays have resolved
	var cpu_eval = build_cpu_evaluation()

	# Phase 5: First retreat evaluation (before energy attachment)
	var retreat_deferred = await cpu_phase_retreat_first_pass(cpu_eval)

	# Phase 6: Energy attachment
	await cpu_phase_energy_attachment(cpu_eval)

	# Phase 7: Second retreat pass (only if Phase 5 deferred pending energy)
	if retreat_deferred:
		cpu_eval = build_cpu_evaluation()
		await cpu_phase_retreat_second_pass(cpu_eval)

	# Phase 8: Attack decision (must always be last)
	await cpu_phase_attack(cpu_eval)

	await get_tree().create_timer(0.5).timeout
	await show_message("Your opponent ends their turn")
	await inbetween_turn_checks(false)

# CPU plays any valid evolutions from hand onto field pokemon using pair scoring
func cpu_phase_evolution() -> void:
	if turn_number <= 2:
		return

	while true:
		# Build list of all valid (evo_card, target) pairs and score them
		var scored_pairs = []
		for card in opponent_hand:
			var valid_targets = get_valid_evolution_targets(card, true)
			for target in valid_targets:
				var result = evaluate_evolution_pair(card, target)
				scored_pairs.append(result)

		if scored_pairs.is_empty():
			break

		# Sort by score descending and pick the best pair
		scored_pairs.sort_custom(func(a, b): return a["score"] > b["score"])
		var best = scored_pairs[0]

		print("CPU evolving " + best["target"].metadata["name"] + " into " + best["evo_card"].metadata["name"] + " (Score: " + str(int(best["score"])) + ")")
		for reason in best["reasons"]:
			print("  - " + reason)

		# Set the globals that perform_evolution reads from
		evolution_card_awaiting_target = best["evo_card"]
		selected_card_for_action = best["target"]
		perform_evolution(true)

		await show_message("Opponent evolved " + best["target"].metadata["name"].to_upper() + " into " + best["evo_card"].metadata["name"].to_upper() + "!")
	
		var evo_target_node = $ACTIVE_POKEMON/OPPONENT/opponent_active_pokemon_container if best["evo_card"].current_location == "active" else $CARD_COLLECTIONS/OPPONENT/opponent_bench_container
		var evo_scale = card_scales[8] if best["evo_card"].current_location == "active" else card_scales[11]
		var evo_texture = get_card_texture(best["evo_card"])
		await animate_card_a_to_b($CARD_COLLECTIONS/OPPONENT/opponent_hand_hbox_container, evo_target_node, 0.3, evo_texture, evo_scale)

		display_pokemon(true)
		display_active_pokemon_energies(true)
		display_hand_cards_array(opponent_hand, $CARD_COLLECTIONS/OPPONENT/opponent_hand_hbox_container, card_scales[11.55], hide_hidden_cards, 500, 6)

		await get_tree().process_frame
	
		await play_evolution_effect(best["evo_card"])

		# Clean up globals
		evolution_card_awaiting_target = null
		selected_card_for_action = null

# R.1: Determines if there is a reason for the active to consider retreating
func evaluate_retreat_reasons(cpu_eval: Dictionary) -> bool:
	var active_key = opponent_active_pokemon.get_instance_id()
	var active_data = cpu_eval["pokemon_data"].get(active_key, {})
	var can_attack = active_data.get("can_attack", false)

	# Reason 1: Mutual guaranteed KO situation
	# Only ignore the guaranteed KO threat if WE can also guarantee a KO back
	if cpu_eval.get("cpu_active_guaranteed_ko", false) and can_attack:
		# Check if our attack is guaranteed to KO the player's active
		var player_hp = player_active_pokemon.current_hp
		var guaranteed_ko_player = false
		
		for attack in active_data.get("attack_data", []):
			if attack["unmet"] == 0:  # Can use this attack
				if attack["damage_min"] >= player_hp:  # Guaranteed to KO
					guaranteed_ko_player = true
					break
					
		if guaranteed_ko_player:
			print("CPU NOT retreating: mutual KO - will attack and trade")
			return false  # Don't retreat, attack instead
		else:
			print("CPU considering retreat: guaranteed KO threat and cannot KO back")
			return true  # Do retreat, we'd lose the trade

	# Reason 2: Active is at risk of KO (potential or bench threat)
	if cpu_eval.get("cpu_active_potential_ko", false) or cpu_eval.get("player_bench_ko_threat", false):
		print("CPU considering retreat: potential KO threat")
		return true

	# Reason 3: Active cannot attack and has no path to attacking within 1-2 turns
	if not can_attack:
		var nearest_attack = 999
		for attack in active_data.get("attack_data", []):
			if attack["unmet"] < nearest_attack:
				nearest_attack = attack["unmet"]

		# Count matching energy cards in hand
		var matching_energy_in_hand = 0
		for card in opponent_hand:
			if card.metadata.get("supertype", "").to_lower() != "energy":
				continue
			var energy_types = get_energy_provided_by_card(card)
			for attack in active_data.get("attack_data", []):
				for req in attack.get("cost", []):
					if req == "Colorless" or req in energy_types:
						matching_energy_in_hand += 1
						break

		if nearest_attack > matching_energy_in_hand + 1:
			print("CPU considering retreat: active has no viable attack path")
			return true

	return false

# Scores all (pokemon, energy_card) pairs and attaches the best one (Phase 0, 2, 3)
func cpu_phase_energy_attachment(cpu_eval: Dictionary) -> void:
	# Phase 0.1: Skip if no energy cards in hand
	var energy_cards_in_hand = []
	for card in opponent_hand:
		if card.metadata.get("supertype", "").to_lower() == "energy":
			energy_cards_in_hand.append(card)

	if energy_cards_in_hand.is_empty() or opponent_energy_played_this_turn:
		return

	# Phase 0.2: Build candidate targets (active + bench)
	var candidates = get_all_cpu_field_pokemon()

	# Phase 2: Score every (pokemon, energy_card) pair
	var scored_pairs = []
	for pokemon in candidates:
		var key = pokemon.get_instance_id()
		var pokemon_data = cpu_eval["pokemon_data"].get(key, {})
		for energy_card in energy_cards_in_hand:
			var score = score_energy_pair(pokemon, energy_card, cpu_eval, pokemon_data)
			scored_pairs.append({
				"pokemon": pokemon,
				"energy_card": energy_card,
				"score": score
			})

	if scored_pairs.is_empty():
		return

	# Phase 3.1: Sort by score descending
	scored_pairs.sort_custom(func(a, b): return a["score"] > b["score"])
	var best = scored_pairs[0]

	# Phase 3.3: Tiebreaking
	best = resolve_energy_tiebreak(scored_pairs, cpu_eval)

	# Phase 3.4: Always attach even if score is negative
	var target = best["pokemon"]
	var energy = best["energy_card"]

	print("CPU attaching " + energy.metadata["name"] + " to " + target.metadata["name"] + " (Score: " + str(int(best["score"])) + ")")

	# Perform the attachment
	opponent_hand.erase(energy)
	target.attached_energies.append(energy)
	opponent_energy_played_this_turn = true

	await show_message("Opponent attached " + energy.metadata["name"].to_upper() + " to " + target.metadata["name"].to_upper() + "!")

	var energy_target_node = $ACTIVE_POKEMON/OPPONENT/opponent_active_pokemon_energies if target == opponent_active_pokemon else $CARD_COLLECTIONS/OPPONENT/opponent_bench_container
	var energy_set = energy.uid.split("-")[0]
	var energy_texture = load("res://cardimages/" + energy_set + "/Small/" + energy.uid + ".png")
	await animate_card_a_to_b($CARD_COLLECTIONS/OPPONENT/opponent_hand_hbox_container, energy_target_node, 0.2, energy_texture, card_scales[12])

	display_hand_cards_array(opponent_hand, $CARD_COLLECTIONS/OPPONENT/opponent_hand_hbox_container, card_scales[11.55], hide_hidden_cards, 500, 6)
	display_pokemon(true)
	display_active_pokemon_energies(true)
	await get_tree().process_frame
	await play_energy_attached_effect(target, energy)
	
# Chooses and executes an attack to end the CPU turn (Phase 8)
func cpu_phase_attack(cpu_eval: Dictionary) -> void:
	if opponent_active_pokemon == null or player_active_pokemon == null:
		return
	
	if turn_number <= 1:
		return
	
	if opponent_active_pokemon.special_condition == "Paralyzed":
		print("CPU cannot attack: active is Paralyzed")
		return
	if opponent_active_pokemon.special_condition == "Asleep":
		print("CPU cannot attack: active is Asleep")
		return
	
	# Check attack readiness from live board state, not stale cpu_eval
	var has_usable_attack = false
	for attack in opponent_active_pokemon.metadata.get("attacks", []):
		if get_unmet_energy_count(attack, opponent_active_pokemon) == 0:
			has_usable_attack = true
			break

	if not has_usable_attack:
		print("CPU cannot attack: no usable attacks")
		return

	var cpu_types = opponent_active_pokemon.metadata.get("types", ["Colorless"])
	var player_hp = player_active_pokemon.current_hp
	var attacks = opponent_active_pokemon.metadata.get("attacks", [])

	# Score each usable attack
	var best_attack_index = -1
	var best_attack_score = -999.0

	for i in range(attacks.size()):
		var attack = attacks[i]
		if get_unmet_energy_count(attack, opponent_active_pokemon) > 0:
			continue

		var score = 0.0
		var damage_range = get_attack_damage_range(attack)
		var min_result = calculate_final_damage(damage_range["min"], cpu_types, player_active_pokemon)
		var max_result = calculate_final_damage(damage_range["max"], cpu_types, player_active_pokemon)

		# Strongly prefer attacks that guarantee a KO
		if min_result["damage"] >= player_hp:
			score += 500.0
			# Among KO attacks, prefer least overkill (conserve energy discard costs)
			score -= (min_result["damage"] - player_hp) * 0.5

		# Attacks that might KO with good luck
		elif max_result["damage"] >= player_hp:
			score += 200.0

		# Base damage contribution
		score += min_result["damage"] * 2.0

		# Penalise attacks with self-discard costs
		var pokemon_name = opponent_active_pokemon.metadata.get("name", "")
		var discard_penalty = get_attack_text_penalty(attack.get("text", ""), pokemon_name)
		score += discard_penalty

		if score > best_attack_score:
			best_attack_score = score
			best_attack_index = i

	if best_attack_index == -1:
		print("CPU found no suitable attack")
		return

	# Execute the chosen attack
	var chosen_attack = attacks[best_attack_index]
	var damage_range = get_attack_damage_range(chosen_attack)
	var result = calculate_final_damage(damage_range["min"], cpu_types, player_active_pokemon)
	var final_damage = result["damage"]

	await show_message("Opponent's " + opponent_active_pokemon.metadata["name"].to_upper() + " used " + chosen_attack["name"].to_upper() + "!")

	if opponent_active_pokemon.special_condition == "Confused":
		await show_message(opponent_active_pokemon.metadata["name"].to_upper() + " IS CONFUSED! FLIPPING COIN...")
		var coin = await flip_coin()
		if not coin:
			var self_damage = 20
			if confusion_rules == "modern_era_confusion_rules":
				self_damage = 30
			if confusion_rules == "base_set_confusion_rules":
				var self_types = opponent_active_pokemon.metadata.get("types", ["Colorless"])
				var confusion_result = calculate_final_damage(self_damage, self_types, opponent_active_pokemon)
				self_damage = confusion_result["damage"]
			opponent_active_pokemon.current_hp = max(0, opponent_active_pokemon.current_hp - self_damage)
			await show_message("THE ATTACK FAILED! " + opponent_active_pokemon.metadata["name"].to_upper() + " HURT ITSELF FOR " + str(self_damage) + " DAMAGE!")
			show_floating_label("-" + str(self_damage) + "HP", Vector2(1030, 300), true)
			display_hp_circles_above_align(opponent_active_pokemon, true)
			print("CONFUSED: CPU ", opponent_active_pokemon.metadata["name"], " hurt itself for ", self_damage)
			await check_all_knockouts()
			display_active_pokemon_energies(true)
			return

	for modifier in result["modifiers"]:
		show_floating_label(modifier, Vector2(530, 300), true)
		await get_tree().create_timer(0.5).timeout

	show_floating_label("-" + str(final_damage) + "HP", Vector2(530, 300), true)

	player_active_pokemon.current_hp = max(0, player_active_pokemon.current_hp - final_damage)

	print("CPU used " + chosen_attack["name"] + " for " + str(final_damage) + " damage! Player HP: " + str(player_active_pokemon.current_hp))

	display_hp_circles_above_align(player_active_pokemon, false)
	
	var attack_text = chosen_attack.get("text", "")
	var effects = parse_card_text_effects(attack_text, opponent_active_pokemon.metadata.get("name", ""))
	if effects.size() > 0:
		await apply_card_text_effects(effects, opponent_active_pokemon, player_active_pokemon, true)

	await check_all_knockouts()
	display_active_pokemon_energies(true)

# CPU evaluates and plays basic pokemon from hand onto bench using threshold scoring
func cpu_phase_bench_play() -> void:
	var bench_thresholds = {0: -999, 1: 100, 2: 200, 3: 350, 4: 500}

	while opponent_bench.size() < 5:
		var current_bench_count = opponent_bench.size()
		var score_threshold = bench_thresholds.get(current_bench_count, 9999)

		# Score all basic pokemon in hand using existing priority criteria
		var best_card: card_object = null
		var best_score: float = -999.0
		for card in opponent_hand:
			if not is_basic_pokemon(card):
				continue
			var result = evaluate_opponents_start_setup_pokemon_choices(card, opponent_hand)
			var score = result.get("total_score", 0)
			if score > best_score:
				best_score = score
				best_card = card

		# Stop if no basic pokemon in hand or best doesn't meet threshold
		if best_card == null or best_score <= score_threshold:
			break

		# Play the pokemon onto the bench
		opponent_hand.erase(best_card)
		best_card.current_location = "bench"
		best_card.placed_on_field_this_turn = true
		opponent_bench.append(best_card)

		print("CPU played " + best_card.metadata["name"] + " to bench (Score: " + str(int(best_score)) + ", Threshold: " + str(score_threshold) + ")")

		await show_message("Opponent placed " + best_card.metadata["name"].to_upper() + " on the bench!")
		var card_texture = get_card_texture(best_card)
		await animate_card_a_to_b($CARD_COLLECTIONS/OPPONENT/opponent_hand_hbox_container, $CARD_COLLECTIONS/OPPONENT/opponent_bench_container, 0.3, card_texture, card_scales[11])
		display_pokemon(true)
		display_hand_cards_array(opponent_hand, $CARD_COLLECTIONS/OPPONENT/opponent_hand_hbox_container, card_scales[11.55], hide_hidden_cards, 500, 6)

# R.5: Selects the best bench replacement and performs the retreat
func execute_cpu_retreat(cpu_eval: Dictionary) -> void:
	var best_replacement = pick_best_bench_replacement(opponent_bench, player_active_pokemon, cpu_eval)

	if best_replacement == null:
		print("CPU retreat failed: no valid bench replacement")
		return
		
	var pre_check = await check_confused_retreat(opponent_active_pokemon, true, "pre_energy")
	if not pre_check:
		display_hp_circles_above_align(opponent_active_pokemon, true)
		await check_all_knockouts()
		display_pokemon(true)
		return
		
	# Discard energy for retreat cost
	var retreat_cost = get_retreat_cost(opponent_active_pokemon)
	var discarded_energies = []
	for i in range(retreat_cost):
		if opponent_active_pokemon.attached_energies.size() > 0:
			var energy = opponent_active_pokemon.attached_energies.pop_back()
			send_card_to_discard(energy, true)
			discarded_energies.append(energy)

	var post_check = await check_confused_retreat(opponent_active_pokemon, true, "post_energy")
	if not post_check:
		display_pokemon(true)
		display_active_pokemon_energies(true)
		return

	# Swap positions
	var old_active = opponent_active_pokemon
	opponent_bench.erase(best_replacement)
	opponent_bench.append(old_active)
	old_active.current_location = "bench"
	best_replacement.current_location = "active"
	opponent_active_pokemon = best_replacement
	opponent_retreated_this_turn = true

	print("CPU retreated " + old_active.metadata["name"] + " for " + best_replacement.metadata["name"])
	await animate_retreat(old_active, best_replacement, discarded_energies, true)
	clear_all_statuses(old_active, true)
	display_pokemon(true)
	display_active_pokemon_energies(true)

# CPU automatically picks a random prize card and moves it to hand
func opponent_take_prize_card() -> void:
	if opponent_prize_cards.size() == 0:
		return
	
	var random_index = randi() % opponent_prize_cards.size()
	var chosen_card = opponent_prize_cards[random_index]
	
	await show_message("OPPONENT TAKES A PRIZE CARD!")
	await take_prize_card(chosen_card, true)

################################################## END OPPONENT PRIORITISE FUNCTIONALITY FUNCTIONS ###################################################
######################################################################################################################################################

#           ########  ####    ##  #######  ##   ##  ########
#              ##     ## ##   ##  ##    ## ##   ##     ##
#              ##     ##  ##  ##  #######  ##   ##     ##
#              ##     ##   ## ##  ##       ##   ##     ##
#           ########  ##    ####  ##       #######     ##
######################################################################################################################################################
########################################################### USER INPUT ON CLICK FUNCTIONS ############################################################

# Card action button is the physical button that appears when in card selection mode, allows attaching energies, playing pokemon and trainer cards
func action_button_pressed_perform_action() -> void:
	
	$BUTTONS/SELECTION_BUTTONS/card_action_button.text = "Select a Card"
	$BUTTONS/SELECTION_BUTTONS/card_action_button.disabled = true
	$BUTTONS/SELECTION_BUTTONS/card_action_button.theme = load("res://uiresources/kenneyUI.tres")
	
	if retreat_mode_active:
		retreat_mode_active = false
		start_retreat_bench_selection()
		return
	
	if retreat_bench_selection_active:
		var new_active = selected_card_for_action

		var pre_check = await check_confused_retreat(player_active_pokemon, false, "pre_energy")
		if not pre_check:
			retreat_bench_selection_active = false
			selected_card_for_action = null
			hide_selection_mode_display_main()
			display_hp_circles_above_align(player_active_pokemon, false)
			await check_all_knockouts()
			display_pokemon(false)
			return

		var post_check = await check_confused_retreat(player_active_pokemon, false, "post_energy")
		if not post_check:
			retreat_bench_selection_active = false
			selected_card_for_action = null
			hide_selection_mode_display_main()
			display_pokemon(false)
			display_active_pokemon_energies()
			return

		player_bench.erase(new_active)
		player_bench.append(player_active_pokemon)

		player_active_pokemon.current_location = "bench"
		new_active.current_location = "active"

		player_retreated_this_turn = true
		retreat_bench_selection_active = false
		selected_card_for_action = null

		hide_selection_mode_display_main()
		await animate_retreat(player_active_pokemon, new_active, retreat_energies_selected, false)

		clear_all_statuses(player_active_pokemon, false)
		player_active_pokemon = new_active
		retreat_energies_selected.clear()

		display_pokemon(false)
		display_active_pokemon_energies()
		return
	
	if knockout_bench_selection_active:
		var new_active = selected_card_for_action
		player_bench.erase(new_active)
		new_active.current_location = "active"
		player_active_pokemon = new_active

		knockout_bench_selection_active = false
		selected_card_for_action = null

		hide_selection_mode_display_main()

		var new_texture = get_card_texture(new_active)
		await animate_card_a_to_b($CARD_COLLECTIONS/PLAYER/player_bench_container, $ACTIVE_POKEMON/PLAYER/player_active_pokemon_container, 0.3, new_texture, card_scales[9])

		display_pokemon(false)
		display_active_pokemon_energies()
		display_hp_circles_above_align(player_active_pokemon, false)

		knockout_replacement_chosen.emit()
		return
	
	# Check if we're in attach mode - handle differently
	if card_attach_mode_active:
		# In attach mode, we're attaching the energy to the selected Pokemon
		perform_energy_attachment()
		return
	
	if evolution_mode_active:
		var evo_card = evolution_card_awaiting_target
		var target_card = selected_card_for_action
		
		perform_evolution(false)
		
		evolution_card_awaiting_target = null
		selected_card_for_action = null
		evolution_mode_active = false
		
		hide_selection_mode_display_main()
		display_hand_cards_array(player_hand, $CARD_COLLECTIONS/PLAYER/player_hand_hbox_container, card_scales[11])
		
		var target_node = null
		var card_scale_to_animate = card_scales[12]
		
		if evo_card.current_location == "active": 
			target_node = $ACTIVE_POKEMON/PLAYER/player_active_pokemon_container
			card_scale_to_animate = card_scales[8]
		else:
			target_node = $CARD_COLLECTIONS/PLAYER/player_bench_container
			card_scale_to_animate = card_scales[11]
			
		var evo_texture = get_card_texture(evo_card)
		await animate_card_a_to_b($CARD_COLLECTIONS/PLAYER/player_hand_hbox_container, target_node, 0.3, evo_texture, card_scale_to_animate)
		
		display_pokemon(false)
		await get_tree().process_frame
		await play_evolution_effect(evo_card)
		display_active_pokemon_energies()
		
		return
	
	if prize_card_selection_active:
		var prize_card = selected_card_for_action
		prize_card_selection_active = false
		selected_card_for_action = null
		
		$BUTTONS/SELECTION_BUTTONS/card_action_button.position.x -= 210
		hide_selection_mode_display_main()
		await take_prize_card(prize_card, false)
		prize_card_taken.emit()
		return
		
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
				# First turn - SET AS ACTIVE POKEMON pokemon
				set_player_active_pokemon()
				display_pokemon(false)  # false = player
				display_hand_cards_array(player_hand, $CARD_COLLECTIONS/PLAYER/player_hand_hbox_container, card_scales[11])
				match_just_started_basic_pokemon_required = false
				$BUTTONS/SELECTION_BUTTONS/card_action_button.position.x -= 210 
				
				# After active pokemon is set, start the bench setup phase
				start_bench_setup_phase()
			else:
				var bench_card = selected_card_for_action
				add_pokemon_to_bench(bench_card)
				display_hand_cards_array(player_hand, $CARD_COLLECTIONS/PLAYER/player_hand_hbox_container, card_scales[11])
				
				if bench_setup_phase_active:
					selected_card_for_action = null
					display_pokemon(false)
					show_enlarged_array_selection_mode(player_hand)
				else:
					hide_selection_mode_display_main()
					await get_tree().process_frame
					await get_tree().process_frame
					var bench_texture = get_card_texture(bench_card)
					await animate_card_a_to_b($CARD_COLLECTIONS/PLAYER/player_hand_hbox_container, $CARD_COLLECTIONS/PLAYER/player_bench_container, 0.3, bench_texture, card_scales[11])
					display_pokemon(false)
		
		"PLAY_TRAINER":
			print("Trainer card play not yet implemented")
			# We'll add this later
		
		"ATTACH_ENERGY":
			start_energy_attachment()
		
		"EVOLVE":
			start_evolution()
		
		_:
			print("Unknown action: ", action_type)

# When the cancel button is clicked, hide everthing in card selection mode and show main screen again
func cancel_button_pressed_hide_selection_mode() -> void:
	
		# If we're in attach mode, cancel the energy attachment
	if card_attach_mode_active:
		print("Energy attachment cancelled")
		
		# Clear the energy card awaiting target (it stays in the hand)
		energy_card_awaiting_target = null
		
		# Exit attach mode
		card_attach_mode_active = false
		
		# Return to main UI screen
		hide_selection_mode_display_main()
		return
	
	elif evolution_mode_active:
		print("Evolution cancelled")
		evolution_card_awaiting_target = null
		evolution_mode_active = false
		hide_selection_mode_display_main()
		return
	
	elif retreat_mode_active:
		print("Retreat energy selection cancelled")
		retreat_mode_active = false
		retreat_energies_selected.clear()
		retreat_cost_remaining = 0
		hide_selection_mode_display_main()
		return
	
	elif retreat_bench_selection_active:
		print("Retreat bench selection cancelled")
		retreat_bench_selection_active = false
		retreat_energies_selected.clear()
		retreat_cost_remaining = 0
		hide_selection_mode_display_main()
		return
	
	# If we were in bench setup phase, end it and draw prize cards
	elif bench_setup_phase_active:
		$opponent_turn_input_blocker.visible = true
		bench_setup_phase_active = false
		$cancel_selection_mode_view_button.text = "Cancel"
		$cancel_selection_mode_view_button.theme = load("res://uiresources/kenneyUI-red.tres")
		draw_prize_cards(true)
		hide_selection_mode_display_main()
	
		await show_message("FLIPPING COIN TO DECIDE WHICH PLAYER GOES FIRST")
	
		var who_starts = await flip_coin()
	
		if who_starts:
			await show_message("You are going first!")
			player_start_turn_checks()
		else:
			await show_message("Opponent is going first!")
			opponent_start_turn_checks()
	else:
		hide_selection_mode_display_main()

# Opens any card array in enlarged selection mode when its container is clicked
func array_container_clicked(event: InputEvent, card_array: Array) -> void:
	if event is InputEventMouseButton and event.pressed:
		if $messagebox_container.visible or $coin_flip_container.visible: return
		if card_array.size() > 0:
			show_enlarged_array_selection_mode(card_array)

# Called when a card in selection mode is clicked
func this_card_clicked(clicked_card: card_object) -> void:
	# Don't allow card selection if action button is hidden (view-only mode) or messagebox is being displayed
	if $messagebox_container.visible or $coin_flip_container.visible: return
	if not $BUTTONS/SELECTION_BUTTONS/card_action_button.visible: return
	
	if card_selection_mode_enabled == true:
		
		# ATTACHMENT MODE ATTACHMENT MODE ATTACHMENT MODE ATTACHMENT MODE ATTACHMENT MODE ATTACHMENT MODE ATTACHMENT MODE
		if card_attach_mode_active:
			# In attach mode, we're selecting a target Pokemon, not performing a card action
			if selected_card_for_action != null:
				var prev_card_display = find_card_ui_for_object(selected_card_for_action)
				if prev_card_display:
					prev_card_display.set_selected(false)
			
			# Store the selected target Pokemon
			selected_card_for_action = clicked_card
			
			print("Selected target Pokemon for energy attachment: ", selected_card_for_action.metadata["name"])
			
			# Apply visual effect to newly selected Pokemon
			var card_display = find_card_ui_for_object(clicked_card)
			if card_display:
				card_display.set_selected(true)
			
			# Update button to show it's ready to attach
			$BUTTONS/SELECTION_BUTTONS/card_action_button.text = "ATTACH ENERGY"
			$BUTTONS/SELECTION_BUTTONS/card_action_button.disabled = false
			$BUTTONS/SELECTION_BUTTONS/card_action_button.theme = load("res://uiresources/kenneyUI-green.tres")
			return
		
		# EVOLUTION MODE EVOLUTION MODE EVOLUTION MODE EVOLUTION MODE EVOLUTION MODE EVOLUTION MODE EVOLUTION MODE	
		elif evolution_mode_active:
			if selected_card_for_action != null:
				var prev_card_display = find_card_ui_for_object(selected_card_for_action)
				if prev_card_display:
					prev_card_display.set_selected(false)
			
			selected_card_for_action = clicked_card
			
			print("Selected evolution target: ", selected_card_for_action.metadata["name"])
			
			var card_display = find_card_ui_for_object(clicked_card)
			if card_display:
				card_display.set_selected(true)
			
			$BUTTONS/SELECTION_BUTTONS/card_action_button.text = "EVOLVE"
			$BUTTONS/SELECTION_BUTTONS/card_action_button.disabled = false
			$BUTTONS/SELECTION_BUTTONS/card_action_button.theme = load("res://uiresources/kenneyUI-green.tres")
			return
		
		# RETREAT MODE RETREAT MODE RETREAT MODE RETREAT MODE RETREAT MODE RETREAT MODE RETREAT MODE RETREAT MODE
		elif retreat_mode_active:
			if clicked_card == player_active_pokemon:
				return
			
			if clicked_card in retreat_energies_selected:
				retreat_energies_selected.erase(clicked_card)
				var card_display = find_card_ui_for_object(clicked_card)
				if card_display:
					card_display.set_selected(false)
			else:
				if retreat_energies_selected.size() >= get_retreat_cost(player_active_pokemon):
					return
				retreat_energies_selected.append(clicked_card)
				var card_display = find_card_ui_for_object(clicked_card)
				if card_display:
					card_display.set_selected(true)
			
			retreat_cost_remaining = get_retreat_cost(player_active_pokemon) - retreat_energies_selected.size()
			$SCREEN_LABELS/MAIN_LABELS/small_hint_info_text_label.text = "Select " + str(retreat_cost_remaining) + " energy card(s) to discard"
			
			if retreat_cost_remaining <= 0:
				$BUTTONS/SELECTION_BUTTONS/card_action_button.text = "DISCARD & RETREAT"
				$BUTTONS/SELECTION_BUTTONS/card_action_button.disabled = false
				$BUTTONS/SELECTION_BUTTONS/card_action_button.theme = load("res://uiresources/kenneyUI-green.tres")
			else:
				$BUTTONS/SELECTION_BUTTONS/card_action_button.text = str(retreat_cost_remaining) + " ENERGY REMAINING"
				$BUTTONS/SELECTION_BUTTONS/card_action_button.disabled = true
				$BUTTONS/SELECTION_BUTTONS/card_action_button.theme = load("res://uiresources/kenneyUI.tres")
			return
		
		elif retreat_bench_selection_active or knockout_bench_selection_active:
			if selected_card_for_action != null:
				var prev_card_display = find_card_ui_for_object(selected_card_for_action)
				if prev_card_display:
					prev_card_display.set_selected(false)
			
			selected_card_for_action = clicked_card
			
			var card_display = find_card_ui_for_object(clicked_card)
			if card_display:
				card_display.set_selected(true)
			
			$BUTTONS/SELECTION_BUTTONS/card_action_button.text = "SET AS ACTIVE"
			$BUTTONS/SELECTION_BUTTONS/card_action_button.disabled = false
			$BUTTONS/SELECTION_BUTTONS/card_action_button.theme = load("res://uiresources/kenneyUI-green.tres")
			return
			
			
			
		# Normal card selection mode (not in attach mode)
		# Remove visual effect from previously selected card
		if selected_card_for_action != null:
			var prev_card_display = find_card_ui_for_object(selected_card_for_action)
			if prev_card_display:
				prev_card_display.set_selected(false)
		
		# Store reference to the selected card
		selected_card_for_action = clicked_card
		
		print("Selected card for action: ", selected_card_for_action.metadata["name"])
		
		# Apply visual effect to newly selected card
		var card_display = find_card_ui_for_object(clicked_card)
		if card_display:
			card_display.set_selected(true)
		
		# Update the button text and state based on the selected card
		update_action_button()
			
	else:
		selected_card_for_action = null

######################################################################################################################################################
########################################################### USER INPUT ON CLICK FUNCTIONS ############################################################
######################################################################################################################################################

#                       ######  ##   ##  ####    ##
#                      ##       ##   ##  ## ##   ##
#                      ##       ##   ##  ##  ##  ##
#                      ##       ##   ##  ##   ## ##
#                      ##       #######  ##    ####

######################################################################################################################################################
####################################################### START OF MAIN GAME RUNNING FUNCTIONS #########################################################
	
func _input(event: InputEvent) -> void:
	
	# Press the escape key to quit the game
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			end_game()
			
	if event is InputEventMouseButton and event.pressed:
		
		if $messagebox_container.visible:
			message_acknowledged.emit()
			get_viewport().set_input_as_handled()
			return
		
		var mouse_pos = get_global_mouse_position()
		
		# Check if click is on the cancel or action button - if so, ignore
		if $cancel_selection_mode_view_button.visible and $cancel_selection_mode_view_button.get_global_rect().has_point(mouse_pos):
			return
		if $BUTTONS/SELECTION_BUTTONS/card_action_button.visible and $BUTTONS/SELECTION_BUTTONS/card_action_button.get_global_rect().has_point(mouse_pos):
			return
		
		# Check if mouse is over any card in the visible containers
		var clicked_on_card = false
		
		# NEW: Only check small selection container if it's visible
		if $SELECTION_MODE/small_selection_mode_container.visible:
			for card_ui in $SELECTION_MODE/small_selection_mode_container.get_children():
				if card_ui.get_global_rect().has_point(mouse_pos) and card_selection_mode_enabled == true:
					clicked_on_card = true
					print("the game thinks a card has been clicked")
					break

		# NEW: Only check large selection container if it's visible
		if $SELECTION_MODE/selection_mode_scroller.visible:
			for card_ui in $SELECTION_MODE/selection_mode_scroller/large_selection_mode_container.get_children():
				if card_ui.get_global_rect().has_point(mouse_pos) and card_selection_mode_enabled == true:
					clicked_on_card = true
					break
		
		# If no card was clicked, clear selection
		if not clicked_on_card:

			if selected_card_for_action != null:
				var card_ui = find_card_ui_for_object(selected_card_for_action)
				if card_ui:
					card_ui.set_selected(false)
			
			selected_card_for_action = null
			update_action_button()
			
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
		
	# Connect all the signals so that when parts of the UI are clicked by mouse they can perform actions
	$CARD_COLLECTIONS/PLAYER/player_bench_container.gui_input.connect(array_container_clicked.bind(player_bench))
	$CARD_COLLECTIONS/OPPONENT/opponent_bench_container.gui_input.connect(array_container_clicked.bind(opponent_bench))
	$CARD_COLLECTIONS/PLAYER/player_prize_cards_container.gui_input.connect(array_container_clicked.bind(player_prize_cards))
	$CARD_COLLECTIONS/OPPONENT/opponent_prize_cards_container.gui_input.connect(array_container_clicked.bind(opponent_prize_cards))
	$CARD_COLLECTIONS/PLAYER/player_discard_pile_icon.gui_input.connect(array_container_clicked.bind(player_discard_pile))
	$CARD_COLLECTIONS/OPPONENT/opponent_discard_pile_icon.gui_input.connect(array_container_clicked.bind(opponent_discard_pile))

	$cancel_selection_mode_view_button.pressed.connect(cancel_button_pressed_hide_selection_mode)
	$BUTTONS/SELECTION_BUTTONS/card_action_button.pressed.connect(action_button_pressed_perform_action)
	$BUTTONS/main_screen_attack_buttons_container/cancel_attack_mode_button.pressed.connect(hide_attack_buttons)
	$BUTTONS/main_screen_buttons_container/button_main_attack.pressed.connect(show_attack_buttons)
	$BUTTONS/main_screen_attack_buttons_container.visible = false
	
	$BUTTONS/main_screen_buttons_container/button_main_attack.pressed.connect(show_attack_buttons)
	$BUTTONS/main_screen_attack_buttons_container/cancel_attack_mode_button.pressed.connect(hide_attack_buttons)
	$BUTTONS/main_screen_attack_buttons_container.visible = false
	
	$BUTTONS/main_screen_buttons_container/button_main_power.pressed.connect(flip_coin)
	
	$BUTTONS/main_screen_buttons_container/button_main_retreat.pressed.connect(start_retreat)
	
	$BUTTONS/main_screen_buttons_container/button_main_endturn.pressed.connect(player_end_turn_checks)

	setup_player()
	setup_opponent(opponent_deck_name)
	
	# Player hand and opponent hand have to be connected after the intiial setup to prevent bugs on clicking
	$CARD_COLLECTIONS/PLAYER/player_hand_hbox_container.gui_input.connect(array_container_clicked.bind(player_hand))
	$CARD_COLLECTIONS/OPPONENT/opponent_hand_hbox_container.gui_input.connect(array_container_clicked.bind(opponent_hand))
	
	opponent_setup_pokemon_from_hand()
	draw_prize_cards(false)
	update_action_button()
	
	update_deck_icon(false)
	update_deck_icon(true)
	
	show_enlarged_array_selection_mode(player_hand)
	display_pokemon(false)
	
	
######################################################## END OF MAIN GAME RUNNING FUNCTIONS ##########################################################
######################################################################################################################################################

######################################################################################################################################################			
################################################################# END OF FUNCTIONS ###################################################################
######################################################################################################################################################
