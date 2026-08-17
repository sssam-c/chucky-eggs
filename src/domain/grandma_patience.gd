class_name GrandmaPatience
extends RefCounted

var _starting: int
var _current: int


func _init(starting_patience: int) -> void:
	assert(starting_patience > 0, "Grandma needs positive starting Patience.")
	_starting = starting_patience
	_current = starting_patience


func current() -> int:
	return _current


func starting() -> int:
	return _starting


func can_afford(amount: int) -> bool:
	assert(amount >= 0, "A Patience cost cannot be negative.")
	return _current >= amount


func gain(amount: int) -> void:
	assert(amount >= 0, "A Patience gain cannot be negative.")
	_current += amount


func lose(amount: int) -> int:
	assert(amount >= 0, "A Patience loss cannot be negative.")
	var amount_lost := mini(amount, _current)
	_current -= amount_lost
	return amount_lost
