extends Node

signal new_turn(turn: int)
var _turn := 0

func move_turn() -> void:
	_turn += 1
	new_turn.emit(_turn)

func reset() -> void:
	_turn = 0
