extends TextureRect
class_name Card

# Card properties
var suit: String = ""
var rank: String = ""
var is_face_up: bool = false
var is_animating: bool = false

# Card texture paths
var card_back_path: String = "res://assets/cards/card_back.png"
var card_textures: Dictionary = {}

func _ready():
	# Set initial size
	custom_minimum_size = Vector2(80, 120)
	expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# Initialize with back texture
	texture = load(card_back_path)
	
	# Build texture dictionary
	_build_texture_dictionary()

func _build_texture_dictionary():
	var suits = ["clubs", "diamonds", "hearts", "spades"]
	var ranks = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"]
	
	for s in suits:
		for r in ranks:
			var key = s + "_" + r
			var path = "res://assets/cards/card_%s_%s.png" % [s, r]
			card_textures[key] = path

func set_card(new_suit: String, new_rank: String):
	suit = new_suit
	rank = new_rank
	if is_face_up:
		_update_texture()

func show_face():
	if not is_animating and not is_face_up:
		flip_to_face(true)

func show_back():
	if not is_animating and is_face_up:
		flip_to_face(false)

func flip_to_face(face_up: bool):
	if is_animating:
		return
	
	is_animating = true
	var tween = create_tween()
	
	# Scale down to 0 on X axis
	tween.tween_property(self, "scale:x", 0.0, 0.15)
	
	# Change texture at midpoint
	tween.tween_callback(func():
		is_face_up = face_up
		_update_texture()
	)
	
	# Scale back up
	tween.tween_property(self, "scale:x", 1.0, 0.15)
	
	# Mark animation complete
	tween.tween_callback(func():
		is_animating = false
	)

func _update_texture():
	if is_face_up and suit != "" and rank != "":
		var key = suit + "_" + rank
		if key in card_textures:
			texture = load(card_textures[key])
		else:
			print("Warning: Card texture not found for ", key)
			texture = load(card_back_path)
	else:
		texture = load(card_back_path)
