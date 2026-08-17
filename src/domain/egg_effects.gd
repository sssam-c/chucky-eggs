class_name EggEffects
extends RefCounted

const APPETISER := "appetiser"
const SULPHUROUS := "sulphurous"
const SHOCKWAVE := "shockwave"
const DECEPTIVELY_FILLING := "deceptively_filling"
const SHOCK_ABSORBER := "shock_absorber"
const SUPPORTED_TYPES: Array[String] = [
	APPETISER,
	SULPHUROUS,
	SHOCKWAVE,
	DECEPTIVELY_FILLING,
	SHOCK_ABSORBER,
]


static func normalize(raw_effects: Variant) -> Array[Dictionary]:
	var normalized: Array[Dictionary] = []
	if raw_effects == null:
		return normalized
	assert(raw_effects is Array, "Egg effects must be an array of effect descriptors.")
	for raw_effect: Variant in raw_effects:
		assert(raw_effect is Dictionary, "An egg effect must be a dictionary descriptor.")
		var effect_type := String(raw_effect.get("type", ""))
		assert(effect_type in SUPPORTED_TYPES, "Unknown egg effect: %s" % effect_type)
		var effect := {"type": effect_type}
		if effect_type == DECEPTIVELY_FILLING:
			var duration := int(raw_effect.get("duration", 0))
			assert(duration > 0, "Deceptively Filling needs a positive duration.")
			effect["duration"] = duration
		normalized.append(effect)
	return normalized


static func break_actions(
	effects: Array[Dictionary],
	slot_index: int,
	circuit_id: String,
	slot_count: int
) -> Array[Dictionary]:
	var actions: Array[Dictionary] = []
	for effect: Dictionary in effects:
		if effect.type == SHOCKWAVE:
			var adjacent_slots: Array[int] = []
			if slot_index > 0:
				adjacent_slots.append(slot_index - 1)
			if slot_index + 1 < slot_count:
				adjacent_slots.append(slot_index + 1)
			actions.append({
				"type": "strike_adjacent",
				"source_slot_index": slot_index,
				"slot_indices": adjacent_slots,
				"circuit_id": circuit_id,
			})
		elif effect.type != SHOCK_ABSORBER:
			actions.append({"type": "grandma_effect", "effect": effect.duplicate(true)})
	return actions


static func descriptions(effects: Array[Dictionary]) -> Array[String]:
	var result: Array[String] = []
	for effect: Dictionary in effects:
		match String(effect.type):
			APPETISER:
				result.append("Appetiser: doubles one future egg's positive Yolk")
			SULPHUROUS:
				result.append("Sulphurous: suppresses 2 Appetite for the rest of the day")
			SHOCKWAVE:
				result.append("Shockwave: strikes the adjacent slots when this egg hatches")
			DECEPTIVELY_FILLING:
				result.append(
					"Deceptively Filling (%d): banks slow-release Yolk, releasing 1 each future thwack"
					% int(effect.duration)
				)
			SHOCK_ABSORBER:
				result.append("Shock Absorber: takes Grandma's hit for the spoon beneath it")
	return result
