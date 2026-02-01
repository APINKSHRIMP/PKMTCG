extends TextureRect

# Create a custom signal that will be emitted when this card is clicked to set this card as the "selected" card
signal card_clicked(card_uid: String)

# Declare the card ID as a variable
var card_uid

# Function to load the card image based on the UID (e.g Base1-1)
func load_card_image(card_uid: String, card_target_size):
	
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
		
		# Set stretch mode to scale proportionally
		self.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		self.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		
	else:
		print("Error: Could not load card image at path: ", card_image_path)

# This function script is used to determine when a card is clicked		
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		# Check if the click is actually on this card
		if get_global_rect().has_point(event.position):
			card_clicked.emit(card_uid)
		
# On card load...
func _ready() -> void:

	# Allow mouse input to pass through to this TextureRect
	mouse_filter = MOUSE_FILTER_PASS
