extends Node2D

var room_scene: PackedScene = preload("res://scenes/room/room.tscn")
var room_count := 7
var collision_check_limit := 500

@onready var rooms := $Rooms
var room_list: Array[Room] = []

func _ready() -> void:
	for i in range(room_count):
		var room := room_scene.instantiate() as Room
#		create room with random coords between 0.0 and screenbounds
		rooms.add_child(room)
		room.global_position = get_random_coords(room)
#		check if it collides with existing rooms, if it does give it new coords
		check_collision(room, 0)
		room_list.append(room)

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
	return rand_coords
