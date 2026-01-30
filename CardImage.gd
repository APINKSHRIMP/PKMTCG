extends TextureRect

# Declare the card ID as a variable
var card_uid
var target_width = 0
var target_height = 0

# Function to load the card image based on the UID (e.g Base1-1)
func load_card_image(card_uid: String, target_width: int = 100, target_height: int = 138):
	
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
	if target_width < 250 or target_height < 350:
		card_image_path="res://cardimages/"+card_set+"/Small/"+card_uid+".png"
	else:
		card_image_path="res://cardimages/"+card_set+"/Large/"+card_uid+".png"	
	
	#print("Card Image is: ", card_image_path)
	# Now find the image from the path provided
	var card_texture = load(card_image_path)
	
	# check that the file could be found and if so load the image
	if card_texture != null:
		
		# We want to resize the image to always be the correct dimensions
		# Therefore we start by gettting the original image dimensions
		var original_card_dimension_width = card_texture.get_width()
		var original_card_dimension_height = card_texture.get_height()
		
		# Calculate scale factor (use the smaller ratio to maintain aspect ratio)
		var scale_x = float(target_width) / float(original_card_dimension_width)
		var scale_y = float(target_height) / float(original_card_dimension_height)
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
		
		#print("Card loaded: ", card_uid, " | Original: ", original_card_dimension_width, "x", original_card_dimension_height, 
		#	  " | Scaled to: ", final_width, "x", final_height)
	else:
		print("Error: Could not load card image at path: ", card_image_path)
