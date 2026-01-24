extends Area2D
class_name Door

signal door_opened

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
#		TODO sound effect
		door_opened.emit()
		queue_free.call_deferred()
