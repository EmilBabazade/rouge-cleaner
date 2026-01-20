extends Node2D

@export var tile_size := 16
@export var min_size := Vector2(7, 7)
@export var max_size := Vector2(12, 12)
@export var room_count := 10

@onready var floor_layer: TileMapLayer = $FloorLayer
@onready var wall_layer: TileMapLayer = $WallLayer

@export var floor_source := 0
@export var floor_coords := Vector2(0, 3)
@export var floor_alt := 0

@export var wall_source := 0
@export var wall_coords := Vector2(1, 3)
@export var wall_alt := 0

var rooms: Array[Rect2] = []

func _ready() -> void:
	generate()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("generate"):
		generate()

func generate() -> void:
	rooms = []
	floor_layer.clear()
	wall_layer.clear()
	for i in range(room_count):
		var room := generate_room()
		var attempt := 1
		var max_attempt := room_count * room.get_area() * 10
#		regenerate until doesnt collide with other rooms
		while collides_with_other_rooms(room) and attempt < max_attempt:
			room = generate_room()
			attempt += 1
#		couldnt generate a non colliding room in max attempts so skip this room
		if collides_with_other_rooms(room):
			continue
		carve_room(room)
		rooms.append(room)
	generate_corridors()

func generate_corridors() -> void:
	print(rooms)
	rooms = sort_rooms_by_distance()
	print('-----')
	print(rooms)
#	TODO: FINISH THIS

func sort_rooms_by_distance() -> Array[Rect2]:
#	sort rooms by distance between room centers
	var sorted_rooms: Array[Rect2] = []
	for i in range(rooms.size()):
		var distance := 999999999
		var sorted_room := Rect2()
		for r in rooms:
			if sorted_rooms.has(r):
				continue
#			first room is closest to 0,0
			var current_distance := 0
			if i == 0:
				current_distance = get_room_center(r).distance_to(Vector2.ZERO) 
			else:
				current_distance = get_room_center(r).distance_to(get_room_center(rooms[i])) 
			if current_distance < distance:
				distance = current_distance
				sorted_room = r
		sorted_rooms.append(sorted_room)
	return sorted_rooms

func get_room_center(room: Rect2) -> Vector2:
	var x: int = (room.position.x + room.size.x) / 2
	var y: int = (room.position.y + room.size.y) / 2
	return Vector2(x, y)

func collides_with_other_rooms(room: Rect2) -> bool:
	for other in rooms:
		if room.intersects(other):
			return true
	return false

func generate_room() -> Rect2:
	var width := randi_range(min_size.x, max_size.x)
	var height := randi_range(min_size.y, max_size.y)
	var screen_size := get_viewport().get_visible_rect().size
	var x := randi_range(0, screen_size.x / tile_size - width)
	var y := randi_range(0, screen_size.y / tile_size - height)
	return Rect2(x, y, width, height)

func carve_room(room: Rect2) -> void:
#	put floor tiles x0+1 to x1 - 1 and y0 + 1 to y1 - 1
#   put horizontal wall tiles x0 to x1 at y0 and same at y1
#   put vertical wall tiles y0 + 1 to y1 - 1 at x0 and x1
	var x0 := room.position.x
	var x1 := room.position.x + room.size.x
	var y0 := room.position.y
	var y1 := room.position.y + room.size.y
#	floor
	for i in range(x0 + 1, x1 - 1):
		for j in range(y0 + 1, y1 - 1):
			floor_layer.set_cell(Vector2(i, j), floor_source, floor_coords, floor_alt)
#	horizontal walls
	for i in range(x0, x1):
		wall_layer.set_cell(Vector2(i, y0), wall_source, wall_coords, wall_alt)
		wall_layer.set_cell(Vector2(i, y1 - 1), wall_source, wall_coords, wall_alt)
#	vertical walls
	for i in range(y0, y1):
		wall_layer.set_cell(Vector2(x0, i), wall_source, wall_coords, wall_alt)
		wall_layer.set_cell(Vector2(x1 - 1, i), wall_source, wall_coords, wall_alt)
