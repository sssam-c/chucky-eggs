class_name ProducerChoiceButton
extends Button

var producer_kind := ""
var daily_yield := 0

@onready var _portrait: Control = %Portrait
@onready var _name_label: Label = %Name
@onready var _yield_label: Label = %Yield
@onready var _egg_previews: Array[Control] = [%Egg1, %Egg2]
@onready var _stats_label: Label = %Stats
@onready var _effect_label: Label = %Effect


func _ready() -> void:
	tooltip_text = ""


func render_choice(choice: Dictionary) -> void:
	producer_kind = String(choice.get("kind", ""))
	daily_yield = int(choice.get("daily_yield", 0))
	var toughness := int(choice.get("toughness", 0))
	var points := int(choice.get("points", 0))
	var yield_label := "%d %s / DAY" % [
		daily_yield,
		"EGG" if daily_yield == 1 else "EGGS",
	]
	var effect_description := _effect_description(String(choice.get("effect", "none")))
	_portrait.set_bird_kind(producer_kind)
	_name_label.text = producer_kind.to_upper()
	_yield_label.text = "LAYS %s" % yield_label
	_stats_label.text = "%d TOUGHNESS  •  %d %s" % [
		toughness, points, "POINT" if points == 1 else "POINTS",
	]
	_effect_label.text = effect_description
	var egg := {
		"kind": producer_kind,
		"toughness": toughness,
		"max_toughness": toughness,
		"points": points,
	}
	for preview_index in range(_egg_previews.size()):
		_egg_previews[preview_index].visible = preview_index < daily_yield
		_egg_previews[preview_index].set_egg(egg, true)
	accessibility_name = "%s producer" % producer_kind.capitalize()
	accessibility_description = "%s. %d toughness. Worth %d %s. %s" % [
		yield_label.to_lower(),
		toughness,
		points,
		"point" if points == 1 else "points",
		effect_description,
	]


func portrait_kind() -> String:
	return _portrait.bird_kind()


func preview_egg_kind() -> String:
	return _egg_previews[0].egg_kind()


func preview_egg_count() -> int:
	return _egg_previews.filter(func(preview: Control) -> bool: return preview.visible).size()


func card_text() -> String:
	return " ".join([
		_name_label.text, _yield_label.text, _stats_label.text, _effect_label.text,
	])


func _effect_description(effect: String) -> String:
	match effect:
		"adjacent_echo":
			return "Copies damage from an adjacent egg."
		"retreat":
			return "A surviving direct hit retreats."
		"pink_weakness":
			return "Pink deals 2 direct damage."
	return "Reliable and plentiful."
