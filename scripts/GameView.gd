extends Control

# GameView.gd - Placeholder for the main poker game view

@onready var return_button = $VBoxContainer/ReturnButton
@onready var npc_label = $VBoxContainer/NPCLabel

func _ready():
	return_button.pressed.connect(_on_return_pressed)
	
	# Display which NPC we're playing against
	if GameManager.current_npc_index >= 0:
		var npc_data = GameManager.get_npc_data(GameManager.current_npc_index)
		npc_label.text = "Playing against: " + npc_data.get("name", "Unknown")
	else:
		npc_label.text = "No opponent selected"

func _on_return_pressed():
	GameManager.return_to_start_screen()
