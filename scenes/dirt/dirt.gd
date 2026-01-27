extends Area2D
class_name Dirt

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	var possible_frame_cords: Array[Vector2] = []
	for i in range(12):
		for j in range(2):
			possible_frame_cords.append(Vector2(i, j))
	sprite.frame_coords = possible_frame_cords.pick_random()
