extends Node2D
class_name Room

@export var max_width := 15
@export var min_width := 5
@export var max_height := 15
@export var min_height := 5

@onready var floor_tilemap: TileMapLayer = $FloorTileMap
@onready var wall_tilemap: TileMapLayer = $WallTileMap

var width := 0
var height := 0

func _ready() -> void:
	floor_tilemap.clear()
	wall_tilemap.clear()
	width = randi_range(min_width, max_width)
	height = randi_range(min_height, max_height)
	var is_door_vertical := randi() % 2 == 0
#	place floor tiles
	for i in range(width):
		for j in range(height):
			floor_tilemap.set_cell(Vector2(i, j), 1, Vector2(0,3))
#	place horizontal walls
	var special_i := randi_range(1, width - 2)
	for i in range(0, width):
		if !is_door_vertical and i == special_i:
			if randi() % 2 == 0:
				wall_tilemap.set_cell(Vector2(i, height), 0, Vector2(2,3))
				wall_tilemap.set_cell(Vector2(i, 0), 0, Vector2(1,3))
			else:
				wall_tilemap.set_cell(Vector2(i, height), 0, Vector2(1,3))
				wall_tilemap.set_cell(Vector2(i, 0), 0, Vector2(2,3))
		else:
			wall_tilemap.set_cell(Vector2(i, height), 0, Vector2(1,3))
			wall_tilemap.set_cell(Vector2(i, 0), 0, Vector2(1,3))
#	place vertical walls
	special_i = randi_range(1, height - 2)
	for i in range(0, height + 1):
		if is_door_vertical and i == special_i:
			if randi() % 2 == 0:
				wall_tilemap.set_cell(Vector2(width, i), 0, Vector2(2,3))
				wall_tilemap.set_cell(Vector2(0, i), 0, Vector2(1,3))
			else:
				wall_tilemap.set_cell(Vector2(width, i), 0, Vector2(1,3))
				wall_tilemap.set_cell(Vector2(0, i), 0, Vector2(2,3))
		else:
			wall_tilemap.set_cell(Vector2(width, i), 0, Vector2(1,3))
			wall_tilemap.set_cell(Vector2(0, i), 0, Vector2(1,3))

func draw_corridor(to_room: Room) -> void:
	# Convert both room centers (WORLD pixels) -> THIS room's tile cells
	var a: Vector2i = floor_tilemap.local_to_map(floor_tilemap.to_local(get_center()))
	var b: Vector2i = floor_tilemap.local_to_map(floor_tilemap.to_local(to_room.get_center()))

	# Build an L-shaped path in CELL coords (tile-by-tile)
	var pts: Array[Vector2i] = []

	var x := a.x
	var y := a.y

	var sx := 1 if b.x >= x else -1
	while x != b.x:
		pts.append(Vector2i(x, y))
		x += sx

	var sy := 1 if b.y >= y else -1
	while y != b.y:
		pts.append(Vector2i(x, y))
		y += sy

	pts.append(b)

	# Draw corridor on THIS room's floor tilemap using CELL coords directly
	for cell in pts:
		if floor_tilemap.get_cell_source_id(cell) == -1:
			floor_tilemap.set_cell(cell, 1, Vector2i(0, 3))


func get_size() -> Vector2:
# i am assuming tile size x and y are same
	var tile_size := floor_tilemap.tile_set.tile_size.x
	return floor_tilemap.get_used_rect().size * tile_size

func collides_with(other: Room) -> bool:
# i am assuming tile size x and y are same
	var a := Rect2(global_position, get_size())
	var b := Rect2(other.global_position, other.get_size())
	return a.intersects(b)

func get_center() -> Vector2:
	return global_position + get_size() * 0.5
