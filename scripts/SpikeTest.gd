extends Control

# SpikeTest.gd - Test script for the LLM prototype
# This script provides a minimal UI to test the LLMClient functionality

@onready var input_line_edit: LineEdit = $VBoxContainer/InputContainer/InputLineEdit
@onready var send_button: Button = $VBoxContainer/InputContainer/SendButton
@onready var output_text_label: RichTextLabel = $VBoxContainer/OutputScrollContainer/OutputTextLabel
@onready var status_label: Label = $VBoxContainer/StatusLabel
@onready var clear_button: Button = $VBoxContainer/ClearButton

var output_history: Array[String] = []

func _ready():
	print("SpikeTest: Initializing test scene")
	
	# Connect UI signals
	send_button.pressed.connect(_on_send_button_pressed)
	clear_button.pressed.connect(_on_clear_button_pressed)
	input_line_edit.text_submitted.connect(_on_text_submitted)
	
	# Connect LLMClient signals (with safety check)
	await get_tree().process_frame  # Wait one frame to ensure autoloads are ready
	
	if has_method("get_node") and get_node("/root/LLMClient"):
		var llm_client = get_node("/root/LLMClient")
		llm_client.response_received.connect(_on_llm_response_received)
		llm_client.error_occurred.connect(_on_llm_error_occurred)
		print("SpikeTest: Connected to LLMClient")
	else:
		print("SpikeTest: WARNING - LLMClient not found. Please restart Godot editor.")
		_add_to_output("[ERROR] LLMClient not available. Please restart Godot editor.", Color.RED)
	
	# Update initial status
	_update_status()
	
	# Set initial focus to input field
	input_line_edit.grab_focus()
	
	# Set some default text to help with testing
	input_line_edit.placeholder_text = "Enter a message to test the LLM..."
	
	print("SpikeTest: Ready for testing")

func _on_send_button_pressed():
	"""Handle the send button press."""
	_send_current_input()

func _on_text_submitted(_text: String):
	"""Handle text submission from LineEdit (Enter key)."""
	_send_current_input()

func _send_current_input():
	"""Send the current input text to the LLM."""
	var input_text = input_line_edit.text
	
	if input_text.length() == 0:
		_add_to_output("[ERROR] Please enter some text first.", Color.RED)
		return
	
	# Check if LLMClient is available
	var llm_client = _get_llm_client()
	if not llm_client:
		_add_to_output("[ERROR] LLMClient not available. Please restart Godot editor.", Color.RED)
		return
	
	print("SpikeTest: Sending input: ", input_text)
	
	# Add user input to output
	_add_to_output("[USER] " + input_text, Color.CYAN)
	
	# Clear input field
	input_line_edit.text = ""
	
	# Show loading state
	_show_loading_state(true)
	
	# Send to LLM
	var success = llm_client.send_prompt(input_text)
	
	if not success:
		print("SpikeTest: Failed to send prompt")
		_show_loading_state(false)

func _on_llm_response_received(response_text: String):
	"""Handle successful LLM response."""
	print("SpikeTest: Received response: ", response_text.substr(0, 100), "...")
	
	_show_loading_state(false)
	_add_to_output("[LLM] " + response_text, Color.GREEN)
	
	# Return focus to input field
	input_line_edit.grab_focus()

func _on_llm_error_occurred(error_message: String):
	"""Handle LLM errors."""
	print("SpikeTest: LLM error: ", error_message)
	
	_show_loading_state(false)
	_add_to_output("[ERROR] " + error_message, Color.RED)
	
	# Return focus to input field
	input_line_edit.grab_focus()

func _show_loading_state(is_loading: bool):
	"""Show/hide loading indicator and update UI state."""
	if is_loading:
		send_button.text = "Processing..."
		send_button.disabled = true
		input_line_edit.editable = false
		_add_to_output("[SYSTEM] Processing your request...", Color.YELLOW)
	else:
		send_button.text = "Send"
		send_button.disabled = false
		input_line_edit.editable = true
	
	_update_status()

func _add_to_output(text: String, _color: Color = Color.WHITE):
	"""Add text to the output with timestamp and color."""
	var timestamp = Time.get_datetime_string_from_system()
	var formatted_text = "[" + timestamp + "] " + text + "\n"
	
	output_history.append(formatted_text)
	
	# Update the output display
	var full_text = ""
	for line in output_history:
		full_text += line
	
	output_text_label.clear()
	output_text_label.append_text(full_text)
	
	# Scroll to bottom
	await get_tree().process_frame
	var scroll_container = $VBoxContainer/OutputScrollContainer
	scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value

func _on_clear_button_pressed():
	"""Clear the output history."""
	output_history.clear()
	output_text_label.clear()
	_add_to_output("[SYSTEM] Output cleared.", Color.GRAY)
	print("SpikeTest: Output cleared")

func _update_status():
	"""Update the status label with current LLM client status."""
	var llm_client = _get_llm_client()
	if llm_client:
		var status_text = "LLM Status: " + llm_client.get_status()
		status_label.text = status_text
	else:
		status_label.text = "LLM Status: Not Available (Restart Editor)"

func _get_llm_client():
	"""Helper function to safely get the LLMClient autoload."""
	# Try to get the LLMClient autoload node
	return get_node_or_null("/root/LLMClient")

# Optional: Update status periodically
func _on_timer_timeout():
	_update_status()