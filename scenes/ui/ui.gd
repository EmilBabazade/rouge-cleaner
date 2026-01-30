extends CanvasLayer
signal new_game


func _on_button_pressed() -> void:
	new_game.emit() 
