extends ConfirmationDialog

# Dialog.gd - Reusable dialog for confirmations and error messages
# Emits signals that parent scenes can connect to for handling user responses

signal dialog_confirmed
signal dialog_cancelled

var callback_data: Variant = null  # Store optional data for callbacks

func _ready():
	confirmed.connect(_on_confirmed)
	canceled.connect(_on_cancelled)
	close_requested.connect(_on_cancelled)

func show_confirmation(title_text: String, message: String, data: Variant = null):
	title = title_text
	dialog_text = message
	callback_data = data
	
	get_ok_button().visible = true
	get_cancel_button().visible = true
	
	popup_centered()

func show_error(title_text: String, message: String):
	title = title_text
	dialog_text = message
	callback_data = null
	
	get_cancel_button().visible = false
	
	popup_centered()

func _on_confirmed():
	dialog_confirmed.emit(callback_data)
	callback_data = null

func _on_cancelled():
	dialog_cancelled.emit()
	callback_data = null
