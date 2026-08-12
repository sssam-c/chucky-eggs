class_name ChickenDaySession
extends RefCounted

const ChickenDay = preload("res://src/domain/chicken_day.gd")

var _day = ChickenDay.new()


func state() -> Dictionary:
	return _day.snapshot()


func submit_thwack(slot_index: int) -> Array[Dictionary]:
	return _day.resolve_thwack(slot_index)


func restart() -> void:
	_day = ChickenDay.new()
