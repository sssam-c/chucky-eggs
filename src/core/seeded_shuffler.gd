class_name SeededShuffler
extends RefCounted

var _random := RandomNumberGenerator.new()


func _init(seed_value: int) -> void:
	_random.seed = seed_value


func shuffle_strings(values: Array[String]) -> Array[String]:
	var shuffled: Array[String] = values.duplicate()
	for index in range(shuffled.size() - 1, 0, -1):
		var swap_index := _random.randi_range(0, index)
		var held_value := shuffled[index]
		shuffled[index] = shuffled[swap_index]
		shuffled[swap_index] = held_value
	return shuffled
