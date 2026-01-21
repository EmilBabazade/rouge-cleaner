extends Node2D

@export var tile_size := 16
@export var min_size := Vector2i(7, 7)
@export var max_size := Vector2i(12, 12)
@export var room_count := 7

@onready var floor_layer: TileMapLayer = $FloorLayer
@onready var wall_layer: TileMapLayer = $WallLayer

@export var floor_source := 0
@export var floor_coords := Vector2i(0, 3)
@export var floor_alt := 0

@export var wall_source := 0
@export var wall_coords := Vector2i(1, 3)
@export var wall_alt := 0

@export var door_source := 0
@export var door_coords := Vector2i(2, 3)
@export var door_alt := 0

var rooms: Array[Rect2i] = []

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
	rooms = sort_rooms_by_distance()
	var corridors := generate_corridors()
	carve_corridors(corridors)

func carve_corridors(corridors: Array[Vector2i]) -> void:
	#	if there is a wall place a door, if there is no floor place a floor
	for i in range(corridors.size()):
		if wall_layer.get_cell_source_id(corridors[i]) != -1:
			var prev := Vector2i(-1, -1)
			var current := wall_layer.get_cell_atlas_coords(corridors[i])
			if i > 0:
				prev = wall_layer.get_cell_atlas_coords(corridors[i - 1])
			if ( 
				is_corner(prev) || 
				!is_corner(current) && prev != wall_coords && prev != door_coords
			):
				wall_layer.set_cell(corridors[i], door_source, door_coords, door_alt)
		elif floor_layer.get_cell_source_id(corridors[i]) == -1:
			floor_layer.set_cell(corridors[i], floor_source, floor_coords, floor_alt)

func is_corner(coords: Vector2i) -> bool:
	var top_left := wall_layer.get_cell_atlas_coords(Vector2i(coords.x - 1, coords.y - 1))
	var top := wall_layer.get_cell_atlas_coords(Vector2i(coords.x, coords.y - 1))
	var top_right := wall_layer.get_cell_atlas_coords(Vector2i(coords.x + 1, coords.y - 1))
	var right := wall_layer.get_cell_atlas_coords(Vector2i(coords.x + 1, coords.y))
	var left := wall_layer.get_cell_atlas_coords(Vector2i(coords.x - 1, coords.y))
	var bottom_left := wall_layer.get_cell_atlas_coords(Vector2i(coords.x - 1, coords.y + 1))
	var bottom := wall_layer.get_cell_atlas_coords(Vector2i(coords.x, coords.y + 1))
	var bottom_right := wall_layer.get_cell_atlas_coords(Vector2i(coords.x + 1, coords.y + 1))
	var empty := Vector2i(-1, -1)
#	floor cells are treated as empty since wall tilemaplayer isnt gonna catch them
	var is_top_left_corner := (
		top_left == empty && top == empty && top_right == empty &&
		left == empty && right == wall_coords &&
		bottom_left == empty && bottom == wall_coords && bottom_right == empty
		)
	var is_top_right_corner := (
		top_left == empty && top == empty && top_right == empty &&
		left == wall_coords && right == empty &&
		bottom_left == empty && bottom == wall_coords && bottom_right == empty
		)
	var is_bottom_left_corner := (
		top_left == empty && top == wall_coords && top_right == empty &&
		left == empty && right == wall_coords &&
		bottom_left == empty && bottom == empty && bottom_right == empty
		)
	var is_bottom_right_corner := (
		top_left == empty && top == wall_coords && top_right == empty &&
		left == wall_coords && right == empty &&
		bottom_left == empty && bottom == empty && bottom_right == empty
		)
	return (
		is_top_left_corner ||
		is_top_right_corner ||
		is_bottom_left_corner ||
		is_bottom_right_corner
	)

func generate_corridors() -> Array[Vector2i]:
	var corridors: Array[Vector2i] = []
	for i in range(rooms.size()):
		if i + 1 == rooms.size():
			return corridors
		var current := get_room_center(rooms[i])
		var end := get_room_center(rooms[i + 1])
		while current != end:
			var dx := signi(end.x - current.x)
			var dy := signi(end.y - current.y)
			if dx != 0 and dy != 0:
				if randi() % 2 == 0:
					current.x += dx
				else:
					current.y += dy
			elif dx != 0:
				current.x += dx
			else:
				current.y += dy
			corridors.append(current)
	return corridors

func sort_rooms_by_distance() -> Array[Rect2i]:
#	sort rooms by distance between room centers
	var sorted_rooms: Array[Rect2i] = []
	for i in range(rooms.size()):
		var distance := 999999999
		var sorted_room := Rect2i()
		for r in rooms:
			if sorted_rooms.has(r):
				continue
#			first room is closest to 0,0
			var current_distance := 0
			if i == 0:
				current_distance = get_room_center(r).distance_to(Vector2i.ZERO) 
			else:
				current_distance = get_room_center(r).distance_to(get_room_center(rooms[i])) 
			if current_distance < distance:
				distance = current_distance
				sorted_room = r
		sorted_rooms.append(sorted_room)
	return sorted_rooms

func get_room_center(room: Rect2i) -> Vector2i:
	var x := int(room.position.x + room.size.x / 2)
	var y := int(room.position.y + room.size.y / 2)
	return Vector2i(x, y)

func collides_with_other_rooms(room: Rect2i) -> bool:
	for other in rooms:
		if room.intersects(other):
			return true
	return false

func generate_room() -> Rect2i:
	var width := randi_range(min_size.x, max_size.x)
	var height := randi_range(min_size.y, max_size.y)
	var screen_size := get_viewport().get_visible_rect().size
	var x := randi_range(0, screen_size.x / tile_size - width)
	var y := randi_range(0, screen_size.y / tile_size - height)
	return Rect2i(x, y, width, height)

func carve_room(room: Rect2i) -> void:
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
			floor_layer.set_cell(Vector2i(i, j), floor_source, floor_coords, floor_alt)
#	horizontal walls
	for i in range(x0, x1):
		wall_layer.set_cell(Vector2i(i, y0), wall_source, wall_coords, wall_alt)
		wall_layer.set_cell(Vector2i(i, y1 - 1), wall_source, wall_coords, wall_alt)
#	vertical walls
	for i in range(y0, y1):
		wall_layer.set_cell(Vector2i(x0, i), wall_source, wall_coords, wall_alt)
		wall_layer.set_cell(Vector2i(x1 - 1, i), wall_source, wall_coords, wall_alt)
