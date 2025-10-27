extends Node

# AudioManager.gd - Autoload singleton for managing game audio
# Handles UI sounds, game event sounds, and background music

# Audio stream players
var ui_player: AudioStreamPlayer = null
var game_player: AudioStreamPlayer = null
var music_player: AudioStreamPlayer = null

# Preloaded audio streams
var sfx_button_click: AudioStream = null
var sfx_button_hover: AudioStream = null
var sfx_card_deal: AudioStream = null
var sfx_card_flip: AudioStream = null
var sfx_chips_bet: AudioStream = null
var sfx_chips_collect: AudioStream = null
var sfx_fold: AudioStream = null
var sfx_turn_notify: AudioStream = null
var sfx_winner: AudioStream = null
var sfx_npc_generate: AudioStream = null
var sfx_npc_delete: AudioStream = null

func _ready():
	print("AudioManager: Initializing...")
	
	# Create audio stream players
	ui_player = AudioStreamPlayer.new()
	ui_player.bus = "SFX"
	add_child(ui_player)
	
	game_player = AudioStreamPlayer.new()
	game_player.bus = "SFX"
	add_child(game_player)
	
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	music_player.volume_db = -10.0  # Background music quieter
	add_child(music_player)
	
	# Load audio streams
	_load_audio_assets()
	
	print("AudioManager: Ready")

func _load_audio_assets():
	"""Load all audio streams from assets folder."""
	sfx_button_click = load("res://assets/audio/sfx/sfx_button_click.wav")
	sfx_button_hover = load("res://assets/audio/sfx/sfx_button_hover.wav")
	sfx_card_deal = load("res://assets/audio/sfx/sfx_card_deal.wav")
	sfx_card_flip = load("res://assets/audio/sfx/sfx_card_flip.wav")
	sfx_chips_bet = load("res://assets/audio/sfx/sfx_chips_bet.wav")
	sfx_chips_collect = load("res://assets/audio/sfx/sfx_chips_collect.wav")
	sfx_fold = load("res://assets/audio/sfx/sfx_fold.wav")
	sfx_turn_notify = load("res://assets/audio/sfx/sfx_turn_notify.wav")
	sfx_winner = load("res://assets/audio/sfx/sfx_winner.wav")
	sfx_npc_generate = load("res://assets/audio/sfx/sfx_npc_generate.wav")
	sfx_npc_delete = load("res://assets/audio/sfx/sfx_npc_delete.wav")
	
	print("AudioManager: Audio assets loaded")

# ============================================================================
# UI SOUNDS
# ============================================================================

func play_button_click():
	"""Play button click sound."""
	if sfx_button_click and ui_player:
		ui_player.stream = sfx_button_click
		ui_player.play()

func play_button_hover():
	"""Play button hover sound."""
	if sfx_button_hover and ui_player:
		ui_player.stream = sfx_button_hover
		ui_player.play()

func play_npc_generate():
	"""Play NPC generation complete sound."""
	if sfx_npc_generate and ui_player:
		ui_player.stream = sfx_npc_generate
		ui_player.play()

func play_npc_delete():
	"""Play NPC deletion sound."""
	if sfx_npc_delete and ui_player:
		ui_player.stream = sfx_npc_delete
		ui_player.play()

# ============================================================================
# GAME SOUNDS
# ============================================================================

func play_card_deal():
	"""Play card dealing sound."""
	if sfx_card_deal and game_player:
		game_player.stream = sfx_card_deal
		game_player.play()

func play_card_flip():
	"""Play card flip/reveal sound."""
	if sfx_card_flip and game_player:
		game_player.stream = sfx_card_flip
		game_player.play()

func play_chips_bet():
	"""Play chips/bet placed sound."""
	if sfx_chips_bet and game_player:
		game_player.stream = sfx_chips_bet
		game_player.play()

func play_chips_collect():
	"""Play pot collection/win sound."""
	if sfx_chips_collect and game_player:
		game_player.stream = sfx_chips_collect
		game_player.play()

func play_fold():
	"""Play fold action sound."""
	if sfx_fold and game_player:
		game_player.stream = sfx_fold
		game_player.play()

func play_turn_notify():
	"""Play turn notification sound."""
	if sfx_turn_notify and game_player:
		game_player.stream = sfx_turn_notify
		game_player.play()

func play_winner():
	"""Play winner announcement sound."""
	if sfx_winner and game_player:
		game_player.stream = sfx_winner
		game_player.play()

# ============================================================================
# BACKGROUND MUSIC
# ============================================================================

func play_background_music():
	"""Start background music loop."""
	# Load music if exists
	if FileAccess.file_exists("res://assets/audio/music/music_ambient_casino.ogg"):
		var music = load("res://assets/audio/music/music_ambient_casino.ogg")
		if music and music_player:
			music_player.stream = music
			music_player.play()
			print("AudioManager: Background music started")
	else:
		print("AudioManager: Background music file not found")

func stop_background_music():
	"""Stop background music."""
	if music_player:
		music_player.stop()
