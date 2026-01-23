extends Node2D

@export var tile_size := 16
@export var min_size := Vector2i(5, 5)
@export var max_size := Vector2i(16, 16)
#@export var room_count := 7

@onready var floor_layer: TileMapLayer = $FloorLayer
@onready var wall_layer: TileMapLayer = $WallLayer

@export var floor_source := 0
@export var floor_coords := Vector2i(0, 3)
@export var floor_alt := 0

@export var wall_source := 0
@export var wall_coords_vert := Vector2i(0, 4)
@export var wall_coords_hor := Vector2i(1, 4)
@export var wall_alt := 0

@export var door_source := 0
@export var door_coords := Vector2i(2, 3)
@export var door_alt := 0

var screen_size := Vector2i.ZERO

@onready var player_scene := preload("res://scenes/player/player.tscn")
var player: Player = null
var rooms: Array[Rect2i] = []

func _ready() -> void:
	player = player_scene.instantiate() as Player
	var vp := get_viewport().get_visible_rect().size
	screen_size = Vector2i(int(vp.x / tile_size), int(vp.y / tile_size))
	generate()

func instantiate_player() -> void:
	var room := rooms[0]
#	generate player in a random coord in first room
	var cell := Vector2i(
		randi_range(room.position.x + 1, room.position.x + room.size.x - 2),
		randi_range(room.position.y + 1, room.position.y + room.size.y - 2)
	)

	player.global_position = floor_layer.map_to_local(cell)
	add_child(player)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("generate"):
		generate()

func generate() -> void:
	rooms = []
	var rooms_grid: Array[Vector2i] = []
	var corridors: Array[Vector2i] = []
	floor_layer.clear()
	wall_layer.clear()
#	divide the room into screen_size / max_size and create a room in each and connect them
	var section_count := Vector2i(
		screen_size.x / max_size.x,
		screen_size.y / max_size.y
	)
	for sy in range(section_count.y):
		for sx in range(section_count.x):
			var section := max_size * Vector2i(sx, sy)
			var room := generate_room(section)
			rooms.append(room)
			rooms_grid.append(Vector2i(sx, sy))
#	generate corridors
	for i in range(rooms.size()):
		var max_grid := get_max_xy(rooms_grid)
		var room_in_grid := rooms_grid[i]
		var room := rooms[i]
		var corridor: Array[Vector2i] = []
		if room_in_grid.x + 1 > max_grid.x and room_in_grid.y + 1 > max_grid.y:
			corridor = generate_corridor(room, Rect2i(-1, -1, -1, -1), Rect2i(-1, -1, -1, -1))
		elif room_in_grid.x + 1 > max_grid.x:
			var room_below_grid := Vector2i(room_in_grid.x, room_in_grid.y + 1)
			var idx := rooms_grid.find(room_below_grid)
			corridor = generate_corridor(room, rooms[idx], Rect2i(-1, -1, -1, -1))
		elif room_in_grid.y + 1 > max_grid.y:
			var room_right_grid := Vector2i(room_in_grid.x + 1, room_in_grid.y)
			var idx := rooms_grid.find(room_right_grid)
			corridor = generate_corridor(room, Rect2i(-1, -1, -1, -1), rooms[idx])
		else:
			var room_below_grid := Vector2i(room_in_grid.x, room_in_grid.y + 1)
			var idx_below := rooms_grid.find(room_below_grid)
			var room_right_grid := Vector2i(room_in_grid.x + 1, room_in_grid.y)
			var idx_right := rooms_grid.find(room_right_grid)
			corridor = generate_corridor(room, rooms[idx_below], rooms[idx_right])
		corridors.append_array(corridor)
#	carve
	for r in rooms:
		carve_room(r)
	carve_corridors(corridors)
	instantiate_player()

func generate_corridor(room: Rect2i, room_below: Rect2i, room_right: Rect2i) -> Array[Vector2i]:
#	TODO THIS IS SHIT DONT MAKE IT WALK OVER WALLS
	var corridor: Array[Vector2i] = []
	# sentinel check (you pass -1 rects when missing neighbor)
	var has_below := room_below.size.x > 0 and room_below.size.y > 0
	var has_right := room_right.size.x > 0 and room_right.size.y > 0
	var a := get_room_center(room)
	# connect to below
	if has_below:
		var b := get_room_center(room_below)
		# go vertical first (mostly straight)
		var current := a
		while current.y != b.y:
			current.y += signi(b.y - current.y)
			corridor.append(current)
		while current.x != b.x:
			current.x += signi(b.x - current.x)
			if intersects_wall(current):
				current.y += 1
			corridor.append(current)

	# connect to right
	if has_right:
		var b := get_room_center(room_right)
		# go horizontal first (mostly straight)
		var current := a
		while current.x != b.x:
			current.x += signi(b.x - current.x)
			corridor.append(current)
		while current.y != b.y:
			current.y += signi(b.y - current.y)
			corridor.append(current)
	return corridor

func intersects_wall(c: Vector2i) -> bool:
	return wall_layer.get_cell_source_id(c) != -1

func get_room_center(room: Rect2i) -> Vector2i:
	var x := int(room.position.x + room.size.x / 2)
	var y := int(room.position.y + room.size.y / 2)
	return Vector2i(x, y)

func get_max_xy(points: Array[Vector2i]) -> Vector2i:
	var max_x := points[0].x
	var max_y := points[0].y

	for p in points:
		if p.x > max_x:
			max_x = p.x
		if p.y > max_y:
			max_y = p.y

	return Vector2i(max_x, max_y)


func generate_room(section_origin: Vector2i) -> Rect2i:
	var width := randi_range(min_size.x, max_size.x)
	var height := randi_range(min_size.y, max_size.y)

	var x := randi_range(
		section_origin.x,
		section_origin.x + max_size.x - width
	)
	var y := randi_range(
		section_origin.y,
		section_origin.y + max_size.y - height
	)

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
		wall_layer.set_cell(Vector2i(i, y0), wall_source, wall_coords_hor, wall_alt)
		wall_layer.set_cell(Vector2i(i, y1 - 1), wall_source, wall_coords_hor, wall_alt)
#	vertical walls
	for i in range(y0, y1):
		wall_layer.set_cell(Vector2i(x0, i), wall_source, wall_coords_vert, wall_alt)
		wall_layer.set_cell(Vector2i(x1 - 1, i), wall_source, wall_coords_vert, wall_alt)

func carve_corridors(corridors: Array[Vector2i]) -> void:
	#	if there is a wall place a door, if there is no floor place a floor
	for i in range(corridors.size()):
		#floor_layer.set_cell(corridors[i], floor_source, Vector2(0,0), floor_alt)
		if wall_layer.get_cell_source_id(corridors[i]) != -1:
			var prev := Vector2i(-1, -1)
			var current := wall_layer.get_cell_atlas_coords(corridors[i])
			if i > 0:
				prev = wall_layer.get_cell_atlas_coords(corridors[i - 1])
			if ( 
				is_corner(prev) || 
				!is_corner(current) && prev != wall_coords_hor && prev != wall_coords_vert && prev != door_coords
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
		left == empty && right == wall_coords_hor && right == wall_coords_vert &&
		bottom_left == empty && bottom == wall_coords_hor && bottom == wall_coords_vert && bottom_right == empty
		)
	var is_top_right_corner := (
		top_left == empty && top == empty && top_right == empty &&
		left == wall_coords_hor && left == wall_coords_vert && right == empty &&
		bottom_left == empty && bottom == wall_coords_hor && bottom == wall_coords_vert && bottom_right == empty
		)
	var is_bottom_left_corner := (
		top_left == empty && top == wall_coords_hor && top == wall_coords_vert && top_right == empty &&
		left == empty && right == wall_coords_hor && right == wall_coords_vert &&
		bottom_left == empty && bottom == empty && bottom_right == empty
		)
	var is_bottom_right_corner := (
		top_left == empty && top == wall_coords_hor && top == wall_coords_vert && top_right == empty &&
		left == wall_coords_hor && left == wall_coords_vert && right == empty &&
		bottom_left == empty && bottom == empty && bottom_right == empty
		)
	return (
		is_top_left_corner ||
		is_top_right_corner ||
		is_bottom_left_corner ||
		is_bottom_right_corner
	)
