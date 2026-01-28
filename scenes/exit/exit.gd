extends Area2D
class_name Exit

signal exit


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		exit.emit()
