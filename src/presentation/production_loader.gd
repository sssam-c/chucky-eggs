class_name ProductionLoader
extends Control

signal loading_started(producer_count: int, egg_count: int)

const PRODUCER_TILE_SCENE = preload("res://src/presentation/producer_output_tile.tscn")
const EGG_VISUAL_SCRIPT = preload("res://src/ui/egg_visual.gd")

@onready var _title_label: Label = %Title
@onready var _subtitle_label: Label = %Subtitle
@onready var _flock_grid: GridContainer = %FlockGrid
@onready var _hopper_label: Label = %HopperLabel
@onready var _hopper_mouth: PanelContainer = %HopperMouth
@onready var _egg_flights: Control = %EggFlights

var _active := false
var _generation := 0
var _flight_tweens: Array[Tween] = []


func begin(
	production: Array[Dictionary],
	day_number: int,
	daily_egg_count: int,
	reduced_motion: bool
) -> bool:
	cancel()
	var playback_generation := _generation
	_active = true
	visible = true
	_title_label.text = "THE FLOCK LAYS — DAY %d" % day_number
	_subtitle_label.text = "%d PRODUCERS LOAD %d EGGS INTO THE HOPPER" % [
		production.size(), daily_egg_count,
	]
	_hopper_label.text = "HOPPER OPEN  •  0 / %d EGGS" % daily_egg_count
	for fact: Dictionary in production:
		var tile = PRODUCER_TILE_SCENE.instantiate()
		_flock_grid.add_child(tile)
		tile.render_producer(fact)

	loading_started.emit(production.size(), daily_egg_count)
	await get_tree().process_frame
	if playback_generation != _generation:
		return false

	if reduced_motion:
		_hopper_label.text = "HOPPER LOADED  •  %d EGGS" % daily_egg_count
		await get_tree().process_frame
		return _finish(playback_generation)

	var loaded_eggs := 0
	for tile in _flock_grid.get_children():
		var fact: Dictionary = tile.production_fact
		var origins: Array[Vector2] = tile.egg_origins_global()
		for egg_index in range(origins.size()):
			_spawn_flying_egg(fact, origins[egg_index])
		loaded_eggs += int(fact.daily_yield)
		_hopper_label.text = "LOADING HOPPER  •  %d / %d EGGS" % [loaded_eggs, daily_egg_count]
		await get_tree().create_timer(0.07).timeout
		if playback_generation != _generation:
			return false

	await get_tree().create_timer(0.52).timeout
	if playback_generation != _generation:
		return false
	_hopper_label.text = "HOPPER LOADED  •  %d EGGS" % daily_egg_count
	await get_tree().create_timer(0.24).timeout
	return _finish(playback_generation)


func cancel() -> void:
	_generation += 1
	for tween: Tween in _flight_tweens:
		if tween != null and tween.is_valid():
			tween.kill()
	_flight_tweens.clear()
	_clear_children(_flock_grid)
	_clear_children(_egg_flights)
	_active = false
	visible = false


func is_active() -> bool:
	return _active


func producer_count() -> int:
	return _flock_grid.get_child_count()


func _spawn_flying_egg(fact: Dictionary, origin_global: Vector2) -> void:
	var flight := Control.new()
	flight.set_script(EGG_VISUAL_SCRIPT)
	flight.custom_minimum_size = Vector2(42, 56)
	flight.size = Vector2(42, 56)
	flight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_egg_flights.add_child(flight)
	flight.set_egg({
		"kind": String(fact.kind),
		"toughness": int(fact.toughness),
		"max_toughness": int(fact.toughness),
		"points": int(fact.points),
	}, true)
	flight.position = origin_global - _egg_flights.global_position - flight.size * 0.5
	var target_global: Vector2 = _hopper_mouth.global_position + _hopper_mouth.size * 0.5
	var target_position: Vector2 = target_global - _egg_flights.global_position - flight.size * 0.5
	var tween := create_tween()
	_flight_tweens.append(tween)
	tween.tween_property(flight, "position", target_position, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(flight, "rotation", 0.35, 0.42)
	tween.parallel().tween_property(flight, "scale", Vector2(0.55, 0.55), 0.42)
	tween.tween_callback(flight.queue_free)


func _finish(playback_generation: int) -> bool:
	if playback_generation != _generation:
		return false
	_active = false
	visible = false
	_clear_children(_flock_grid)
	_clear_children(_egg_flights)
	_flight_tweens.clear()
	return true


func _clear_children(parent: Node) -> void:
	for child: Node in parent.get_children():
		child.free()
