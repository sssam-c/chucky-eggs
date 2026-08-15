class_name SeededChanceRoller
extends RefCounted

var _random := RandomNumberGenerator.new()


func _init(seed_value: int) -> void:
	_random.seed = seed_value


func roll(chance: float) -> bool:
	assert(chance >= 0.0 and chance <= 1.0, "A chance must be between zero and one.")
	return _random.randf() < chance
