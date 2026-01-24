extends Node
class_name Corridor

var cells: Array[Vector2i] = []

static func create(c: Array[Vector2i]) -> Corridor:
	var corr := Corridor.new()
	corr.cells = c
	return corr

func intersects(coord: Vector2i) -> bool:
	return cells.has(coord)
