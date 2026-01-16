extends Node2D
class_name Room

@export var max_width := 15
@export var min_width := 5
@export var max_height := 15
@export var min_height := 5

@onready var floor_tilemap: TileMapLayer = $FloorTileMap
@onready var wall_tilemap: TileMapLayer = $WallTileMap

func _ready() -> void:
	floor_tilemap.clear()
	wall_tilemap.clear()
	var x := randi_range(min_width, max_width)
	var y := randi_range(min_height, max_height)
#	place floor tiles
	for i in range(x):
		for j in range(y):
			floor_tilemap.set_cell(Vector2(i, j), 1, Vector2(0,3))
#	place horizontal walls
	for i in range(0, x):
		wall_tilemap.set_cell(Vector2(i, y), 0, Vector2(1,3))
		wall_tilemap.set_cell(Vector2(i, 0), 0, Vector2(1,3))
#	place vertical walls
	for i in range(0, y + 1):
		wall_tilemap.set_cell(Vector2(x, i), 0, Vector2(1,3))
		wall_tilemap.set_cell(Vector2(0, i), 0, Vector2(1,3))
