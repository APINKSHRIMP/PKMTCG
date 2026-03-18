extends Control

# ─── Constants ───────────────────────────────────────────────────────────────

const PLAYER_DATA_PATH     := "C:/pkm-tcg-gdt/playerdata/player_data.json"
const SET_DICT_PATH        := "C:/pkm-tcg-gdt/playerdata/set_dictionary.json"
const OWNED_CARDS_FOLDER   := "C:/pkm-tcg-gdt/playerdata/playerownedcards/"
const PLAYER_DECKS_FOLDER  := "C:/pkm-tcg-gdt/playerdata/playerdecks/"

const CARD_SIZE     := Vector2(183, 254)
const CARD_H_SEP    := 2
const CARD_V_SEP    := 2
const COLUMNS       := 9
const MAX_COPIES    := 4
const DECK_SIZE     := 60

# ─── State ───────────────────────────────────────────────────────────────────

# Ordered array of dictionaries: [{set_id, set_name}, ...]
var set_list         : Array = []
# Indices into set_list that are unlocked — used for next/prev wrapping
var unlocked_indices : Array = []
# Current position in unlocked_indices (NOT set_list)
var current_unlock_pos : int = 0

# The player's current deck: card_id → count in deck
var deck_cards       : Dictionary = {}
var total_deck_count : int = 0

# Tracks which card IDs are basic energies (no 4-copy cap)
var basic_energy_ids : Dictionary = {}

# The deck name currently loaded
var current_deck_name : String = ""

# Reference to the load-deck popup so we can free it later
var load_popup       : CanvasLayer = null

# Tracks which set is currently being loaded — used to abort a progressive
# load if the player switches sets before the previous one finishes
var _loading_set_id  : String = ""

# ─── Zoom state ──────────────────────────────────────────────────────────────

# Reference to the zoom overlay (CanvasLayer) so we can remove it on release
var zoom_overlay : CanvasLayer = null
# Whether we're currently in zoom mode
var is_zoomed : bool = false

# ─── Node references ─────────────────────────────────────────────────────────

@onready var grid             : GridContainer = $deck_grid_container
@onready var save_btn         : Button        = $deck_save_button
@onready var cancel_btn       : Button        = $deck_cancel_button
@onready var empty_btn        : Button        = $empty_deck_button
@onready var load_btn         : Button        = $load_deck_button
@onready var next_btn         : Button        = $next_set
@onready var prev_btn         : Button        = $previous_set
@onready var set_label        : Label         = $set_name_label
@onready var deck_name_edit   : LineEdit      = $deck_name
@onready var deck_count_label : Label         = $deck_count_label

# ─── Lifecycle ───────────────────────────────────────────────────────────────

func _ready() -> void:
	# Start background music — loops until scene changes
	SoundManagerScript.play_bgm("res://audio/bgm/coin_mode.ogg", true)
	
	# Load data sources
	_load_set_dictionary()
	var last_set_id := _load_player_data()    # returns last_set_loaded string
	_build_unlocked_indices()
	_find_starting_set(last_set_id)

	# Wire up button signals
	save_btn.pressed.connect(_on_save_pressed)
	cancel_btn.pressed.connect(_on_cancel_pressed)
	empty_btn.pressed.connect(_on_empty_deck_pressed)
	load_btn.pressed.connect(_on_load_deck_pressed)
	next_btn.pressed.connect(_on_next_set)
	prev_btn.pressed.connect(_on_prev_set)

	# Limit deck name to 20 characters — LineEdit.max_length natively
	# blocks further typing once the limit is reached
	deck_name_edit.max_length = 25
	
	# Re-evaluate save button whenever the name is typed or cleared
	deck_name_edit.text_changed.connect(_on_deck_name_changed)

	# Wrap the grid in a scroll container so large sets can scroll
	_wrap_grid_in_scroll_container()

	# Load the player's current deck
	_load_deck(current_deck_name)

	# Initial UI state
	_update_deck_count_label()
	_refresh_save_button()

	# Display the starting set
	await get_tree().process_frame
	_display_current_set()


# ─── Data loading ────────────────────────────────────────────────────────────

## Reads set_dictionary.json into set_list.
## Each entry is {set_id: "base1", set_name: "Base"}.
func _load_set_dictionary() -> void:
	var file := FileAccess.open(SET_DICT_PATH, FileAccess.READ)
	if file == null:
		push_error("DeckBuild: cannot open " + SET_DICT_PATH)
		return
	var data = JSON.parse_string(file.get_as_text())
	file.close()

	if data is Dictionary and data.has("set_list"):
		set_list = data["set_list"]


## Reads player_data.json — returns the last_set_loaded value.
## Also stores the current deck name.
func _load_player_data() -> String:
	var file := FileAccess.open(PLAYER_DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("DeckBuild: cannot open " + PLAYER_DATA_PATH)
		return "base1"
	var data = JSON.parse_string(file.get_as_text())
	file.close()

	if not data is Dictionary:
		return "base1"

	current_deck_name = data.get("deck", "")
	deck_name_edit.text = current_deck_name.replace("_", " ")

	return data.get("last_set_loaded", "base1")


## Builds unlocked_indices — an array of indices into set_list whose
## set is unlocked.  Sets are always unlocked in order, so we scan
## until we hit the first locked set then stop.
func _build_unlocked_indices() -> void:
	unlocked_indices.clear()
	for i in range(set_list.size()):
		var set_id : String = set_list[i]["set_id"]
		var owned_path := OWNED_CARDS_FOLDER + set_id + "_player_owned_cards.json"
		var file := FileAccess.open(owned_path, FileAccess.READ)
		if file == null:
			continue
		var data = JSON.parse_string(file.get_as_text())
		file.close()
		if data is Dictionary and data.get("set_unlocked", false):
			unlocked_indices.append(i)


## Finds the position in unlocked_indices that matches the given set_id.
## Falls back to position 0 if not found.
func _find_starting_set(set_id: String) -> void:
	for i in range(unlocked_indices.size()):
		var idx = unlocked_indices[i]
		if set_list[idx]["set_id"] == set_id:
			current_unlock_pos = i
			return
	current_unlock_pos = 0


## Loads a deck file from the playerdecks folder.
## Populates deck_cards dictionary and total_deck_count.
func _load_deck(deck_name: String) -> void:
	deck_cards.clear()
	total_deck_count = 0

	if deck_name == "":
		return

	var path := PLAYER_DECKS_FOLDER + deck_name + ".json"
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("DeckBuild: cannot open deck " + path)
		return
	var data = JSON.parse_string(file.get_as_text())
	file.close()

	if not data is Array:
		return

	for entry in data:
		if entry is Dictionary and entry.has("id") and entry.has("count"):
			var card_id : String = entry["id"]
			var count   : int    = int(entry["count"])
			deck_cards[card_id] = count
			total_deck_count += count


## Loads the player_owned_cards JSON for a given set_id.
## Returns the "owned_cards" array, or an empty array on failure.
func _load_owned_cards_for_set(set_id: String) -> Array:
	var path := OWNED_CARDS_FOLDER + set_id + "_player_owned_cards.json"
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("DeckBuild: cannot open " + path)
		return []
	var data = JSON.parse_string(file.get_as_text())
	file.close()

	if data is Dictionary and data.has("owned_cards"):
		return data["owned_cards"]
	return []


# ─── Scroll container ───────────────────────────────────────────────────────

## Wraps the GridContainer inside a ScrollContainer so the card grid
## can scroll vertically when a set has more cards than fit on screen.
## This is done in code rather than the scene file to keep the .tscn simple.
func _wrap_grid_in_scroll_container() -> void:
	var parent = grid.get_parent()

	var scroll := ScrollContainer.new()
	scroll.name = "deck_scroll_container"
	# The scroll container inherits the grid's position and size from the scene
	scroll.position = grid.position
	scroll.size     = grid.size
	# Only allow vertical scrolling — horizontal is handled by column count
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode   = ScrollContainer.SCROLL_MODE_AUTO

	# Reparent: remove grid from root, add scroll to root, put grid inside scroll
	parent.remove_child(grid)
	parent.add_child(scroll)
	scroll.add_child(grid)

	# Reset grid position inside the scroll container
	grid.position = Vector2.ZERO
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", CARD_H_SEP)
	grid.add_theme_constant_override("v_separation", CARD_V_SEP)


# ─── Grid display ────────────────────────────────────────────────────────────

## Clears the grid and populates it with cards from the current set.
## Cards are added one per frame so the player sees them appear progressively
## rather than a single freeze while the entire set loads at once.
func _display_current_set() -> void:
	# Determine which set to display
	if unlocked_indices.is_empty():
		return
	var set_idx  : int        = unlocked_indices[current_unlock_pos]
	var set_id   : String     = set_list[set_idx]["set_id"]
	var set_name : String     = set_list[set_idx]["set_name"]

	# Update the set name label
	set_label.text = set_name

	# Clear existing cards — kill any active tweens first
	_clear_grid()

	# Load this set's owned-cards data
	var owned_cards := _load_owned_cards_for_set(set_id)

	# Store which set we're currently loading so we can detect if the player
	# switches set mid-load and abort the old load gracefully
	_loading_set_id = set_id

	# Populate the grid one card per frame for progressive visual loading
	for card_data in owned_cards:
		# If the player switched sets while we were still loading, stop
		if _loading_set_id != set_id:
			return
		_add_card_to_grid(card_data)
		await get_tree().process_frame


## Removes all card entries from the grid, killing tweens to avoid
## errors from animating freed nodes.
func _clear_grid() -> void:
	for child in grid.get_children():
		# Each child is a TextureRect (card_rect) added directly to the grid
		var tw = child.get_meta("deck_tween", null)
		if tw:
			tw.kill()
		child.queue_free()
	# queue_free is deferred, so wait a frame before adding new children
	await get_tree().process_frame


## Creates a single card entry in the grid.
## card_data is a dictionary: {card_id, owned, is_basic_energy}
func _add_card_to_grid(card_data: Dictionary) -> void:
	var card_id   : String = card_data["card_id"]
	var owned     : int    = int(card_data["owned"])
	var is_energy : bool   = card_data.get("is_basic_energy", false)
	var in_deck   : int    = deck_cards.get(card_id, 0)

	# Track basic energy IDs globally so click handlers can check
	if is_energy:
		basic_energy_ids[card_id] = true

	# ── Card image ──
	# TextureRect is added directly to the grid — no wrapper Control needed.
	# The key to preventing overlap is EXPAND_IGNORE_SIZE which tells the
	# TextureRect to report custom_minimum_size to the GridContainer for
	# layout purposes rather than the texture's native pixel dimensions.
	# Without this, a 245x342 texture would make the grid cell 245x342
	# even though we want 150x207.
	var card_rect := TextureRect.new()
	var card_set := card_id.split("-")[0]
	var image_path := "res://cardimages/" + card_set + "/Large/" + card_id + ".png"
	var card_texture = load(image_path)

	if card_texture != null:
		card_rect.texture = card_texture
	else:
		push_error("DeckBuild: missing card image " + image_path)

	card_rect.custom_minimum_size = CARD_SIZE
	card_rect.size                = CARD_SIZE
	# EXPAND_IGNORE_SIZE: the TextureRect ignores its texture's native size
	# for layout. The GridContainer sees custom_minimum_size (150x207) instead
	# of the texture's actual pixel dimensions. This is what prevents overlap.
	card_rect.expand_mode         = TextureRect.EXPAND_IGNORE_SIZE
	# STRETCH_KEEP_ASPECT_CENTERED: scales the texture to fit within the rect
	# while preserving aspect ratio. Combined with EXPAND_IGNORE_SIZE, the
	# texture scales DOWN to fit 150x207 rather than dictating the cell size.
	card_rect.stretch_mode        = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# Prevent the card from growing if the grid offers more space
	card_rect.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	card_rect.size_flags_vertical   = Control.SIZE_SHRINK_BEGIN
	# Pivot at center so scale animations grow from the middle
	card_rect.pivot_offset        = CARD_SIZE / 2.0

	# ── Count label ──
	# Overlaid on the bottom of the card image. The label and its background
	# are children of the card_rect so they move with it during animations.
	var label_bg := ColorRect.new()
	label_bg.color = Color(0, 0, 0, 0.65)
	label_bg.position = Vector2(0, CARD_SIZE.y - 22)
	label_bg.size = Vector2(CARD_SIZE.x, 22)
	label_bg.z_index = 10
	label_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var count_label := Label.new()
	var kenney_theme = load("res://uiresources/kenneyUI.tres")
	if kenney_theme:
		count_label.theme = kenney_theme
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	count_label.text = str(in_deck) + "/" + str(owned)
	count_label.add_theme_font_size_override("font_size", 14)
	count_label.add_theme_color_override("font_color", Color.WHITE)
	count_label.position = Vector2.ZERO
	count_label.size = Vector2(CARD_SIZE.x, 22)
	count_label.z_index = 11
	count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# ── Store metadata on the card_rect directly ──
	card_rect.set_meta("card_id",         card_id)
	card_rect.set_meta("owned",           owned)
	card_rect.set_meta("in_deck",         in_deck)
	card_rect.set_meta("is_basic_energy", is_energy)
	card_rect.set_meta("card_rect",       card_rect)
	card_rect.set_meta("count_label",     count_label)

	# ── Visual styling based on ownership ──
	if owned == 0:
		card_rect.modulate     = Color(0.08, 0.08, 0.08, 1.0)
		card_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		card_rect.modulate     = Color.WHITE
		card_rect.mouse_filter = Control.MOUSE_FILTER_STOP
		card_rect.gui_input.connect(_on_card_gui_input.bind(card_rect))

		if in_deck > 0:
			_apply_selected_animation(card_rect)

	# ── Assemble and add to grid ──
	label_bg.add_child(count_label)
	card_rect.add_child(label_bg)
	grid.add_child(card_rect)


# ─── Card click handling ─────────────────────────────────────────────────────

## Handles mouse input on a card image.
## Left click  = add one copy to deck
## Right click = remove one copy from deck
func _on_card_gui_input(event: InputEvent, card_node: Control) -> void:
	if not event is InputEventMouseButton or not event.pressed:
		return

	var card_id   : String     = card_node.get_meta("card_id")
	var owned     : int        = card_node.get_meta("owned")
	var in_deck   : int        = card_node.get_meta("in_deck")
	var is_energy : bool       = card_node.get_meta("is_basic_energy")
	var card_rect : TextureRect = card_node.get_meta("card_rect")
	var label     : Label      = card_node.get_meta("count_label")

	# Determine the max copies allowed for this specific card
	var max_allowed : int
	if is_energy:
		# Basic energies: only limited by how many the player owns
		max_allowed = owned
	else:
		# Everything else (Pokémon, Trainers, Special Energy): 4-copy rule
		max_allowed = mini(owned, MAX_COPIES)

	if event.button_index == MOUSE_BUTTON_LEFT:
		# ── Add a copy ──
		if in_deck >= max_allowed:
			return     # already at limit for this card

		in_deck += 1
		total_deck_count += 1
		deck_cards[card_id] = in_deck
		card_node.set_meta("in_deck", in_deck)

		SoundManagerScript.play_sfx(SoundManagerScript.SFX_plus_select)

		# Start selection animation when the first copy is added
		if in_deck == 1:
			_apply_selected_animation(card_rect)

	elif event.button_index == MOUSE_BUTTON_RIGHT:
		# ── Remove a copy ──
		if in_deck <= 0:
			return     # nothing to remove

		in_deck -= 1
		total_deck_count -= 1

		if in_deck == 0:
			deck_cards.erase(card_id)
			# Stop animation when last copy is removed
			_remove_selected_animation(card_rect)
		else:
			deck_cards[card_id] = in_deck

		card_node.set_meta("in_deck", in_deck)
		SoundManagerScript.play_sfx(SoundManagerScript.SFX_minus_select)

	else:
		return   # ignore middle-click etc.

	# Update the label and global UI
	label.text = str(in_deck) + "/" + str(owned)
	_update_deck_count_label()
	_refresh_save_button()


# ─── Selection animation ────────────────────────────────────────────────────

## Starts a looping glow + scale animation on a card to show it is in the deck.
## Matches the style from cardimage.gd set_selected(true).
func _apply_selected_animation(card_rect: TextureRect) -> void:
	# Kill any existing tween on this card
	var old_tween = card_rect.get_meta("deck_tween", null)
	if old_tween:
		old_tween.kill()

	card_rect.pivot_offset = CARD_SIZE / 2.0
	card_rect.modulate     = Color.WHITE

	var tw := create_tween()
	tw.set_loops()
	card_rect.set_meta("deck_tween", tw)

	# Glow brighter + grow slightly, then return to normal — loops forever
	tw.tween_property(card_rect, "modulate", Color.WHITE * 1.4, 0.5)
	tw.parallel().tween_property(card_rect, "scale", Vector2(1.03, 1.03), 0.5)
	tw.tween_property(card_rect, "modulate", Color.WHITE * 1.0, 0.5)
	tw.parallel().tween_property(card_rect, "scale", Vector2(1.0, 1.0), 0.5)


## Stops the selection animation and resets the card to its normal state.
func _remove_selected_animation(card_rect: TextureRect) -> void:
	var tw = card_rect.get_meta("deck_tween", null)
	if tw:
		tw.kill()
		card_rect.set_meta("deck_tween", null)
	card_rect.modulate = Color.WHITE
	card_rect.scale    = Vector2(1.0, 1.0)


# ─── Set navigation ─────────────────────────────────────────────────────────

## Move to the next unlocked set (wraps around to the start).
func _on_next_set() -> void:
	if unlocked_indices.is_empty():
		return
	current_unlock_pos = (current_unlock_pos + 1) % unlocked_indices.size()
	_display_current_set()
	# Scroll back to top when switching sets
	_reset_scroll_position()


## Move to the previous unlocked set (wraps around to the end).
func _on_prev_set() -> void:
	if unlocked_indices.is_empty():
		return
	current_unlock_pos -= 1
	if current_unlock_pos < 0:
		current_unlock_pos = unlocked_indices.size() - 1
	_display_current_set()
	_reset_scroll_position()


## Scrolls the scroll container back to the top.
func _reset_scroll_position() -> void:
	var scroll = grid.get_parent()
	if scroll is ScrollContainer:
		scroll.scroll_vertical = 0


# ─── Empty deck ──────────────────────────────────────────────────────────────

## Clears the entire deck — resets all in-deck counts to 0.
func _on_empty_deck_pressed() -> void:
	deck_cards.clear()
	total_deck_count = 0
	deck_name_edit.text = ""
	_update_deck_count_label()
	_refresh_save_button()

	# Refresh every card in the current grid to remove animations and counts
	for card_rect in grid.get_children():
		var label     : Label       = card_rect.get_meta("count_label", null)
		var owned     : int         = card_rect.get_meta("owned", 0)

		if label == null:
			continue

		card_rect.set_meta("in_deck", 0)
		label.text = "0/" + str(owned)

		# Only remove animation from owned cards — unowned cards must stay dark
		if owned > 0:
			_remove_selected_animation(card_rect)
		# Unowned cards keep their darkened modulate untouched


# ─── Save ────────────────────────────────────────────────────────────────────

## Saves the current deck to a JSON file and updates player_data.json.
func _on_save_pressed() -> void:
	if total_deck_count != DECK_SIZE:
		return

	# Build the deck name from the text field
	var display_name := deck_name_edit.text.strip_edges()
	if display_name == "":
		return
	var file_name := display_name.replace(" ", "_")

	SoundManagerScript.play_sfx(SoundManagerScript.SFX_gamemode_select)

	# Build the deck array in the same format as existing deck files
	var deck_array : Array = []
	for card_id in deck_cards:
		deck_array.append({
			"id": card_id,
			"count": deck_cards[card_id]
		})

	# Sort by card ID for consistent file output
	deck_array.sort_custom(func(a, b): return a["id"] < b["id"])

	# Write the deck file
	var deck_path := PLAYER_DECKS_FOLDER + file_name + ".json"
	var deck_file := FileAccess.open(deck_path, FileAccess.WRITE)
	if deck_file == null:
		push_error("DeckBuild: cannot write " + deck_path)
		return
	deck_file.store_string(JSON.stringify(deck_array, "\t"))
	deck_file.close()

	# Update player_data.json with the new deck name and last set loaded
	_save_player_data(file_name)

	current_deck_name = file_name
	SoundManagerScript.play_sfx(SoundManagerScript.SFX_gamemode_select)

	# Disable save button after saving
	_refresh_save_button()


## Updates player_data.json — writes the active deck name and last set viewed.
func _save_player_data(deck_file_name: String) -> void:
	var file := FileAccess.open(PLAYER_DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("DeckBuild: cannot read " + PLAYER_DATA_PATH)
		return
	var data = JSON.parse_string(file.get_as_text())
	file.close()

	if not data is Dictionary:
		return

	data["deck"] = deck_file_name
	# Store the current set's ID so we return here next time
	var set_idx = unlocked_indices[current_unlock_pos]
	data["last_set_loaded"] = set_list[set_idx]["set_id"]

	var write_file := FileAccess.open(PLAYER_DATA_PATH, FileAccess.WRITE)
	if write_file == null:
		push_error("DeckBuild: cannot write " + PLAYER_DATA_PATH)
		return
	write_file.store_string(JSON.stringify(data, "\t"))
	write_file.close()


# ─── Cancel ──────────────────────────────────────────────────────────────────

## Saves the last set viewed to player_data and returns to the main menu.
func _on_cancel_pressed() -> void:
	_save_last_set_loaded()
	SoundManagerScript.stop_bgm()
	get_tree().change_scene_to_file("res://gdscenes/MainMenu.tscn")


## Writes only last_set_loaded to player_data.json without touching deck name.
func _save_last_set_loaded() -> void:
	var file := FileAccess.open(PLAYER_DATA_PATH, FileAccess.READ)
	if file == null:
		return
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	if not data is Dictionary:
		return

	var set_idx = unlocked_indices[current_unlock_pos]
	data["last_set_loaded"] = set_list[set_idx]["set_id"]

	var write_file := FileAccess.open(PLAYER_DATA_PATH, FileAccess.WRITE)
	if write_file == null:
		return
	write_file.store_string(JSON.stringify(data, "\t"))
	write_file.close()


# ─── Input handling (Escape + Spacebar zoom) ────────────────────────────────

## Handles global keyboard input for the deck build screen.
## - Escape: closes zoom if active, otherwise returns to main menu
## - Spacebar press: zooms into the hovered card's large image
## - Spacebar release: closes the zoom overlay and restores UI
func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return

	# ── Escape key ──
	if event.pressed and event.keycode == KEY_ESCAPE:
		# If zoomed in, close the zoom instead of leaving the scene
		if is_zoomed:
			_hide_zoom()
			return
		_on_cancel_pressed()

	# ── Spacebar hold-to-zoom ──
	if event.keycode == KEY_SPACE:
		if event.pressed and not event.is_echo():
			# Key just went down (not a held-key repeat) — try to zoom
			# Don't zoom if a popup is open or the deck name field has focus
			if load_popup != null:
				return
			if deck_name_edit.has_focus():
				return
			var card = _get_hovered_card()
			if card != null:
				_show_zoom(card)
		elif not event.pressed:
			# Key released — close zoom
			_hide_zoom()


# ─── Card zoom ──────────────────────────────────────────────────────────────

## Returns the card TextureRect under the mouse cursor, or null if none.
## Uses Godot's built-in gui_get_hovered_control() which returns whichever
## Control node the mouse is currently over. Because the mouse might land
## on a child node (the count label, its ColorRect background, etc.) rather
## than the card TextureRect itself, we walk up the node tree looking for
## a node that carries our "card_id" metadata — that's the actual card.
func _get_hovered_card() -> TextureRect:
	var hovered = get_viewport().gui_get_hovered_control()
	if hovered == null:
		return null
	# Walk up to 5 parents looking for our card_id metadata
	var node = hovered
	for i in range(5):
		if node == null:
			return null
		if node.has_meta("card_id"):
			return node as TextureRect
		node = node.get_parent()
	return null


## Shows a zoomed-in view of the given card.
## Creates a CanvasLayer overlay (layer 150, above everything including the
## load popup at layer 100) with a dimmed background and the large card image
## displayed at 600×825. Also hides all UI elements except the borders and
## background scroller so the card is the sole focus.
func _show_zoom(card_rect: TextureRect) -> void:
	if is_zoomed:
		return

	var card_id : String = card_rect.get_meta("card_id")
	var card_set := card_id.split("-")[0]
	# Build path to the LARGE version of the card image
	var large_path := "res://cardimages/" + card_set + "/Large/" + card_id + ".png"
	var large_texture = load(large_path)
	if large_texture == null:
		push_error("DeckBuild: missing large card image " + large_path)
		return

	is_zoomed = true

	# Hide all UI elements except backgrounds
	_set_ui_visibility(false)

	# Build the overlay — CanvasLayer renders above everything at layer 150
	zoom_overlay = CanvasLayer.new()
	zoom_overlay.layer = 150
	add_child(zoom_overlay)

	# Semi-transparent black backdrop
	var backdrop := ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.75)
	backdrop.anchor_right  = 1.0
	backdrop.anchor_bottom = 1.0
	zoom_overlay.add_child(backdrop)

	# The large card image, centered on screen
	var zoom_card := TextureRect.new()
	zoom_card.texture = large_texture
	zoom_card.custom_minimum_size = Vector2(600, 825)
	zoom_card.size                = Vector2(600, 825)
	zoom_card.expand_mode         = TextureRect.EXPAND_IGNORE_SIZE
	zoom_card.stretch_mode        = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# Center it: (1920 - 600) / 2 = 660,  (1080 - 825) / 2 ≈ 128
	zoom_card.position = Vector2(660, 128)
	zoom_overlay.add_child(zoom_card)


## Removes the zoom overlay and restores all UI elements.
func _hide_zoom() -> void:
	if not is_zoomed:
		return

	is_zoomed = false

	if zoom_overlay != null:
		zoom_overlay.queue_free()
		zoom_overlay = null

	# Restore UI visibility
	_set_ui_visibility(true)


## Hides or shows all UI elements except top_border, bottom_border,
## and background_scroller. When zooming, we want only the card visible
## against the background.
func _set_ui_visibility(visible_flag: bool) -> void:
	# The scroll container is the grid's parent (created in _wrap_grid_in_scroll_container)
	var scroll = grid.get_parent()
	var nodes_to_toggle := [
		scroll,
		save_btn,
		cancel_btn,
		empty_btn,
		load_btn,
		next_btn,
		prev_btn,
		set_label,
		deck_name_edit,
		deck_count_label,
	]
	for node in nodes_to_toggle:
		if node != null and is_instance_valid(node):
			node.visible = visible_flag


# ─── UI helpers ──────────────────────────────────────────────────────────────

## Updates the "XX/60" label in the top bar.
func _update_deck_count_label() -> void:
	deck_count_label.text = str(total_deck_count) + "/" + str(DECK_SIZE)


## Called every time the player types or deletes in the deck name field.
## text_changed passes the new text as an argument but we just need to
## re-evaluate whether the save button should be enabled or disabled.
func _on_deck_name_changed(_new_text: String) -> void:
	_refresh_save_button()


## Enables the save button only when the deck has exactly 60 cards
## and a deck name has been entered.
func _refresh_save_button() -> void:
	var name_ok := deck_name_edit.text.strip_edges() != ""
	if total_deck_count == DECK_SIZE and name_ok:
		save_btn.disabled = false
		var green_theme = load("res://uiresources/kenneyUI-green.tres")
		if green_theme:
			save_btn.theme = green_theme
	else:
		save_btn.disabled = true
		save_btn.theme = load("res://uiresources/kenneyUI.tres")


# ─── Load deck popup ────────────────────────────────────────────────────────

## Opens a popup showing all saved decks in the playerdecks folder.
## The player picks one from the list and clicks Load, or clicks Cancel.
func _on_load_deck_pressed() -> void:
	# Prevent opening multiple popups
	if load_popup != null:
		return

	# Read all .json files from the decks folder
	var deck_files : Array = []
	var dir := DirAccess.open(PLAYER_DECKS_FOLDER)
	if dir == null:
		push_error("DeckBuild: cannot open " + PLAYER_DECKS_FOLDER)
		return
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.ends_with(".json"):
			deck_files.append(fname.trim_suffix(".json"))
		fname = dir.get_next()
	dir.list_dir_end()
	deck_files.sort()

	if deck_files.is_empty():
		return

	# ── Build the popup UI ──
	# CanvasLayer ensures the popup renders above everything else.
	load_popup = CanvasLayer.new()
	load_popup.layer = 100
	add_child(load_popup)

	# Semi-transparent background overlay to dim the screen behind the popup
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.anchor_right  = 1.0
	overlay.anchor_bottom = 1.0
	load_popup.add_child(overlay)

	# Main panel — centered on screen
	var panel := PanelContainer.new()
	var kenney_theme = load("res://uiresources/kenneyUI.tres")
	if kenney_theme:
		panel.theme = kenney_theme
	panel.custom_minimum_size = Vector2(500, 600)
	panel.anchor_left   = 0.5
	panel.anchor_top    = 0.5
	panel.anchor_right  = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left   = -250
	panel.offset_top    = -300
	panel.offset_right  = 250
	panel.offset_bottom = 300
	load_popup.add_child(panel)

	# Vertical layout inside the panel
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	# Title
	var title_label := Label.new()
	title_label.text = "Load a Deck"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 28)
	vbox.add_child(title_label)

	# Scrollable list of decks
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(460, 420)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode   = ScrollContainer.SCROLL_MODE_AUTO
	vbox.add_child(scroll)

	var list_vbox := VBoxContainer.new()
	list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_vbox.add_theme_constant_override("separation", 5)
	scroll.add_child(list_vbox)

	# Track which deck is currently highlighted.
	# Using a Dictionary because GDScript lambdas capture objects by reference
	# but Strings by value — so a plain String variable updated in one lambda
	# would not be visible to another lambda. The Dictionary acts as a shared
	# mutable container that both lambdas can read and write.
	var selection := {"deck_name": "", "button": null}

	# Create a button for each deck file
	for deck_name in deck_files:
		var btn := Button.new()
		btn.text = deck_name.replace("_", " ")
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if kenney_theme:
			btn.theme = kenney_theme
		btn.custom_minimum_size = Vector2(440, 40)
		# When clicked, highlight this button and store the deck name
		btn.pressed.connect(
			func():
				# Un-highlight previous selection
				if selection["button"] != null and is_instance_valid(selection["button"]):
					selection["button"].theme = kenney_theme
				# Highlight new selection
				var blue_theme = load("res://uiresources/kenneyUI-blue.tres")
				if blue_theme:
					btn.theme = blue_theme
				selection["button"] = btn
				selection["deck_name"] = deck_name
		)
		list_vbox.add_child(btn)

	# Bottom row: Load + Cancel buttons
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_row)

	var load_confirm_btn := Button.new()
	load_confirm_btn.text = "Load"
	load_confirm_btn.custom_minimum_size = Vector2(120, 45)
	var green_theme = load("res://uiresources/kenneyUI-green.tres")
	if green_theme:
		load_confirm_btn.theme = green_theme
	load_confirm_btn.pressed.connect(
		func():
			if selection["deck_name"] != "":
				var chosen_name : String = selection["deck_name"]
				_close_load_popup()
				# Load the chosen deck
				current_deck_name = chosen_name
				deck_name_edit.text = chosen_name.replace("_", " ")
				_load_deck(chosen_name)
				_update_deck_count_label()
				_refresh_save_button()
				_display_current_set()
	)
	btn_row.add_child(load_confirm_btn)

	var cancel_popup_btn := Button.new()
	cancel_popup_btn.text = "Cancel"
	cancel_popup_btn.custom_minimum_size = Vector2(120, 45)
	var red_theme = load("res://uiresources/kenneyUI-red.tres")
	if red_theme:
		cancel_popup_btn.theme = red_theme
	cancel_popup_btn.pressed.connect(_close_load_popup)
	btn_row.add_child(cancel_popup_btn)


## Removes the load-deck popup from the scene tree.
func _close_load_popup() -> void:
	if load_popup != null:
		load_popup.queue_free()
		load_popup = null
