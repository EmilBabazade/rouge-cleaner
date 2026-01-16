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
#	place floor tiles
	for i in range(width):
		for j in range(height):
			floor_tilemap.set_cell(Vector2(i, j), 1, Vector2(0,3))
#	place horizontal walls
	for i in range(0, width):
		wall_tilemap.set_cell(Vector2(i, height), 0, Vector2(1,3))
		wall_tilemap.set_cell(Vector2(i, 0), 0, Vector2(1,3))
#	place vertical walls
	for i in range(0, height + 1):
		wall_tilemap.set_cell(Vector2(width, i), 0, Vector2(1,3))
		wall_tilemap.set_cell(Vector2(0, i), 0, Vector2(1,3))

func get_size() -> Vector2:
# i am assuming tile size x and y are same
	var tile_size := floor_tilemap.tile_set.tile_size.x
	return floor_tilemap.get_used_rect().size * tile_size

func collides_with(other: Room) -> bool:
# i am assuming tile size x and y are same
	var a := Rect2(global_position, get_size())
	var b := Rect2(other.global_position, other.get_size())
	return a.intersects(b)
