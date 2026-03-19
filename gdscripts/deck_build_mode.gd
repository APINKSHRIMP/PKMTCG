extends Control

# ─── Constants ───────────────────────────────────────────────────────────────

const PLAYER_DATA_PATH     := "C:/pkm-tcg-gdt/playerdata/player_data.json"
const SET_DICT_PATH        := "C:/pkm-tcg-gdt/playerdata/set_dictionary.json"
const OWNED_CARDS_FOLDER   := "C:/pkm-tcg-gdt/playerdata/playerownedcards/"
const PLAYER_DECKS_FOLDER  := "C:/pkm-tcg-gdt/playerdata/playerdecks/"

const PLAYER_PROGRESS_PATH := "C:/pkm-tcg-gdt/playerdata/player_progress.json"

const CARD_SIZE     := Vector2(183, 254)
const CARD_H_SEP    := 2
const CARD_V_SEP    := 2
const COLUMNS       := 9
const MAX_COPIES    := 4
const DECK_SIZE     := 60

# ─── Energy style data ──────────────────────────────────────────────────────
# Each style maps to 6 card IDs in a fixed order: grass, fire, water,
# lightning, psychic, fighting.  The order matters because each set has
# different numbering — we can't just loop through sequentially.

const ENERGY_TYPES := ["grass", "fire", "water", "lightning", "psychic", "fighting"]

const ENERGY_STYLES : Dictionary = {
	"Base1":  ["base1-99",  "base1-98",  "base1-102", "base1-100", "base1-101", "base1-97"],
	"Ecard1": ["ecard1-162","ecard1-161","ecard1-165","ecard1-163","ecard1-164","ecard1-160"],
	"ex1":    ["ex1-104",   "ex1-108",   "ex1-106",   "ex1-109",   "ex1-107",   "ex1-105"],
	"ex9":    ["ex9-101",   "ex9-102",   "ex9-103",   "ex9-104",   "ex9-105",   "ex9-106"],
	"ex13":   ["ex13-105",  "ex13-106",  "ex13-107",  "ex13-108",  "ex13-109",  "ex13-110"],
	"ex16":   ["ex16-103",  "ex16-104",  "ex16-105",  "ex16-106",  "ex16-107",  "ex16-108"],
}

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

# The player's current energy style key (e.g. "ex13")
var current_energy_style : String = "Base1"

# Whether the energy style picker overlay is currently visible
var energy_picker_active : bool = false

# Reference to the energy picker Control so we can free it
var energy_picker_overlay : Control = null

# Holds references to the 6 energy icon TextureRects from the scene tree,
# keyed by type name: "grass", "fire", "water", "lightning", "psychic", "fighting"
var energy_icons   : Dictionary = {}
# Matching count labels for each energy type
var energy_labels  : Dictionary = {}
# Tweens for the energy icon glow animation, keyed by type name
var energy_tweens  : Dictionary = {}

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

# Energy icon TextureRects in the scene — these show the current style's images
@onready var grass_energy_icon     : TextureRect = $grass_energy_icon
@onready var fire_energy_icon      : TextureRect = $fire_energy_icon
@onready var water_energy_icon     : TextureRect = $water_energy_icon
@onready var lightning_energy_icon : TextureRect = $lightning_energy_icon
@onready var psychic_energy_icon   : TextureRect = $psychic_energy_icon
@onready var fighting_energy_icon  : TextureRect = $fighting_energy_icon

# Count labels overlaid on top of each energy icon
@onready var grass_energy_count     : Label = $grass_energy_count_label
@onready var fire_energy_count      : Label = $fire_energy_count_label
@onready var water_energy_count     : Label = $water_energy_count_label
@onready var lightning_energy_count : Label = $lightning_energy_count_label
@onready var psychic_energy_count   : Label = $psychic_energy_count_label
@onready var fighting_energy_count  : Label = $figthing_energy_count_label

# The button that opens the energy style picker overlay
@onready var change_energy_btn : Button = $change_energy_style_button

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
	change_energy_btn.pressed.connect(_on_change_energy_style_pressed)

	# Limit deck name to 20 characters — LineEdit.max_length natively
	# blocks further typing once the limit is reached
	deck_name_edit.max_length = 25
	
	# Re-evaluate save button whenever the name is typed or cleared
	deck_name_edit.text_changed.connect(_on_deck_name_changed)

	# Wrap the grid in a scroll container so large sets can scroll
	_wrap_grid_in_scroll_container()

	# Load the player's current deck
	_load_deck(current_deck_name)

	# ── Energy icon setup ──
	# Build the convenience dictionaries that map type name → node.
	# This lets the rest of the code work with energy types by string
	# name ("grass", "fire", etc.) instead of individual variable names.
	energy_icons = {
		"grass": grass_energy_icon, "fire": fire_energy_icon,
		"water": water_energy_icon, "lightning": lightning_energy_icon,
		"psychic": psychic_energy_icon, "fighting": fighting_energy_icon,
	}
	energy_labels = {
		"grass": grass_energy_count, "fire": fire_energy_count,
		"water": water_energy_count, "lightning": lightning_energy_count,
		"psychic": psychic_energy_count, "fighting": fighting_energy_count,
	}

	# Load the saved energy style from player_data.json and update the icons
	_load_energy_style()
	_update_energy_icons()

	# Wire up click handling on each energy icon.  gui_input is the signal
	# Godot fires on any Control when the mouse interacts with it.
	# We set mouse_filter to STOP so the icon consumes the click rather
	# than letting it pass through to nodes behind it.
	for energy_type in ENERGY_TYPES:
		var icon : TextureRect = energy_icons[energy_type]
		icon.mouse_filter = Control.MOUSE_FILTER_STOP
		icon.gui_input.connect(_on_energy_icon_gui_input.bind(energy_type))

	# Refresh energy icon labels and animations from deck state
	_refresh_energy_icons_from_deck()

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


# ─── Energy style management ────────────────────────────────────────────────

## Reads the energy_style field from player_data.json and stores it.
## Falls back to "Base1" if the field is missing.
func _load_energy_style() -> void:
	var file := FileAccess.open(PLAYER_DATA_PATH, FileAccess.READ)
	if file == null:
		return
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	if data is Dictionary:
		current_energy_style = data.get("energy_style", "Base1")


## Updates the 6 energy icon TextureRects to show images from the
## currently selected energy style.  Each icon loads the "Small" version
## of its card image from the cardimages folder.
func _update_energy_icons() -> void:
	if not ENERGY_STYLES.has(current_energy_style):
		current_energy_style = "Base1"

	var card_ids : Array = ENERGY_STYLES[current_energy_style]
	# card_ids is ordered: grass, fire, water, lightning, psychic, fighting
	# ENERGY_TYPES is in the same order, so index i lines up
	for i in range(ENERGY_TYPES.size()):
		var energy_type : String = ENERGY_TYPES[i]
		var card_id     : String = card_ids[i]
		var card_set := card_id.split("-")[0]
		var image_path := "res://cardimages/" + card_set + "/Small/" + card_id + ".png"
		var tex = load(image_path)
		if tex != null:
			energy_icons[energy_type].texture = tex


## Refreshes the count labels and glow animations on all 6 energy icons
## based on the current deck contents.  Called at startup and whenever the
## deck changes (load, empty, etc.).
func _refresh_energy_icons_from_deck() -> void:
	if not ENERGY_STYLES.has(current_energy_style):
		return

	var card_ids : Array = ENERGY_STYLES[current_energy_style]
	for i in range(ENERGY_TYPES.size()):
		var energy_type : String = ENERGY_TYPES[i]
		var card_id     : String = card_ids[i]
		var in_deck     : int    = deck_cards.get(card_id, 0)
		var label       : Label  = energy_labels[energy_type]
		label.text = str(in_deck)

		var icon : TextureRect = energy_icons[energy_type]
		if in_deck > 0:
			_apply_energy_icon_animation(energy_type, icon)
		else:
			_remove_energy_icon_animation(energy_type, icon)


## Starts the glow + grow loop on an energy icon (same visual feel as
## the main grid cards).  The icon's pivot_offset must be set to its
## centre so it scales from the middle rather than the top-left corner.
func _apply_energy_icon_animation(energy_type: String, icon: TextureRect) -> void:
	# Kill any existing tween first to avoid stacking animations
	if energy_tweens.has(energy_type) and energy_tweens[energy_type] != null:
		energy_tweens[energy_type].kill()

	icon.pivot_offset = icon.size / 2.0
	icon.modulate = Color.WHITE

	var tw := create_tween()
	tw.set_loops()
	energy_tweens[energy_type] = tw

	tw.tween_property(icon, "modulate", Color.WHITE * 1.4, 0.5)
	tw.parallel().tween_property(icon, "scale", Vector2(1.06, 1.06), 0.5)
	tw.tween_property(icon, "modulate", Color.WHITE * 1.0, 0.5)
	tw.parallel().tween_property(icon, "scale", Vector2(1.0, 1.0), 0.5)


## Stops the glow animation and resets an energy icon to normal.
func _remove_energy_icon_animation(energy_type: String, icon: TextureRect) -> void:
	if energy_tweens.has(energy_type) and energy_tweens[energy_type] != null:
		energy_tweens[energy_type].kill()
		energy_tweens[energy_type] = null
	icon.modulate = Color.WHITE
	icon.scale = Vector2(1.0, 1.0)


## Handles left/right click on an energy icon.
## Left click  = add one of that energy to the deck
## Right click = remove one of that energy from the deck
## The card_id used comes from the current energy style, so switching
## styles later will use different set-specific IDs.
func _on_energy_icon_gui_input(event: InputEvent, energy_type: String) -> void:
	if not event is InputEventMouseButton or not event.pressed:
		return

	# Look up which card_id this energy type maps to in the current style
	var type_index := ENERGY_TYPES.find(energy_type)
	if type_index == -1:
		return
	var card_id : String = ENERGY_STYLES[current_energy_style][type_index]
	var in_deck : int    = deck_cards.get(card_id, 0)
	var icon    : TextureRect = energy_icons[energy_type]
	var label   : Label  = energy_labels[energy_type]

	if event.button_index == MOUSE_BUTTON_LEFT:
		# Energies have no copy cap — add freely
		in_deck += 1
		total_deck_count += 1
		deck_cards[card_id] = in_deck
		SoundManagerScript.play_sfx(SoundManagerScript.SFX_plus_select)

		if in_deck == 1:
			_apply_energy_icon_animation(energy_type, icon)

	elif event.button_index == MOUSE_BUTTON_RIGHT:
		if in_deck <= 0:
			return
		in_deck -= 1
		total_deck_count -= 1

		if in_deck == 0:
			deck_cards.erase(card_id)
			_remove_energy_icon_animation(energy_type, icon)
		else:
			deck_cards[card_id] = in_deck

		SoundManagerScript.play_sfx(SoundManagerScript.SFX_minus_select)
	else:
		return

	label.text = str(in_deck)
	_update_deck_count_label()
	_refresh_save_button()


# ─── Energy style picker overlay ────────────────────────────────────────────
# When the player clicks "Change Energy Style", we hide all normal UI and
# show a grid of 6 rows × 6 columns of energy cards.  Each row represents
# one set's energy style.  Clicking any card in a row selects that entire
# row (i.e. that style).  Save/Cancel buttons appear on the right.

## Called when the "Change Energy Style" button is pressed.
## Hides all normal deck-builder UI and shows the energy picker overlay.
func _on_change_energy_style_pressed() -> void:
	if energy_picker_active:
		return

	energy_picker_active = true
	_set_ui_visibility(false)

	# Build the overlay as a regular Control (NOT a CanvasLayer).
	# CanvasLayer creates a separate rendering layer that ignores the
	# normal scene tree's z_index entirely — meaning the top_and_right_border
	# could never render on top of it.  By using a plain Control with a
	# z_index between the background and the border, the energy cards
	# scroll behind the border naturally.
	energy_picker_overlay = Control.new()
	energy_picker_overlay.z_index = 10   # above background (-10), below border (50)
	energy_picker_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(energy_picker_overlay)

	# ── Semi-transparent backdrop ──
	var backdrop := ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.55)
	backdrop.anchor_right  = 1.0
	backdrop.anchor_bottom = 1.0
	backdrop.z_index = 55   # above the border so the dimming covers everything
	energy_picker_overlay.add_child(backdrop)

	# ── Title label ──
	var title := Label.new()
	var kenney_theme = load("res://uiresources/kenneyUI.tres")
	if kenney_theme:
		title.theme = kenney_theme
	title.text = "Select Energy Card Style"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(200, 20)
	title.size = Vector2(1200, 50)
	title.z_index = 55
	energy_picker_overlay.add_child(title)

	# Track which style is currently selected in the picker.
	# Using a Dictionary as a mutable container so lambdas can share it
	# (same pattern as the load deck popup).
	var picker_selection := {"style": current_energy_style}

	# ── Card size for the picker grid ──
	# 20% larger than the standard deck build card size (183×254)
	var picker_card_size := CARD_SIZE * 1.2   # → ~220 × 305

	# We'll store references to each row's card nodes so we can animate
	# the selected row.  Key = style name, value = array of TextureRects.
	var row_cards : Dictionary = {}
	# Also store tweens per style so we can kill them when selection changes
	var row_tweens : Dictionary = {}

	# Get the list of styles the player has unlocked from player_progress.json
	var available_styles := _get_unlocked_energy_styles()

	# ── Build a ScrollContainer + GridContainer for the card grid ──
	# ScrollContainer lets the player scroll vertically if there are more
	# rows than fit on screen.  The GridContainer inside handles the 6-column
	# layout automatically — we just add children and it wraps them.
	# Position and size match the available blank space on screen (1675×965)
	# starting from just below the title bar area.
	var picker_scroll := ScrollContainer.new()
	picker_scroll.position = Vector2(70, 140)
	picker_scroll.size = Vector2(1605, 905)
	picker_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	picker_scroll.vertical_scroll_mode   = ScrollContainer.SCROLL_MODE_AUTO
	picker_scroll.z_index = 0
	picker_scroll.clip_contents = true
	energy_picker_overlay.add_child(picker_scroll)

	var picker_grid := GridContainer.new()
	picker_grid.columns = 6
	picker_grid.add_theme_constant_override("h_separation", 28)
	picker_grid.add_theme_constant_override("v_separation", 14)
	picker_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Wrap the grid in a MarginContainer to add internal padding.
	# Without this, cards sit flush against the ScrollContainer's clip
	# boundary — so when the selected row's grow animation scales them
	# up ~5%, the left/top edges get clipped.  The margin gives breathing
	# room on all sides.
	var margin_container := MarginContainer.new()
	margin_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin_container.add_theme_constant_override("margin_left", 15)
	margin_container.add_theme_constant_override("margin_right", 15)
	margin_container.add_theme_constant_override("margin_top", 10)
	margin_container.add_theme_constant_override("margin_bottom", 10)
	picker_scroll.add_child(margin_container)
	margin_container.add_child(picker_grid)

	# Dimmed colour for non-selected but unlocked rows — 20% darker than white
	var dimmed_modulate := Color(0.8, 0.8, 0.8, 1.0)
	# Blacked-out colour for locked styles — matches the unowned card look
	var locked_modulate := Color(0.08, 0.08, 0.08, 1.0)

	for style_name in ENERGY_STYLES.keys():
		var is_unlocked : bool = style_name in available_styles
		var card_ids : Array = ENERGY_STYLES[style_name]

		# ── 6 energy cards for this row ──
		var cards_in_row : Array = []
		for col in range(6):
			var card_id : String = card_ids[col]
			var card_set := card_id.split("-")[0]
			var image_path := "res://cardimages/" + card_set + "/Large/" + card_id + ".png"
			var tex = load(image_path)

			var card_rect := TextureRect.new()
			if tex:
				card_rect.texture = tex
			card_rect.custom_minimum_size = picker_card_size
			card_rect.size = picker_card_size
			# EXPAND_IGNORE_SIZE tells the TextureRect to report
			# custom_minimum_size to the GridContainer for layout,
			# rather than the texture's full native pixel dimensions.
			# Without this the cards render at their original huge size.
			card_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			card_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			card_rect.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			card_rect.size_flags_vertical   = Control.SIZE_SHRINK_BEGIN
			card_rect.pivot_offset = picker_card_size / 2.0

			if not is_unlocked:
				# Locked style — black out the cards and ignore mouse input
				# so they can't be clicked, same visual as unowned cards
				card_rect.modulate = locked_modulate
				card_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			else:
				# Unlocked but not the current selection — dim slightly
				# so the selected row stands out.  The selected row's
				# modulate gets overridden to full white by the animation.
				card_rect.modulate = dimmed_modulate
				card_rect.mouse_filter = Control.MOUSE_FILTER_STOP
				card_rect.gui_input.connect(
					_on_picker_card_clicked.bind(style_name, picker_selection, row_cards, row_tweens)
				)

			picker_grid.add_child(card_rect)
			cards_in_row.append(card_rect)

		row_cards[style_name] = cards_in_row

	# Apply the glow animation to the currently selected style's row
	if row_cards.has(current_energy_style):
		_animate_picker_row(current_energy_style, row_cards, row_tweens)

	# ── Save and Cancel buttons on the right side ──
	# Position them in the same area as the normal save/cancel buttons.
	# z_index 55 keeps them above the border (50) so they're always visible.
	var picker_save_btn := Button.new()
	picker_save_btn.text = "save style"
	picker_save_btn.custom_minimum_size = Vector2(226, 63)
	picker_save_btn.position = Vector2(1689, 902)
	picker_save_btn.z_index = 55
	var green_theme = load("res://uiresources/kenneyUI-green.tres")
	if green_theme:
		picker_save_btn.theme = green_theme
	picker_save_btn.add_theme_font_size_override("font_size", 23)
	picker_save_btn.pressed.connect(
		func():
			_on_energy_picker_save(picker_selection["style"])
	)
	energy_picker_overlay.add_child(picker_save_btn)

	var picker_cancel_btn := Button.new()
	picker_cancel_btn.text = "cancel"
	picker_cancel_btn.custom_minimum_size = Vector2(224, 63)
	picker_cancel_btn.position = Vector2(1690, 986)
	picker_cancel_btn.z_index = 55
	var red_theme = load("res://uiresources/kenneyUI-red.tres")
	if red_theme:
		picker_cancel_btn.theme = red_theme
	picker_cancel_btn.add_theme_font_size_override("font_size", 23)
	picker_cancel_btn.pressed.connect(_on_energy_picker_cancel)
	energy_picker_overlay.add_child(picker_cancel_btn)


## Reads player_progress.json and returns the array of unlocked energy style
## names.  This determines which rows appear in the picker.
func _get_unlocked_energy_styles() -> Array:
	var file := FileAccess.open(PLAYER_PROGRESS_PATH, FileAccess.READ)
	if file == null:
		return ["Base1"]
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	if data is Dictionary and data.has("energy_styles"):
		return data["energy_styles"]
	return ["Base1"]


## Called when any card in the picker grid is clicked.
## Selects that row's style — removes animation from the old selection
## and applies it to the new one.
func _on_picker_card_clicked(event: InputEvent, style_name: String,
		picker_selection: Dictionary, row_cards: Dictionary,
		row_tweens: Dictionary) -> void:
	if not event is InputEventMouseButton or not event.pressed:
		return
	if event.button_index != MOUSE_BUTTON_LEFT:
		return

	var old_style : String = picker_selection["style"]

	# If clicking the already-selected style, do nothing
	if old_style == style_name:
		return

	SoundManagerScript.play_sfx(SoundManagerScript.SFX_plus_select)

	# Remove animation from old selection
	if row_cards.has(old_style):
		_stop_picker_row_animation(old_style, row_cards, row_tweens)

	# Apply animation to new selection
	picker_selection["style"] = style_name
	_animate_picker_row(style_name, row_cards, row_tweens)


## Starts the glow + grow loop on all 6 cards in a picker row.
## Each card gets its own tween so they all pulse together.
func _animate_picker_row(style_name: String, row_cards: Dictionary,
		row_tweens: Dictionary) -> void:
	# Kill any existing tweens for this row first
	_stop_picker_row_animation(style_name, row_cards, row_tweens)

	var tweens_for_row : Array = []
	for card_rect in row_cards[style_name]:
		var tw := create_tween()
		tw.set_loops()
		tw.tween_property(card_rect, "modulate", Color.WHITE * 1.4, 0.5)
		tw.parallel().tween_property(card_rect, "scale", Vector2(1.05, 1.05), 0.5)
		tw.tween_property(card_rect, "modulate", Color.WHITE * 1.0, 0.5)
		tw.parallel().tween_property(card_rect, "scale", Vector2(1.0, 1.0), 0.5)
		tweens_for_row.append(tw)
	row_tweens[style_name] = tweens_for_row


## Stops all glow/grow animations on a picker row and resets the cards
## to the dimmed state (20% darker) so the selected row stands out.
func _stop_picker_row_animation(style_name: String, row_cards: Dictionary,
		row_tweens: Dictionary) -> void:
	if row_tweens.has(style_name) and row_tweens[style_name] != null:
		for tw in row_tweens[style_name]:
			if tw != null:
				tw.kill()
		row_tweens[style_name] = null

	if row_cards.has(style_name):
		for card_rect in row_cards[style_name]:
			card_rect.modulate = Color(0.8, 0.8, 0.8, 1.0)
			card_rect.scale = Vector2(1.0, 1.0)


## Called when the picker's "save style" button is pressed.
## Saves the newly selected style to player_data.json, then swaps any
## energy cards already in the deck from the old style to the new style,
## updates the icons, and closes the picker.
func _on_energy_picker_save(new_style: String) -> void:
	var old_style := current_energy_style

	# ── Swap energy cards in the deck from old style → new style ──
	# If the player had e.g. 10 × base1-99 (Base1 grass) in their deck,
	# and they switch to ex13, we need to replace those with ex13-105.
	if old_style != new_style and ENERGY_STYLES.has(old_style) and ENERGY_STYLES.has(new_style):
		var old_ids : Array = ENERGY_STYLES[old_style]
		var new_ids : Array = ENERGY_STYLES[new_style]
		for i in range(6):
			var old_id : String = old_ids[i]
			var new_id : String = new_ids[i]
			if deck_cards.has(old_id):
				var count : int = deck_cards[old_id]
				deck_cards.erase(old_id)
				deck_cards[new_id] = count

	current_energy_style = new_style

	# Save to player_data.json
	_save_energy_style_to_player_data(new_style)

	SoundManagerScript.play_sfx(SoundManagerScript.SFX_gamemode_select)

	# Close picker and return to normal view
	_close_energy_picker()

	# Update the energy icons to show the new style's images
	_update_energy_icons()
	_refresh_energy_icons_from_deck()


## Called when the picker's "cancel" button is pressed.
## Closes the picker without saving — the original style is preserved.
func _on_energy_picker_cancel() -> void:
	_close_energy_picker()


## Removes the energy picker overlay and restores all normal UI.
func _close_energy_picker() -> void:
	energy_picker_active = false

	if energy_picker_overlay != null:
		energy_picker_overlay.queue_free()
		energy_picker_overlay = null

	_set_ui_visibility(true)


## Writes the energy_style field to player_data.json without touching
## any other fields.
func _save_energy_style_to_player_data(style_name: String) -> void:
	var file := FileAccess.open(PLAYER_DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("DeckBuild: cannot read " + PLAYER_DATA_PATH)
		return
	var data = JSON.parse_string(file.get_as_text())
	file.close()

	if not data is Dictionary:
		return

	data["energy_style"] = style_name

	var write_file := FileAccess.open(PLAYER_DATA_PATH, FileAccess.WRITE)
	if write_file == null:
		push_error("DeckBuild: cannot write " + PLAYER_DATA_PATH)
		return
	write_file.store_string(JSON.stringify(data, "\t"))
	write_file.close()


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

		# Skip basic energy cards — these are managed via the energy icons
		# on the right side of the screen, not the main card grid
		if card_data.get("is_basic_energy", false):
			continue

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

	# Also reset the energy icon labels and animations
	_refresh_energy_icons_from_deck()


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
		# If the energy picker is open, close it (same as pressing cancel)
		if energy_picker_active:
			_on_energy_picker_cancel()
			return
		_on_cancel_pressed()

	# ── Spacebar hold-to-zoom ──
	if event.keycode == KEY_SPACE:
		if event.pressed and not event.is_echo():
			# Key just went down (not a held-key repeat) — try to zoom
			# Don't zoom if a popup or picker is open, or the deck name field has focus
			if load_popup != null:
				return
			if energy_picker_active:
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
		change_energy_btn,
	]

	# Add all 6 energy icons and their count labels to the toggle list
	for energy_type in ENERGY_TYPES:
		nodes_to_toggle.append(energy_icons[energy_type])
		nodes_to_toggle.append(energy_labels[energy_type])

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
				_refresh_energy_icons_from_deck()
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
