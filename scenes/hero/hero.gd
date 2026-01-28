extends Player
class_name Hero

@export var target: Player

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	TurnManager.new_turn.connect(_on_new_turn)
#	setup random sprite assigment
	var possible_frame_coords: Array[Vector2i] = []
	for i in range(7):
		for j in range(7):
			if j == 0 and (i == 5 or i == 6):
				continue
			if j == 1 and (i == 5 or i == 6):
				continue
			if j == 3 and i == 6:
				continue
			if j == 4 and i == 6:
				continue
			if j == 5 and i == 6:
				continue
			if j == 6 and (i == 5 or i == 6):
				continue
			possible_frame_coords.append(Vector2i(i, j))
	sprite.frame_coords = possible_frame_coords.pick_random()

func _process(_delta: float) -> void:
	pass

func _on_new_turn(_turn: int) -> void:
	if target == null:
		return
	if moving:
		return
	var hero_cell: Vector2i = Vector2i(global_position / move_dist)
	var player_cell: Vector2i = Vector2i(target.global_position / move_dist)
	var diff: Vector2i = player_cell - hero_cell
	if diff == Vector2i.ZERO:
		return
	var dir: Vector2 = Vector2.ZERO
	if abs(diff.x) >= abs(diff.y):
		dir = Vector2(signi(diff.x), 0)
	else:
		dir = Vector2(0, signi(diff.y))
	await _try_step_no_turn(dir, diff)

func _try_step_no_turn(dir: Vector2, diff: Vector2i) -> void:
	var motion := dir * move_dist
	var next_pos := global_position + motion
	if test_move(global_transform, motion) or is_closed_door_at(next_pos):
		var alt := Vector2.ZERO
		if dir.x != 0:
			alt = Vector2(0, signi(diff.y))
		else:
			alt = Vector2(signi(diff.x), 0)
		if alt == Vector2.ZERO:
			return
		motion = alt * move_dist
		next_pos = global_position + motion
		if test_move(global_transform, motion) or is_closed_door_at(next_pos):
			return
	#if not move_audio.playing:
		#move_audio.play()
	moving = true
	prev_pos = global_position
	var target_pos := global_position + motion
	var tween := create_tween()
	tween.tween_property(self, "global_position", target_pos, step_time)
	await tween.finished
	moving = false

func is_closed_door_at(world_pos: Vector2) -> bool:
	var space := get_world_2d().direct_space_state
	var q := PhysicsPointQueryParameters2D.new()
	q.position = world_pos
	q.collide_with_areas = true
	q.collide_with_bodies = false
	var hits := space.intersect_point(q, 32)
	for h in hits:
		var c: Node = h.collider
		if c != null and c.is_in_group("door"):
			return true
	return false
