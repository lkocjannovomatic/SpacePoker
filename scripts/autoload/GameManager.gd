extends Node

# GameManager.gd - Global Autoload Singleton
# Manages game state, NPC data persistence, and scene transitions

# Signals for UI state management
signal processing_started
signal processing_finished
signal npc_data_changed

# Current game state
var current_npc_index: int = -1  # Index of NPC being played against
var player_stats: Dictionary = {
	"total_wins": 0,
	"total_losses": 0
}

# Start Screen Constants
const MAX_NPC_SLOTS = 8
const SAVE_DIR = "saves/"

# NPC Data Structure
var npc_slots: Array = []

# NPC Generator reference
var _npc_generator: Node = null

func _ready():
	print("GameManager: Initializing...")
	_setup_npc_generator()
	_initialize_npc_slots()
	_load_all_data()

func _setup_npc_generator():
	_npc_generator = Node.new()
	_npc_generator.set_script(load("res://scripts/start_screen/NPCGenerator.gd"))
	add_child(_npc_generator)
	
	_npc_generator.generation_completed.connect(_on_npc_generation_completed)
	_npc_generator.generation_failed.connect(_on_npc_generation_failed)

func _initialize_npc_slots():
	npc_slots.clear()
	for i in range(MAX_NPC_SLOTS):
		npc_slots.append(_npc_generator.empty_npc())

func _load_all_data():
	print("GameManager: Loading data from saves...")
	
	# Load each NPC slot
	for i in range(MAX_NPC_SLOTS):
		var file_path = "res://" + SAVE_DIR + "slot_" + str(i) + ".json"
		var data = _load_json_file(file_path)
		
		if data != null:
			npc_slots[i] = data
		else:
			# If file doesn't exist, keep the empty slot (no file creation)
			print("GameManager: Slot ", i, " is empty (no save file)")
	
	# Load player stats
	var stats_path = "res://" + SAVE_DIR + "player_stats.json"
	var stats_data = _load_json_file(stats_path)
	
	if stats_data != null:
		player_stats = stats_data
	else:
		# If file doesn't exist, use default stats (no file creation yet)
		print("GameManager: Using default player stats (no save file)")
	
	npc_data_changed.emit()
	print("GameManager: Data loaded successfully")

func _load_json_file(file_path: String) -> Variant:
	if not FileAccess.file_exists(file_path):
		return null
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		print("GameManager Error: Could not open file: ", file_path)
		return null
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("GameManager Error: JSON parse error in ", file_path, " at line ", json.get_error_line(), ": ", json.get_error_message())
		return null
	
	return json.data

func save_npc_slot(slot_index: int):
	if slot_index < 0 or slot_index >= MAX_NPC_SLOTS:
		print("GameManager Error: Invalid slot index: ", slot_index)
		return
	
	var file_path = "res://" + SAVE_DIR + "slot_" + str(slot_index) + ".json"
	_save_json_file(file_path, npc_slots[slot_index])

func save_player_stats():
	var stats_path = "res://" + SAVE_DIR + "player_stats.json"
	_save_json_file(stats_path, player_stats)

func _save_json_file(file_path: String, data: Variant):
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		print("GameManager Error: Could not open file for writing: ", file_path)
		return
	
	var json_string = ""
	
	# For NPC data, manually construct JSON with proper field order
	if data is Dictionary and data.has("name"):
		json_string = "{\n"
		json_string += '\t"name": ' + JSON.stringify(data.get("name", "")) + ",\n"
		json_string += '\t"backstory": ' + JSON.stringify(data.get("backstory", "")) + ",\n"
		json_string += '\t"aggression": ' + str(data.get("aggression", 0.5)) + ",\n"
		json_string += '\t"bluffing": ' + str(data.get("bluffing", 0.5)) + ",\n"
		json_string += '\t"risk_aversion": ' + str(data.get("risk_aversion", 0.5)) + ",\n"
		json_string += '\t"wins_against": ' + str(data.get("wins_against", 0)) + ",\n"
		json_string += '\t"losses_against": ' + str(data.get("losses_against", 0)) + ",\n"
		json_string += '\t"conversation_history": ' + JSON.stringify(data.get("conversation_history", "")) + "\n"
		json_string += "}"
	else:
		# For other data (like player stats), use standard JSON
		json_string = JSON.stringify(data, "\t")
	
	file.store_string(json_string)
	file.close()
	print("GameManager: Saved data to ", file_path)

func is_slot_empty(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= MAX_NPC_SLOTS:
		return true
	
	return npc_slots[slot_index]["name"] == ""

func get_npc_data(slot_index: int) -> Dictionary:
	if slot_index < 0 or slot_index >= MAX_NPC_SLOTS:
		return {}
	
	return npc_slots[slot_index]

func generate_npc(slot_index: int):
	# Defensive check: prevent generation on occupied slot
	if not is_slot_empty(slot_index):
		print("GameManager Warning: Attempted to generate NPC in occupied slot ", slot_index)
		return
	
	print("GameManager: Starting NPC generation for slot ", slot_index)
	processing_started.emit()
	
	current_npc_index = slot_index
	_npc_generator.generate_npc(slot_index)

func _on_npc_generation_completed(slot_index: int, npc_data: Dictionary):
	print("GameManager: NPC generation completed for slot ", slot_index)
	
	# Store the generated NPC data
	npc_slots[slot_index] = npc_data
	save_npc_slot(slot_index)
	
	# Reset tracking
	current_npc_index = -1
	
	# Notify UI
	processing_finished.emit()
	npc_data_changed.emit()

func _on_npc_generation_failed(error_message: String):
	print("GameManager: NPC generation failed - ", error_message)
	
	# Reset tracking
	current_npc_index = -1
	
	# Notify UI
	processing_finished.emit()

func delete_npc(slot_index: int):
	if slot_index < 0 or slot_index >= MAX_NPC_SLOTS:
		print("GameManager Error: Invalid slot index for deletion: ", slot_index)
		return
	
	if is_slot_empty(slot_index):
		print("GameManager Warning: Attempted to delete already empty slot ", slot_index)
		return
	
	print("GameManager: Deleting NPC in slot ", slot_index)
	npc_slots[slot_index] = _npc_generator.empty_npc()
	_delete_save_file(slot_index)
	
	npc_data_changed.emit()

func _delete_save_file(slot_index: int):
	var file_path = "res://" + SAVE_DIR + "slot_" + str(slot_index) + ".json"
	
	if FileAccess.file_exists(file_path):
		var dir = DirAccess.open("res://" + SAVE_DIR)
		if dir:
			var result = dir.remove("slot_" + str(slot_index) + ".json")
			if result == OK:
				print("GameManager: Deleted save file for slot ", slot_index)
			else:
				print("GameManager Error: Failed to delete save file for slot ", slot_index, ". Error: ", result)
		else:
			print("GameManager Error: Could not open saves directory for file deletion")
	else:
		print("GameManager: No save file to delete for slot ", slot_index)

func start_match(slot_index: int):
	if is_slot_empty(slot_index):
		print("GameManager Error: Cannot start match with empty slot ", slot_index)
		return
	
	current_npc_index = slot_index
	print("GameManager: Starting match against ", npc_slots[slot_index]["name"])
	
	change_scene("res://scenes/GameView.tscn")

func record_match_result(player_won: bool):
	"""Record the result of a completed match."""
	if current_npc_index < 0:
		print("GameManager Error: No active match to record")
		return
	
	if player_won:
		player_stats["total_wins"] += 1
		npc_slots[current_npc_index]["losses_against"] += 1
	else:
		player_stats["total_losses"] += 1
		npc_slots[current_npc_index]["wins_against"] += 1
	
	save_player_stats()
	save_npc_slot(current_npc_index)
	npc_data_changed.emit()
	
	print("GameManager: Match result recorded")

func change_scene(scene_path: String):
	"""Change to a different scene."""
	print("GameManager: Changing scene to ", scene_path)
	get_tree().change_scene_to_file(scene_path)

func return_to_start_screen():
	"""Return to the start screen."""
	current_npc_index = -1
	change_scene("res://scenes/StartScreen.tscn")