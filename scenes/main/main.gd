extends Node2D

@export var tile_size := 32
@export var min_size := Vector2i(5, 5)
@export var max_size := Vector2i(16, 16)

@onready var floor_layer: TileMapLayer = $FloorLayer
@export var floor_source := 2
@export var floor_coords := Vector2i(0, 12)
@export var floor_alt := 0

@onready var wall_layer: TileMapLayer = $WallLayer
@export var wall_source := 3
@export var wall_coords_vert := Vector2i(0, 2)
@export var wall_coords_hor := Vector2i(1, 2)
@export var wall_alt := 0

@export var door_source := 1
@export var door_coords := Vector2i(0, 0)
@export var door_alt := 1

@onready var darkness_layer: TileMapLayer = $DarknessLayer
@export var darkness_source := 3
@export var darkness_coords := Vector2i(0, 0)
@export var darkness_alt := 0

@export var screen_size := Vector2i(72, 40)

@onready var player_scene := preload("res://scenes/player/player.tscn")
var player: Player = null
var rooms: Array[Rect2i] = []
var dark_rooms: Array[Rect2i] = []
var corridors: Array[Corridor] = []
var dark_corridors: Array[Corridor] = []

@onready var hero_scene := preload("res://scenes/hero/hero.tscn")
var hero: Hero
@export var min_hero_turn := 20
@export var max_hero_turn := 100
var hero_turn: int
var player_spawn_room: Rect2

@onready var dirt_scene:PackedScene = preload("res://scenes/dirt/dirt.tscn")
@onready var dirt_holder := $DirtHolder

@onready var camera: Camera2D = $Camera2D

func _ready() -> void:
	#var vp := get_viewport().get_visible_rect().size
	#screen_size = Vector2i(int(vp.x / tile_size), int(vp.y / tile_size))
	camera.limit_bottom = screen_size.y * tile_size
	camera.limit_right = screen_size.x * tile_size
	player = player_scene.instantiate() as Player
	camera.position_smoothing_enabled = false
	camera.global_position = player.global_position
	camera.set_deferred('position_smoothing_enabled', true)
	add_child(player)
	generate()

func connect_signals() -> void:
	var doors := get_tree().get_nodes_in_group('door')
	for d: Door in doors:
		d.door_opened.connect(on_door_opened)
	TurnManager.new_turn.connect(on_next_turn)

func on_next_turn(turn: int) -> void:
	print("turn: ", turn)

func _process(_delta: float) -> void:
#	camera follow player
	camera.global_position = player.global_position
#	change camera zoom level
	if Input.is_action_just_pressed("zoom"):
		if camera.zoom == Vector2.ONE:
			camera.position_smoothing_enabled = false
			camera.zoom = Vector2(0.5,0.5)
			camera.position_smoothing_enabled = true
		else:
			camera.position_smoothing_enabled = false
			camera.zoom = Vector2.ONE
			camera.position_smoothing_enabled = true
# 	regenerate room when r is pressed
	if Input.is_action_just_pressed("generate"):
		generate()
#	when player intersects with a room make it alight
	var to_remove: Array[int] = []
	for i in range(dark_rooms.size()):
		var r := dark_rooms[i]
		var p := Rect2i(player.position / tile_size, Vector2i(1, 1))
		if r.intersects(p):
			for x in range(r.position.x, r.position.x + r.size.x):
				for y in range(r.position.y, r.position.y + r.size.y):
					var coord := Vector2i(x,y)
					darkness_layer.erase_cell(coord)
			to_remove.append(i)
	for i in to_remove:
		dark_rooms.remove_at(i)
#	add hero that chases the player
	if TurnManager._turn == hero_turn and not hero.is_node_ready():
		var room := player_spawn_room
	#	generate hero in a random coord in first room
		var cell := Vector2i(
			randi_range(room.position.x + 1, room.position.x + room.size.x - 2),
			randi_range(room.position.y + 1, room.position.y + room.size.y - 2)
		)
		hero.global_position = floor_layer.map_to_local(cell)
		hero.target = player
		add_child(hero)
		print('new hero is coming!')

#  alights the corridor this door is on
func on_door_opened() -> void:
	var curr_pos: Vector2i = player.global_position / tile_size
	reveal_from(curr_pos)

func reveal_from(start: Vector2i) -> void:
	var stack: Array[Vector2i] = [start]
	var seen := {}
	var dirs := [
		Vector2i(0,1),
		Vector2i(0,-1),
		Vector2i(1,0),
		Vector2i(-1,0)
	]
	for d: Vector2i in dirs: 
			stack.append(start + d)
	while stack.size() > 0:
		var pos: Vector2i = stack.pop_back()
		if seen.has(pos):
			continue
		seen[pos] = true
		if wall_layer.get_cell_source_id(pos) != -1: 
			darkness_layer.erase_cell(pos)
			continue
		if floor_layer.get_cell_atlas_coords(pos) == door_coords: 
			darkness_layer.erase_cell(pos)
			continue
		darkness_layer.erase_cell(pos)
		for d: Vector2i in dirs: 
			stack.append(pos + d)

func erase_darkness(pos: Vector2i) -> void:
	var dirs := [
		Vector2i(0, 0),
		Vector2i(0, 1),
		Vector2i(0, -1),
		Vector2i(1, 0),
		Vector2i(-1, 0)
	]
	for dir: Vector2i in dirs:
		darkness_layer.erase_cell(pos + dir)

# add the player to the scene in a random room
func instantiate_player() -> void:
	var room := rooms[0]
	player_spawn_room = room
#	generate player in a random coord in first room
	var cell := Vector2i(
		randi_range(room.position.x + 1, room.position.x + room.size.x - 2),
		randi_range(room.position.y + 1, room.position.y + room.size.y - 2)
	)
	player.global_position = floor_layer.map_to_local(cell)

# generate 0 to minimum room area number of dirts in every room 
func generate_dirts() -> void:
	var max_dirt_count := min_size.x * min_size.y
	for r in rooms:
		for i in randi_range(0, max_dirt_count):
			var dirt := dirt_scene.instantiate() as Dirt
			dirt.global_position = get_random_dirt_coords(r)
			var attempts := max_dirt_count * 10
			while dirt_collides_with_others(dirt) and attempts > 0:
				dirt.global_position = get_random_dirt_coords(r)
			if !dirt_collides_with_others(dirt):
				dirt_holder.add_child(dirt)

# get random dirt coordinates in a room
func get_random_dirt_coords(r: Rect2i) -> Vector2:
	var coord := Vector2i(-1,-1)
	coord.x = randi_range(r.position.x + 1, r.position.x + r.size.x - 2)
	coord.y = randi_range(r.position.y + 1, r.position.y + r.size.y - 2)
	var local := floor_layer.map_to_local(coord)
	return to_global(local)

# check if dirt is on top of any other dirt
func dirt_collides_with_others(d: Dirt) -> bool:
	for other in d.get_overlapping_areas():
		if other.is_in_group('dirt'):
			return true
	return false

# generate rooms and corridors
func generate() -> void:
	rooms = []
	corridors = []
	var rooms_grid: Array[Vector2i] = []
	floor_layer.clear()
	wall_layer.clear()
	darkness_layer.clear()
	for child in dirt_holder.get_children():
		child.queue_free.call_deferred()
	TurnManager.reset()
	if hero != null:
		hero.queue_free()
	hero = hero_scene.instantiate() as Hero
	hero_turn = randi_range(min_hero_turn, max_hero_turn)
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
		corridors.append(Corridor.create(corridor))
	dark_rooms = rooms
	dark_corridors = corridors
#	carve
	for r in rooms:
		carve_room(r)
	carve_corridors()
	instantiate_player()
	generate_walls()
	generate_dirts()
	connect_signals.call_deferred()
	generate_darkness()

# make everything dark
func generate_darkness() -> void:
	var cover_size := screen_size * 1.2
	for x in cover_size.x:
		for y in cover_size.y:
			var coord := Vector2i(x, y)
			darkness_layer.set_cell(coord, darkness_source, darkness_coords, darkness_alt)

# fill the rest of the map with walls
func generate_walls() -> void:
	for x in screen_size.x:
		for y in screen_size.y:
			var coord := Vector2i(x,y)
			if (floor_layer.get_cell_source_id(coord) == -1
				and wall_layer.get_cell_source_id(coord) == -1):
					var above := Vector2i(coord.x, coord.y - 1)
					var below := Vector2i(coord.x, coord.y + 1)
					if (floor_layer.get_cell_source_id(above) != -1 or
						floor_layer.get_cell_source_id(below) != -1):
						wall_layer.set_cell(coord, wall_source, wall_coords_hor, wall_alt)
					else:
						wall_layer.set_cell(coord, wall_source, wall_coords_vert, wall_alt)

# generate corridors between rooms
func generate_corridor(room: Rect2i, room_below: Rect2i, room_right: Rect2i) -> Array[Vector2i]:
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

# check if coord intersects with a wall
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

# generate a room in section
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

# place floor tiles surrounded by walls
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

func carve_corridors() -> void:
	#	if there is a wall place a door, if there is no floor place a floor
	var corrs: Array[Vector2i] = []
	for c in corridors:
		corrs.append_array(c.cells)
	for i in range(corrs.size()):
		#floor_layer.set_cell(corridors[i], floor_source, Vector2(0,0), floor_alt)
		if wall_layer.get_cell_source_id(corrs[i]) != -1:
			var prev := Vector2i(-1, -1)
			var current := wall_layer.get_cell_atlas_coords(corrs[i])
			if i > 0:
				prev = wall_layer.get_cell_atlas_coords(corrs[i - 1])
			if ( 
				is_corner(prev) || 
				!is_corner(current) && prev != wall_coords_hor && prev != wall_coords_vert && prev != door_coords
			):
				wall_layer.set_cell(corrs[i], door_source, door_coords, door_alt)
				floor_layer.set_cell(corrs[i], floor_source, floor_coords, floor_alt)
		elif floor_layer.get_cell_source_id(corrs[i]) == -1:
			floor_layer.set_cell(corrs[i], floor_source, floor_coords, floor_alt)

# check if wall is in the corner of room
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
