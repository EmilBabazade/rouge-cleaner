extends AnimatableBody2D
class_name Player

@export var move_dist := 16
@export var step_time := 0.05
@export var first_repeat_delay := 0.18
@export var repeat_delay := 0.07

var prev_pos: Vector2
var moving := false
var held_dir := Vector2.ZERO
var repeat_timer := 0.0
var first_repeat := true

@onready var cleaning_area: Area2D = $CleaningArea

func _process(delta: float) -> void:
#	movement
	var dir := _read_dir()
	if dir != Vector2.ZERO:
		if dir != held_dir:
			held_dir = dir
			first_repeat = true
			repeat_timer = 0.0
			_try_step(dir)
		else:
			repeat_timer -= delta
			if repeat_timer <= 0.0:
				_try_step(dir)
	else:
		held_dir = Vector2.ZERO
#	cleaning
	if Input.is_action_just_pressed("clean"):
		var areas := cleaning_area.get_overlapping_areas()
		for area in areas:
			if area.is_in_group("dirt"):
				area.queue_free.call_deferred()

func _read_dir() -> Vector2:
	if Input.is_action_pressed("left"):
		return Vector2.LEFT
	if Input.is_action_pressed("up"):
		return Vector2.UP
	if Input.is_action_pressed("right"):
		return Vector2.RIGHT
	if Input.is_action_pressed("down"):
		return Vector2.DOWN
	return Vector2.ZERO

func _try_step(dir: Vector2) -> void:
	if moving:
		return
	moving = true
	var motion := dir * move_dist
	if not test_move(global_transform, motion):
		prev_pos = global_position
		var target := global_position + motion
		var tween := create_tween()
		var _x := tween.tween_property(self, "global_position", target, step_time)
		await tween.finished
	moving = false
	repeat_timer = first_repeat_delay if first_repeat else repeat_delay
	first_repeat = false
