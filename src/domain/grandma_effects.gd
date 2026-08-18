class_name GrandmaEffects
extends RefCounted

const EggEffects = preload("res://src/domain/egg_effects.gd")
const SULPHUROUS_APPETITE_PER_EGG := 2

var _appetiser_charges := 0
var _sulphurous_suppression := 0


func snapshot() -> Dictionary:
	return {
		"appetiser_charges": _appetiser_charges,
		"sulphurous_suppression": _sulphurous_suppression,
	}


func activate(
	effect: Dictionary,
	events: Array[Dictionary],
	base_appetite: int,
	current_satisfaction: int
) -> void:
	var suppression_added := 0
	match String(effect.type):
		EggEffects.APPETISER:
			_appetiser_charges += 1
		EggEffects.SULPHUROUS:
			var appetite_before := effective_appetite(base_appetite)
			_sulphurous_suppression = mini(
				_sulphurous_suppression + SULPHUROUS_APPETITE_PER_EGG,
				maxi(base_appetite - 1, 0)
			)
			suppression_added = appetite_before - effective_appetite(base_appetite)
		_:
			assert(false, "Shockwave is an immediate egg effect, not a Grandma effect.")
	events.append({
		"type": "grandma_effect_activated",
		"effect_type": String(effect.type),
		"grandma_effects": snapshot(),
		"base_appetite": base_appetite,
		"effective_appetite": effective_appetite(base_appetite),
		"score": current_satisfaction,
		"satisfaction": current_satisfaction,
		"suppression_added": suppression_added,
	})


func appetiser_multiplier_for_yolk(yolk: int, events: Array[Dictionary]) -> int:
	if yolk <= 0 or _appetiser_charges <= 0:
		return 1
	_appetiser_charges -= 1
	events.append({
		"type": "appetiser_consumed",
		"multiplier": 2,
		"grandma_effects": snapshot(),
	})
	return 2


func effective_appetite(base_appetite: int) -> int:
	return maxi(1, base_appetite - _sulphurous_suppression)


func clear() -> void:
	_appetiser_charges = 0
	_sulphurous_suppression = 0
