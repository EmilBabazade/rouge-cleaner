extends Node2D

var room_scene: PackedScene = preload("res://scenes/room/room.tscn")
var room_count := 8
var collision_check_limit := 1000

@export var draw_corridor_paths := false

@onready var rooms := $Rooms
var room_list: Array[Room] = []
var closest_rooms: Dictionary[Room, Room] = {}

func _ready() -> void:
	for i in range(room_count):
		var room := room_scene.instantiate() as Room
#		create room with random coords between 0.0 and screenbounds
		rooms.add_child(room)
		room.global_position = get_random_coords(room)
#		check if it collides with existing rooms, if it does give it new coords
		check_collision(room, 0)
		room_list.append(room)
#	setup corridors
	for r: Room in room_list:
		var best: Room = null
		var best_d2 := INF
		var center := r.get_center()
		for other: Room in room_list:
			if r == other or (closest_rooms.has(other) and closest_rooms[other] == r):
				continue
			var d2 := center.distance_squared_to(other.get_center())
			if d2 < best_d2:
				best_d2 = d2
				best = other
		closest_rooms[r] = best
#		corridors
		var points := l_path(r.get_center(), best.get_center())
		r.draw_corridor(best)
		if draw_corridor_paths:
#			line2d to visualize paths
			var line := Line2D.new()
			add_child(line)
			line.width = 2
			line.default_color = Color(randf(), randf(), randf(), 1.0)
			line.points = points

func l_path(a: Vector2i, b: Vector2i) -> Array[Vector2i]:
	var pts: Array[Vector2i] = []
	var x := a.x
	var y := a.y

	# horizontal
	var sx := 1 if b.x >= x else -1
	while x != b.x:
		pts.append(Vector2i(x, y))
		x += sx

	# vertical
	var sy := 1 if b.y >= y else -1
	while y != b.y:
		pts.append(Vector2i(x, y))
		y += sy

	pts.append(b)
	return pts

func check_collision(room: Room, check_count: int) -> void:
	check_count += 1
	assert(check_count < collision_check_limit, "Maximum room collision check recursion limit reached!")
	for r in room_list:
		if room.collides_with(r):
			room.global_position = get_random_coords(room)
			check_collision(room, check_count)
			return

func get_random_coords(room: Room) -> Vector2:
	var screen_size := get_viewport().get_visible_rect().size
	var room_size := room.get_size()
	var rand_coords := Vector2.ZERO
	rand_coords.x = randi_range(0, screen_size.x - room_size.x)
	rand_coords.y = randi_range(0, screen_size.y - room_size.y)
	rand_coords = snap_to_grid(rand_coords, 16)
	return rand_coords

func snap_to_grid(pos: Vector2, tile: int) -> Vector2:
	return pos.snapped(Vector2(tile, tile))
