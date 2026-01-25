extends Area2D
class_name Dirt


#func _on_body_entered(body: Node2D) -> void:
	#if body is Player:
		#queue_free.call_deferred()
