extends Control

# StatisticsScreen.gd - Display player statistics and per-NPC records

@onready var return_button = $MarginContainer/PanelContainer/VBoxContainer/ButtonContainer/ReturnButton
@onready var stats_container = $MarginContainer/PanelContainer/VBoxContainer/ScrollContainer/MarginContainer/StatsVBoxContainer/PerNPCStats
@onready var global_stats_label = $MarginContainer/PanelContainer/VBoxContainer/ScrollContainer/MarginContainer/StatsVBoxContainer/GlobalStatsLabel

func _ready():
	return_button.pressed.connect(_on_return_pressed)
	_display_statistics()

func _display_statistics():
	# Display global stats
	var total_wins = GameManager.player_stats.get("total_wins", 0)
	var total_losses = GameManager.player_stats.get("total_losses", 0)
	var total_games = total_wins + total_losses
	var win_percentage = 0.0
	
	if total_games > 0:
		win_percentage = (float(total_wins) / float(total_games)) * 100.0
	
	global_stats_label.text = "Overall Record:\n"
	global_stats_label.text += "Wins: %d | Losses: %d | Win Rate: %.1f%%" % [total_wins, total_losses, win_percentage]
	
	# Display per-NPC stats
	for i in range(GameManager.MAX_NPC_SLOTS):
		var npc_data = GameManager.get_npc_data(i)
		
		if not GameManager.is_slot_empty(i):
			var npc_name = npc_data.get("name", "Unknown")
			var wins = npc_data.get("wins_against", 0)
			var losses = npc_data.get("losses_against", 0)
			var npc_games = wins + losses
			var npc_win_percentage = 0.0
			
			if npc_games > 0:
				npc_win_percentage = (float(wins) / float(npc_games)) * 100.0
			
			var npc_stats_label = Label.new()
			npc_stats_label.text = "\nVs %s:\nWins: %d | Losses: %d | Win Rate: %.1f%%" % [npc_name, wins, losses, npc_win_percentage]
			stats_container.add_child(npc_stats_label)

func _on_return_pressed():
	GameManager.return_to_start_screen()
