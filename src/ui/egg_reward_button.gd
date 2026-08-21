class_name EggRewardButton
extends Button

const ChickenDay = preload("res://src/domain/chicken_day.gd")

var egg_kind := ""

@onready var _name_label: Label = %Name
@onready var _egg_visual: Control = %Egg
@onready var _stats_label: Label = %Stats
@onready var _effect_label: Label = %Effect


func render_offer(kind: String) -> void:
	var definition := ChickenDay.egg_definition(kind)
	assert(not definition.is_empty(), "Unknown reward egg: %s" % kind)
	egg_kind = kind
	var toughness := int(definition.toughness)
	var yolk := int(definition.points)
	_name_label.text = kind.to_upper()
	_stats_label.text = "%d TOUGHNESS  •  %d YOLK" % [toughness, yolk]
	_effect_label.text = _effect_description(String(definition.effect))
	_egg_visual.set_egg({
		"kind": kind,
		"toughness": toughness,
		"max_toughness": toughness,
		"points": yolk,
		"effects": [],
		"all_other_effects": [],
	}, true)
	accessibility_name = "Add one %s egg" % kind.capitalize()
	accessibility_description = "%d toughness, %d Yolk. %s" % [
		toughness, yolk, _effect_description(String(definition.effect)),
	]


func card_text() -> String:
	return " ".join([_name_label.text, _stats_label.text, _effect_label.text])


func _effect_description(effect: String) -> String:
	match effect:
		"adjacent_echo":
			return "Copies damage when an adjacent egg is tapped."
		"screen_left":
			return "After surviving a direct tap, swaps one cup left."
		"pink_weakness":
			return "A direct Pink tap deals 2 damage."
		"break_tap_right":
			return "On break, fires the spoon immediately to its right."
		_:
			return "No additional effect."
