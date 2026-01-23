extends AnimatableBody2D
class_name Player

@export var move_dist := 16

func _process(_delta: float) -> void:
	var direction := Vector2.ZERO
	if Input.is_action_just_pressed("left"):
		direction = Vector2.LEFT
	elif Input.is_action_just_pressed("up"):
		direction = Vector2.UP
	elif Input.is_action_just_pressed("right"):
		direction = Vector2.RIGHT
	elif Input.is_action_just_pressed("down"):
		direction = Vector2.DOWN
	
	if direction != Vector2.ZERO:
		move(direction)

func move(direction: Vector2) -> void:
	var motion := direction * move_dist
	if not test_move(global_transform, motion):
		var target := global_position + motion
		var tween := create_tween()
		var _dump := tween.tween_property(self, "global_position", target, 0.05)
		await tween.finished
		direction = Vector2.ZERO
