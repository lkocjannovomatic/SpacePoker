extends ConfirmationDialog

# Dialog.gd - Reusable dialog for confirmations and error messages
# Emits signals that parent scenes can connect to for handling user responses

signal dialog_confirmed
signal dialog_cancelled

var callback_data: Variant = null  # Store optional data for callbacks

func _ready():
	# Connect built-in signals
	confirmed.connect(_on_confirmed)
	canceled.connect(_on_cancelled)
	close_requested.connect(_on_cancelled)

func show_confirmation(title_text: String, message: String, data: Variant = null):
	"""Show a confirmation dialog with OK and Cancel buttons."""
	title = title_text
	dialog_text = message
	callback_data = data
	
	# Show both OK and Cancel buttons
	get_ok_button().visible = true
	get_cancel_button().visible = true
	
	popup_centered()

func show_error(title_text: String, message: String):
	"""Show an error message with only an OK button."""
	title = title_text
	dialog_text = message
	callback_data = null
	
	# Hide cancel button for error messages
	get_cancel_button().visible = false
	
	popup_centered()

func _on_confirmed():
	"""Handle confirmation button click."""
	dialog_confirmed.emit(callback_data)
	callback_data = null

func _on_cancelled():
	"""Handle cancellation or dialog close."""
	dialog_cancelled.emit()
	callback_data = null
