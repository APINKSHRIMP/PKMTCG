extends TextureRect

# Create a custom signal that will be emitted when this card is clicked to set this card as the "selected" card
signal card_clicked(clicked_card: card_object)

# Declare the card ID as a variable
var card_uid
var card_ref: card_object

# Animation and selection variables
var tween: Tween
var is_selected: bool = false
var original_modulate: Color

# Function to load the card image based on the UID (e.g Base1-1)
func load_card_image(card_uid: String, card_target_size, card_object_ref: card_object = null):	
	# Store reference to the card object so we can emit it when clicked
	self.card_ref = card_object_ref
	
	# Store the card UID so we can access it later when clicked
	self.card_uid = card_uid
	
	# Check the card_uid to make sure it's valid and if not error out 
	var split_uid = card_uid.split("-")
	if split_uid.size() != 2:
		print("Invalid UID provided, card_uid:", card_uid)
		return
	
	# Card details will be for example "Base1-1" "EX2-2"
	var card_set = split_uid[0]
	
	# Set the image to a null card in case there's any errors
	var card_image_path="res://cardimages/null.png"
	
	# Now find the image based on the card card_uid and size
	# If the image is only being displayed small then no point wasting resources loading large card images and shrinking them down.
	if card_target_size.x < 250 or card_target_size.y < 350:
		card_image_path="res://cardimages/"+card_set+"/Small/"+card_uid+".png"
	else:
		card_image_path="res://cardimages/"+card_set+"/Large/"+card_uid+".png"	
	
	# Now find the image from the path provided
	var card_texture = load(card_image_path)
	
	# check that the file could be found and if so load the image
	if card_texture != null:
		
		# We want to resize the image to always be the correct dimensions
		# Therefore we start by gettting the original image dimensions
		var original_card_dimension_width = card_texture.get_width()
		var original_card_dimension_height = card_texture.get_height()
		
		# Calculate scale factor (use the smaller ratio to maintain aspect ratio)
		var scale_x = float(card_target_size.x) / float(original_card_dimension_width)
		var scale_y = float(card_target_size.y) / float(original_card_dimension_height)
		var scale_factor = min(scale_x, scale_y)
		
		# Calculate final size maintaining aspect ratio
		var final_width = int(original_card_dimension_width * scale_factor)
		var final_height = int(original_card_dimension_height * scale_factor)
		
		# Set the texture
		self.texture = card_texture
		
		# Set size
		self.custom_minimum_size = Vector2(final_width, final_height)
		
		# NEW: Set pivot point to center so scaling happens from center
		self.pivot_offset = Vector2(final_width / 2, final_height / 2)
		
		# Set stretch mode to scale proportionally
		self.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		
		# Set stretch mode to scale proportionally
		self.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		self.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		
	else:
		print("Error: Could not load card image at path: ", card_image_path)

# Apply animation and colour effects to show selected card
# Apply visual effect when card is selected
func set_selected(selected: bool) -> void:
	is_selected = selected
	
	if selected:
		# Kill any existing tween to prevent conflicts
		if tween:
			tween.kill()
		
		# Store original color BEFORE starting animation if not already stored
		if original_modulate == Color(0, 0, 0, 0):
			original_modulate = Color.WHITE
		
		# Create new tween for smooth animation
		tween = create_tween()
		tween.set_loops()  # Loop the animation
		
		# Glow and scale happen simultaneously
		tween.tween_property(self, "modulate", Color.WHITE * 1.4, 0.5)
		tween.parallel().tween_property(self, "scale", Vector2(1.03, 1.03), 0.5)
		
		# Return to normal - glow and scale happen simultaneously
		tween.tween_property(self, "modulate", Color.WHITE * 1.0, 0.5)
		tween.parallel().tween_property(self, "scale", Vector2(1.0, 1.0), 0.5)
		
	else:
		# Kill the tween animation
		if tween:
			tween.kill()
			tween = null
		
		# Restore original appearance immediately
		modulate = Color.WHITE
		scale = Vector2(1.0, 1.0)
		
# This function script is used to determine when a card is clicked			
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		# Check if the click is actually on this card
		if get_global_rect().has_point(event.position):
			
			# NEW: Check if this card's parent container is visible
			var parent_container = get_parent()
			if parent_container and not parent_container.visible:
				return  # Don't process if parent container is hidden
			
			card_clicked.emit(card_ref)
			
			# Tell main script a card was clicked
			get_tree().root.get_child(0).card_was_clicked_this_frame = true
			
			# CRITICAL: Get reference to the main script to check if we're in selection mode
			var main_script = get_tree().root.get_child(0)
			
			# If in selection mode, consume the input so it doesn't propagate to other cards
			if main_script.card_selection_mode_enabled:
				get_tree().get_root().set_input_as_handled()		

# On card load...
func _ready() -> void:
	# Allow mouse input to pass through to this TextureRect
	mouse_filter = MOUSE_FILTER_PASS
