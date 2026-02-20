extends Control

######################################################################################################################################################
################################################################# SET OF VARIABLES ###################################################################
######################################################################################################################################################

# GLOBAL VARIABLES FOR FULL MATCH VARIABLES AND CHANGABLES. MOST ARE SELF EXPLANATORY BY NAME

# TESTING VARIABLES
var amount_of_cards_to_draw = 7		# CAN CHANGE THE AMOUNT OF INITIAL HAND CARDS TO CHECK ARRAYS AND CARD FUNCTIONS
var hide_hidden_cards = false      	# TO SHOW PRIZE CARDS AND OPPONENTS HAND SET TO TRUE. FOR REAL GAME SET TO FALSE

# Game Variables
var turn_number: int = 1

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

var match_just_started_basic_pokemon_required = true
var bench_setup_phase_active = false

var player_energy_played_this_turn: bool = false
var opponent_energy_played_this_turn: bool = false

var energy_card_awaiting_target: card_object = null  # Stores the energy card while selecting its target
var card_attach_mode_active: bool = false

var evolution_card_awaiting_target: card_object = null
var evolution_mode_active: bool = false

var opponents_turn_active: bool = false

# UI VARIABLES
var large_header_text_label: Label
var small_hint_info_text_label: Label

#signals
signal message_acknowledged
signal prize_card_taken

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
	12: Vector2(50, 69)
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
	
	# Prevent showing empty arrays
	if card_array.size() == 0:
		print("Cannot show enlarged array: array is empty")
		return
	
	# Hide attack buttons if they are currently showing
	if $main_screen_attack_buttons_container.visible:
		hide_attack_buttons()
	
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
	
	$player_active_pokemon_energies.visible = false
	$opponent_active_pokemon_energies.visible = false
	
	$player_active_pokemon_hp_container.visible = false
	$opponent_active_pokemon_hp_container.visible = false
	
	$player_bench_container.visible = false
	$opponent_bench_container.visible = false
	
	$opponent_bench_cards_label.visible = false
	$player_bench_cards_label.visible = false
	
	$opponent_prize_cards_label.visible = false
	$player_prize_cards_label.visible = false
	
	$opponent_prize_cards_container.visible = false
	$player_prize_cards_container.visible = false
	
	$player_deck_icon.visible = false
	$opponent_deck_icon.visible = false
	
	$player_discard_pile_icon.visible = false
	$opponent_discard_pile_icon.visible = false
	
	# We do however want to show the header and hint labels
	$small_hint_info_text_label.visible = true
	$large_header_text_label.visible = true
	
	$main_screen_buttons_container.visible = false
	
	for card in $player_active_pokemon_container.get_children():
		card.mouse_filter = MOUSE_FILTER_IGNORE
	for card in $opponent_active_pokemon_container.get_children():
		card.mouse_filter = MOUSE_FILTER_IGNORE
	
	# Show the buttons
	$card_action_button.visible = true
	
	# A specific clause for the start of the game, a basic pokemon HAS to be chosen so we cannot allow cancelling out.
	if match_just_started_basic_pokemon_required == true:
		$cancel_selection_mode_view_button.visible = false
	else:
		$cancel_selection_mode_view_button.visible = true
	
	# Hide action button if viewing opponent's hand
	if card_array == opponent_hand or card_array == opponent_bench or card_array == player_discard_pile or card_array == opponent_discard_pile:
		$card_action_button.visible = false		
	else:
		$card_action_button.visible = true
		
	if $card_action_button.visible:
		$cancel_selection_mode_view_button.offset_left = 35.0
		$cancel_selection_mode_view_button.offset_right = 473.0
	else:
		$cancel_selection_mode_view_button.offset_left = -219.0
		$cancel_selection_mode_view_button.offset_right = 219.0
		
	update_selection_mode_labels(card_array, match_just_started_basic_pokemon_required)
	
	$selection_mode_scroller.visible = false
	$selection_mode_scroller/large_selection_mode_container.visible = false
	
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
	
	$player_active_pokemon_energies.visible = true
	$opponent_active_pokemon_energies.visible = true
	
	$player_active_pokemon_hp_container.visible = true
	$opponent_active_pokemon_hp_container.visible = true
	
	$main_screen_buttons_container.visible = true
	
	# Show the player and oppoents bench
	$player_bench_container.visible = true
	$opponent_bench_container.visible = true
	
	$opponent_bench_cards_label.visible = true
	$player_bench_cards_label.visible = true
	
	$opponent_prize_cards_label.visible = true
	$player_prize_cards_label.visible = true
	
	$opponent_prize_cards_container.visible = true
	$player_prize_cards_container.visible = true
	
	$player_deck_icon.visible = true
	$opponent_deck_icon.visible = true

	$player_discard_pile_icon.visible = true
	$opponent_discard_pile_icon.visible = true
	
	update_deck_icon(false)
	update_deck_icon(true)
	
	# We do however want to show the header and hint labels
	$small_hint_info_text_label.visible = false
	$large_header_text_label.visible = false
	
	$card_action_button.text = "Select a Card"
	$card_action_button.disabled = true
	$card_action_button.theme = load("res://uiresources/kenneyUI.tres")
	
	# Re-enable mouse input on previously hidden containers
	$player_active_pokemon_container.mouse_filter = MOUSE_FILTER_PASS
	$opponent_active_pokemon_container.mouse_filter = MOUSE_FILTER_PASS
	$player_bench_container.mouse_filter = MOUSE_FILTER_PASS
	
	# Re-enable input on cards in the active pokemon containers
	for card in $player_active_pokemon_container.get_children():
		card.mouse_filter = MOUSE_FILTER_PASS
	for card in $opponent_active_pokemon_container.get_children():
		card.mouse_filter = MOUSE_FILTER_PASS
	
# Displays both the player and opponents hand cards. Shows players at the top of screen and opponents in top right smaller.
func display_hand_cards_array(hand: Array, hand_container, card_size: Vector2, face_down: bool = false):
	
	# Load the script that displays card images
	var card_display_script = load("res://gdscripts/cardimage.gd")
	
	# Clear existing cards from container to prevent stale entries when cards leave or enter the hand
	for child in hand_container.get_children():
		child.queue_free()
	
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
		
		# Replace the visual distinction block in display_hand_cards_array():

		# If this is the active Pokemon (last card in attach mode), add visual distinction
		if (card_attach_mode_active or evolution_mode_active) and index == hand.size() - 1:
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
	var active_container = $opponent_active_pokemon_container if is_opponent else $player_active_pokemon_container
	var bench_container = $opponent_bench_container if is_opponent else $player_bench_container
	
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
		$large_header_text_label.text = "Build Your Bench"
		$small_hint_info_text_label.text = "Select up to 5 Pokémon to place on your bench"
		return
	
	# Determine which array we're displaying and set appropriate text
	if array_displayed == player_hand:
		if is_starting_game:
			$large_header_text_label.text = "Select a Basic Pokémon"
			$small_hint_info_text_label.text = "You must place a Basic Pokémon as your Active Pokémon to start"
		else:
			$large_header_text_label.text = "Your Hand"
			$small_hint_info_text_label.text = "Select a card to play"
	
	elif array_displayed == player_bench:
		$large_header_text_label.text = "Your Bench"
		$small_hint_info_text_label.text = "Select a card to set as your Active Pokémon"
	
	elif array_displayed == opponent_hand:
		$large_header_text_label.text = "Opponent's Hand"
		$small_hint_info_text_label.text = "Viewing opponent's hand"
		
	elif array_displayed == opponent_bench:
		$large_header_text_label.text = "Opponent's Bench"
		$small_hint_info_text_label.text = "Viewing opponent's bench"
		
	elif array_displayed == player_prize_cards:
		$large_header_text_label.text = "Your Prize Cards"
		$small_hint_info_text_label.text = "Viewing your prize cards"
		
	elif array_displayed == opponent_prize_cards:
		$large_header_text_label.text = "Opponent's prize cards"
		$small_hint_info_text_label.text = "Viewing opponent's prize cards"

	elif array_displayed == player_discard_pile:
		$large_header_text_label.text = "Your Discard Pile"
		$small_hint_info_text_label.text = "Viewing your discard pile"
		
	elif array_displayed == opponent_discard_pile:
		$large_header_text_label.text = "Opponent's Discard Pile"
		$small_hint_info_text_label.text = "Viewing opponent's discard pile"

# Displays the prize cards for the specified player in their prize cards container
func display_prize_cards(is_opponent: bool) -> void:
	
	# Get the appropriate container and prize cards array
	var prize_cards_container: HBoxContainer
	var prize_cards: Array
	
	if is_opponent:
		prize_cards_container = $opponent_prize_cards_container
		prize_cards = opponent_prize_cards		
	else:
		prize_cards_container = $player_prize_cards_container
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

# Add this new function after display_pokemon()
func display_active_pokemon_energies() -> void:
	# Clear the energies container first
	for child in $player_active_pokemon_energies.get_children():
		child.queue_free()
	
	# If no active pokemon, nothing to display
	if player_active_pokemon == null:
		return
	
	# If active pokemon has no attached energies, nothing to display
	if player_active_pokemon.attached_energies.size() == 0:
		return
	
	# Load the card display script for energy cards
	var card_display_script = load("res://gdscripts/cardimage.gd")
	
	# Display each attached energy
	for attached_energy in player_active_pokemon.attached_energies:
		var energy_display = TextureRect.new()
		energy_display.set_script(card_display_script)
		$player_active_pokemon_energies.add_child(energy_display)
		
		# Display energy cards smaller than the Pokemon (use card_scales[10])
		energy_display.load_card_image(attached_energy.uid, card_scales[11], attached_energy)

# Displays HP circles above the active pokemon, colouring red from damage taken
func display_hp_circles_above_align(active_pokemon: card_object, is_opponent: bool) -> void:
	var hp_grid_container = $opponent_active_pokemon_hp_container if is_opponent else $player_active_pokemon_hp_container
	
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
	
	$main_screen_buttons_container.visible = false
	$main_screen_attack_buttons_container.visible = true
	
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
		$main_screen_attack_buttons_container.add_child(btn)
		
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
	for child in $main_screen_attack_buttons_container.get_children():
		# Skip the cancel button — it's a permanent node, not dynamically generated
		if child.name == "cancel_attack_mode_button":
			continue
		child.queue_free()
	
	$main_screen_attack_buttons_container.visible = false
	$main_screen_buttons_container.visible = true

# Displays the message box with given text and pauses execution until the player clicks
func show_message(message_text: String) -> void:
	$messagebox_container.visible = true
	$messagebox_container/messagebox_text_label.text = message_text
	
	# Suspend this function here — engine keeps running until signal fires
	await message_acknowledged
	
	$messagebox_container.visible = false

# Creates a floating label at a given position that drifts upward and fades out over 2 seconds
func show_floating_label(message: String, spawn_position: Vector2) -> void:
	var label = Label.new()
	label.text = message
	
	# uncomment these to make it centrally aligned instead of left aligned
	#label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	#label.custom_minimum_size = Vector2(300, 0)
	
	label.position = spawn_position
	label.modulate = Color(1, 1, 1, 1)
	
	# Apply kenney theme for the pixel font, then override colour and size
	label.theme = load("res://uiresources/kenneyUI.tres")
	label.add_theme_color_override("font_color", Color.BLACK)
	label.add_theme_font_size_override("font_size", 32)
	
	add_child(label)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", spawn_position.y - 150, 2.0)
	tween.tween_property(label, "modulate:a", 0.0, 2.0)
	
	await tween.finished
	label.queue_free()

# Changes the deck icon to show how many cards are (roughly)
func update_deck_icon(is_opponent: bool) -> void:
	var deck = opponent_deck if is_opponent else player_deck
	var widget = $opponent_deck_icon if is_opponent else $player_deck_icon
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
		evolution_mode_active
	)

	if should_disable:
		$main_screen_buttons_container/button_main_attack.theme = load("res://uiresources/kenneyUI.tres")
		$main_screen_buttons_container/button_main_power.theme = load("res://uiresources/kenneyUI.tres")
		$main_screen_buttons_container/button_main_retreat.theme = load("res://uiresources/kenneyUI.tres")
		$main_screen_buttons_container/button_main_endturn.theme = load("res://uiresources/kenneyUI.tres")
	else:
		$main_screen_buttons_container/button_main_attack.theme = load("res://uiresources/kenneyUI-blue.tres")
		$main_screen_buttons_container/button_main_power.theme = load("res://uiresources/kenneyUI-blue.tres")
		$main_screen_buttons_container/button_main_retreat.theme = load("res://uiresources/kenneyUI-blue.tres")
		$main_screen_buttons_container/button_main_endturn.theme = load("res://uiresources/kenneyUI-blue.tres")	
				
	$main_screen_buttons_container/button_main_attack.disabled = should_disable
	$main_screen_buttons_container/button_main_power.disabled = should_disable
	$main_screen_buttons_container/button_main_retreat.disabled = should_disable
	$main_screen_buttons_container/button_main_endturn.disabled = should_disable	

# Updates the discard pile icon to show the top card and count for the specified player
func update_discard_pile_display(is_opponent: bool) -> void:
	var discard = opponent_discard_pile if is_opponent else player_discard_pile
	var icon = $opponent_discard_pile_icon if is_opponent else $player_discard_pile_icon
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
	
############################################################### END DISPLAY FUNCTIONS ################################################################
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
	display_hand_cards_array(opponent_hand, opponent_hand_container, card_scales[12], hide_hidden_cards)

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
	$card_action_button.text = "Select a Card"
	$card_action_button.disabled = true
	$card_action_button.theme = load("res://uiresources/kenneyUI.tres")
	
	selected_card_for_action = null
	
	$cancel_selection_mode_view_button.text = "Done"
	$cancel_selection_mode_view_button.theme = load("res://uiresources/kenneyUI-green.tres")
	
	# Show the hand again for bench pokemon selection
	show_enlarged_array_selection_mode(player_hand)	
	
############################################################### END GAME LOAD FUNCTIONS ##############################################################
######################################################################################################################################################

#                    #######  #######    #######  #######
#                    ##      ##     ##  ##        ##
#                    ##      ##     ##  ##        #######
#                    ##      ##     ##  ##        ##
#                    #######  #######   ##        #######

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

# Function to change the text, enabled mode and function of the action button.
func update_action_button() -> void:
	
	# We need to see what the button can do by running the function get_card_action
	var action_info = get_card_action(selected_card_for_action)
	var action_button = $card_action_button
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
	if $small_selection_mode_container.visible:
		for card_ui in $small_selection_mode_container.get_children():
			# Only check if this is a TextureRect with card_ref
			if card_ui is TextureRect and "card_ref" in card_ui:
				if card_ui.card_ref == card_obj:
					return card_ui
	
	# Check large selection container
	if $selection_mode_scroller.visible:
		for card_ui in $selection_mode_scroller/large_selection_mode_container.get_children():
			# Only check if this is a TextureRect with card_ref
			if card_ui is TextureRect and "card_ref" in card_ui:
				if card_ui.card_ref == card_obj:
					return card_ui
	
	return null

# Function to get all basic pokemon from a given array of cards
func get_all_basic_pokemon(card_array: Array) -> Array:
	var basic_pokemon = []
	for card in card_array:
		if card.metadata.get("supertype") == "Pokémon" and card.metadata.has("subtypes") and card.metadata["subtypes"].has("Basic"):
			basic_pokemon.append(card)
	return basic_pokemon

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
	$large_header_text_label.text = "ATTACHING " + energy_name.to_upper()
	$small_hint_info_text_label.text = "Select a Pokémon to attach " + energy_name + " to"
	
	# Update action button text
	$card_action_button.text = "ATTACH ENERGY"
	
# Add this new function after start_energy_attachment()
func perform_energy_attachment() -> void:
	# Validate that we have an energy card awaiting attachment
	if energy_card_awaiting_target == null:
		print("Error: No energy card awaiting attachment")
		return
	
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
	
	# Refresh the hand display to remove the attached energy
	display_hand_cards_array(player_hand, $player_hand_hbox_container, card_scales[11])
	
	# Refresh the active Pokemon display to show the attached energy
	display_pokemon(false)	
	
	# Display the attached energies on the active Pokemon
	display_active_pokemon_energies()

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

	return drawn_card

# Resets placed_on_field_this_turn to false for all pokemon on the specified player's field
func reset_field_pokemon_turn_flags(is_opponent: bool) -> void:
	var active = opponent_active_pokemon if is_opponent else player_active_pokemon
	var bench = opponent_bench if is_opponent else player_bench

	if active != null:
		active.placed_on_field_this_turn = false

	for bench_pokemon in bench:
		bench_pokemon.placed_on_field_this_turn = false

# Called when the player presses the end turn button to reset per-turn variables and begin next turn
func player_end_turn_checks() -> void:
	opponents_turn_active = true
	turn_number += 1
	
	update_main_screen_buttons()
	show_floating_label("End turn", Vector2(800, 850))
	
	await check_all_knockouts()
	
	await get_tree().create_timer(0.5).timeout
	player_energy_played_this_turn = false
	reset_field_pokemon_turn_flags(false)
	player_start_turn_checks()

# Called at the start of the player's turn to perform mandatory actions
func player_start_turn_checks() -> void:

	turn_number += 1
	var drawn_card = draw_card_from_deck(false)
	
	opponents_turn_active = false
	update_main_screen_buttons()
	
	if drawn_card == null:
		return

	display_hand_cards_array(player_hand, $player_hand_hbox_container, card_scales[11])
	update_deck_icon(false)
	show_floating_label("Start turn", Vector2(800, 850))
	
# Scans active and bench for Pokemon that the given evolution card can legally evolve from
func get_valid_evolution_targets(evolution_card: card_object, is_opponent: bool) -> Array:
	var active = opponent_active_pokemon if is_opponent else player_active_pokemon
	var bench = opponent_bench if is_opponent else player_bench
	var valid_targets = []
	
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
	$large_header_text_label.text = "EVOLVING INTO " + evo_name.to_upper()
	$small_hint_info_text_label.text = "Select a Pokémon to evolve into " + evo_name
	
	$card_action_button.text = "EVOLVE"
	$card_action_button.disabled = true
	$card_action_button.theme = load("res://uiresources/kenneyUI.tres")

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

# Removes a prize card from the specified player's prizes and adds it to their hand
func take_prize_card(card: card_object, is_opponent: bool) -> void:
	var prizes = opponent_prize_cards if is_opponent else player_prize_cards
	var hand = opponent_hand if is_opponent else player_hand
	
	prizes.erase(card)
	card.current_location = "hand"
	hand.append(card)
	
	display_prize_cards(is_opponent)
	var hand_container = $opponent_hand_hbox_container if is_opponent else $player_hand_hbox_container
	var hand_scale = card_scales[12] if is_opponent else card_scales[11]
	display_hand_cards_array(hand, hand_container, hand_scale)

func player_pick_prize_card() -> void:
	prize_card_selection_active = true
	$card_action_button.position.x += 210
	show_enlarged_array_selection_mode(player_prize_cards)
	$large_header_text_label.text = "TAKE A PRIZE CARD"
	$small_hint_info_text_label.text = "Select a prize card to add to your hand"
	$cancel_selection_mode_view_button.visible = false
	$card_action_button.text = "TAKE PRIZE"
	$card_action_button.disabled = true
	$card_action_button.theme = load("res://uiresources/kenneyUI.tres")

########################################################## END CORE FUNCTIONALITY FUNCTIONS ##########################################################
######################################################################################################################################################

#	           ##    ########  #######     ##     ######  ##   ##
#             ####      ##       ##       ####    ##      ##  ##
#            ##  ##     ##       ##      ##  ##   ##      ####
#           ########    ##       ##     ########  ##      ##  ##
#          ##      ##   ##       ##    ##      ## ######  ##    ##

######################################################################################################################################################
############################################################# ATTACK AND DAMAGE FUNCTIONS ############################################################

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
	
	var attacking_types = player_active_pokemon.metadata.get("types", ["Colorless"])
	var result = calculate_final_damage(base_damage, attacking_types, opponent_active_pokemon)
	var final_damage = result["damage"]

	for modifier in result["modifiers"]:
		show_floating_label(modifier, Vector2(1420, 250))
		await get_tree().create_timer(0.5).timeout

	show_floating_label("-"+str(final_damage) + "HP", Vector2(1420, 250))
	
	opponent_active_pokemon.current_hp = max(0, opponent_active_pokemon.current_hp - final_damage)
	
	print(player_active_pokemon.metadata["name"] + " used " + attack.get("name", "") + " for " + str(final_damage) + " damage!")
	print(opponent_active_pokemon.metadata["name"] + " HP remaining: " + str(opponent_active_pokemon.current_hp))
	
	display_hp_circles_above_align(opponent_active_pokemon, true)
	hide_attack_buttons()
	
	await check_all_knockouts()
	
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

# Checks a single Pokemon's HP and if zero or below, discards it and clears its field position
func check_and_handle_knockout(pokemon: card_object, is_opponent: bool) -> bool:
	if pokemon == null or pokemon.current_hp > 0:
		return false
	
	var ko_name = pokemon.metadata.get("name", "Unknown")
	var active = opponent_active_pokemon if is_opponent else player_active_pokemon
	var bench = opponent_bench if is_opponent else player_bench
	
	await show_message(ko_name.to_upper() + " WAS KNOCKED OUT!")
	
	send_card_to_discard(pokemon, is_opponent)
	
	if pokemon == active:
		if is_opponent:
			opponent_active_pokemon = null
		else:
			player_active_pokemon = null
	elif pokemon in bench:
		bench.erase(pokemon)
	
	display_pokemon(is_opponent)
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
			await player_pick_prize_card()
			await prize_card_taken
	
	if results["opponent_kos"] > 0:
		await handle_post_knockout(true)
	
	if results["player_kos"] > 0:
		await handle_post_knockout(false)
	
	return results

##########################################################################################################
# TESTING - THIS FUNCTION NEEDS AMENDING TO SWITCH IN BENCH POKEMON TO ACTIVE PROPERLY THROUGH CHOICE
##########################################################################################################
#### vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv #######
# After KOs are processed, promotes a bench Pokemon to active or ends the game if none remain
func handle_post_knockout(is_opponent: bool) -> void:
	var active = opponent_active_pokemon if is_opponent else player_active_pokemon
	var bench = opponent_bench if is_opponent else player_bench
	
	if active != null:
		return
	
	if bench.size() == 0:
		await show_message("NO POKEMON REMAINING!")
		game_end_logic(not is_opponent)
		return
	
	if is_opponent:
		opponent_active_pokemon = bench.pop_front()
		opponent_active_pokemon.current_location = "active"
		display_pokemon(true)
		await show_message("OPPONENT SET " + opponent_active_pokemon.metadata["name"].to_upper() + "AS THEIR ACTIVE POKEMON!")
	else:
		pass


########################################################## END ATTACK AND DAMAGE FUNCTIONS ###########################################################
######################################################################################################################################################

#                ##      ##      ########  ####    ##  ########
#               ####    ####        ##     ## ##   ##     ##
#              ##  ##  ##  ##       ##     ##  ##  ##     ##
#             ##    ####    ##      ##     ##   ## ##     ##
#            ##      ##      ##  ########  ##    ####   #######

######################################################################################################################################################
################################################### SMALL FUNCTIONS TO HELP WITH CODE READABILITY ####################################################

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

################################################# END SMALL FUNCTIONS TO HELP WITH CODE READABILITY ##################################################
######################################################################################################################################################

# #######  ######   ##   ##        #######  ##   ##    ######    ########  #######  #######
# ##       ##   ##  ##   ##        ##       ##   ##  ##      ##     ##     ##       ## 
# ##       ######   ##   ##  ##### ##       #######  ##      ##     ##     ##       #######
# ##       ##       ##   ##        ##       ##   ##  ##      ##     ##     ##       ##
# #######  ##       #######        #######  ##   ##    ######     #######  #######  #######

######################################################################################################################################################
#################################################### OPPONENT PRIORITISE FUNCTIONALITY FUNCTIONS #####################################################

# THESE FUNCTIONS ARE SPECIFICALLY FOR DECIDING THE BEST POKEMON FROM A GIVEN ARRAY.
# USED TO CHOOSE THE FIRST ACTIVE POKEMON AT MATCH START, REPLACING ACTIVE POKEMON FROM BENCH, AND CHOOSING BEST CARD FOR DECK SEARCHING EFFECTS

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
			
################################################### END OPPONENT PRIORITISE FUNCTIONALITY FUNCTIONS ##################################################
######################################################################################################################################################
 
# #######  ######   ##   ##        ######   #######    ####### #######
# ##       ##   ##  ##   ##        ##      ##     ##  ##       ##
# ##       ######   ##   ##  ##### ##      ##     ##  ##       #######
# ##       ##       ##   ##        ##      ##     ##  ##       ##
# #######  ##       #######        #######  #######   ##       #######

######################################################################################################################################################
###################################################### OPPONENT GENERAL FUNCTIONALITY FUNCTIONS ######################################################

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

# Function to select the best active pokemon and up to 3 bench pokemon from opponent's hand
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

# Function to set up opponent's active and bench pokemon using the priority condition criteria scoring selection
func opponent_setup_pokemon_from_hand() -> void:
	var selected_pokemon = select_opponent_pokemon_for_setup(opponent_hand)
	var active_pokemon = selected_pokemon.get("active")
	var bench_pokemon_list = selected_pokemon.get("bench", [])
	
	# Remove active pokemon from hand and set it as active
	opponent_hand.erase(active_pokemon)
	opponent_active_pokemon = active_pokemon
	opponent_active_pokemon.placed_on_field_this_turn = true
	
	# Remove bench pokemon from hand and add to bench
	for bench_pokemon in bench_pokemon_list:
		opponent_hand.erase(bench_pokemon)
		bench_pokemon.placed_on_field_this_turn = true
		opponent_bench.append(bench_pokemon)
	
	# Update displays
	display_pokemon(true)  # true = opponent
	display_hand_cards_array(opponent_hand, $opponent_hand_hbox_container, card_scales[12], hide_hidden_cards)

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
	
	$card_action_button.text = "Select a Card"
	$card_action_button.disabled = true
	$card_action_button.theme = load("res://uiresources/kenneyUI.tres")
	
	# Check if we're in attach mode - handle differently
	if card_attach_mode_active:
		# In attach mode, we're attaching the energy to the selected Pokemon
		perform_energy_attachment()
		return
	
	if evolution_mode_active:
		perform_evolution(false)
		
		evolution_card_awaiting_target = null
		selected_card_for_action = null
		evolution_mode_active = false
		
		hide_selection_mode_display_main()
		display_hand_cards_array(player_hand, $player_hand_hbox_container, card_scales[11])
		display_pokemon(false)
		display_active_pokemon_energies()
		return	
	
	if prize_card_selection_active:
		take_prize_card(selected_card_for_action, false)
		prize_card_selection_active = false
		selected_card_for_action = null
		
		$card_action_button.position.x -= 210
		hide_selection_mode_display_main()
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
				display_hand_cards_array(player_hand, $player_hand_hbox_container, card_scales[11])
				match_just_started_basic_pokemon_required = false
				$card_action_button.position.x -= 210 
				
				# After active pokemon is set, start the bench setup phase
				start_bench_setup_phase()
			else:
				# After first turn - add to bench instead
				add_pokemon_to_bench(selected_card_for_action)
				display_hand_cards_array(player_hand, $player_hand_hbox_container, card_scales[11])
				display_pokemon(false)  # false = player
				
				# If in bench setup phase, keep the modal open and re-show the hand for more selections
				if bench_setup_phase_active:
					selected_card_for_action = null
					show_enlarged_array_selection_mode(player_hand)
				else:
					hide_selection_mode_display_main()
		
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
	
	if evolution_mode_active:
		print("Evolution cancelled")
		evolution_card_awaiting_target = null
		evolution_mode_active = false
		hide_selection_mode_display_main()
		return
	
	# If we were in bench setup phase, end it and draw prize cards
	if bench_setup_phase_active:
		bench_setup_phase_active = false
		$cancel_selection_mode_view_button.text = "Cancel"
		$cancel_selection_mode_view_button.theme = load("res://uiresources/kenneyUI-red.tres")
		draw_prize_cards(true)
	
	hide_selection_mode_display_main()

# Main function to show all hand cards larger when the player's hand is clicked
func player_hand_clicked_show_hand(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		show_enlarged_array_selection_mode(player_hand)

# Main function to show all hand cards larger when the opponent's hand is clicked		
func opponent_hand_clicked_show_hidden_hand(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		show_enlarged_array_selection_mode(opponent_hand)

# Main function to show all of player's bench cards larger when clicked
func player_bench_clicked_show_bench(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		show_enlarged_array_selection_mode(player_bench)

# Main function to show all of opponent's bench cards larger when clicked
func opponent_bench_clicked_show_bench(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		show_enlarged_array_selection_mode(opponent_bench)

# Called when a card in selection mode is clicked
func this_card_clicked(clicked_card: card_object) -> void:
	if card_selection_mode_enabled == true:
		
		# Check if we're in card attach mode (selecting a target Pokemon)
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
			$card_action_button.text = "ATTACH ENERGY"
			$card_action_button.disabled = false
			$card_action_button.theme = load("res://uiresources/kenneyUI-green.tres")
			return
			
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
			
			$card_action_button.text = "EVOLVE"
			$card_action_button.disabled = false
			$card_action_button.theme = load("res://uiresources/kenneyUI-green.tres")
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

# Opens the opponent's discard pile for viewing in selection mode
func opponent_discard_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if opponent_discard_pile.size() > 0:
			show_enlarged_array_selection_mode(opponent_discard_pile)
			
# Opens the player's discard pile for viewing in selection mode
func player_discard_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if player_discard_pile.size() > 0:
			show_enlarged_array_selection_mode(player_discard_pile)

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
			return
		
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
	
	$player_discard_pile_icon.gui_input.connect(player_discard_clicked)
	$opponent_discard_pile_icon.gui_input.connect(opponent_discard_clicked)
	
	$cancel_selection_mode_view_button.pressed.connect(cancel_button_pressed_hide_selection_mode)
	$card_action_button.pressed.connect(action_button_pressed_perform_action)
	$main_screen_attack_buttons_container/cancel_attack_mode_button.pressed.connect(hide_attack_buttons)
	$main_screen_buttons_container/button_main_attack.pressed.connect(show_attack_buttons)
	$main_screen_attack_buttons_container.visible = false
	
	$main_screen_buttons_container/button_main_attack.pressed.connect(show_attack_buttons)
	$main_screen_attack_buttons_container/cancel_attack_mode_button.pressed.connect(hide_attack_buttons)
	$main_screen_attack_buttons_container.visible = false
	
	$main_screen_buttons_container/button_main_endturn.pressed.connect(player_end_turn_checks)

	setup_player()
	setup_opponent("testing1")
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
