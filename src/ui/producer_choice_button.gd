class_name ProducerChoiceButton
extends Button

var producer_kind := ""

@onready var _portrait: Control = %Portrait
@onready var _name_label: Label = %Name
@onready var _price_label: Label = %Price
@onready var _yield_label: Label = %Yield
@onready var _egg_preview: Control = %Egg1
@onready var _stats_label: Label = %Stats
@onready var _effect_label: Label = %Effect


func _ready() -> void:
	tooltip_text = ""


func render_choice(choice: Dictionary) -> void:
	producer_kind = String(choice.get("kind", ""))
	var toughness := int(choice.get("toughness", 0))
	var points := int(choice.get("points", 0))
	var effect_description := _effect_description(String(choice.get("effect", "none")))
	_portrait.set_bird_kind(producer_kind)
	_name_label.text = producer_kind.to_upper()
	_price_label.text = "FREE"
	_yield_label.text = "LAYS 1 EGG / DAY"
	_stats_label.text = "%d TOUGHNESS  •  %d %s" % [
		toughness, points, "POINT" if points == 1 else "POINTS",
	]
	_effect_label.text = effect_description
	var egg := {
		"kind": producer_kind,
		"toughness": toughness,
		"max_toughness": toughness,
		"points": points,
		"double_yolk_chance": float(choice.get("double_yolk_chance", 0.0)),
		"effects": choice.get("effects", []).duplicate(true),
		"all_other_effects": choice.get("all_other_effects", []).duplicate(true),
	}
	_egg_preview.set_egg(egg, true)
	accessibility_name = "%s bird, free day reward" % producer_kind.capitalize()
	accessibility_description = "Free day reward. Lays 1 egg per day. %d toughness. Worth %d %s. %s" % [
		toughness,
		points,
		"point" if points == 1 else "points",
		effect_description,
	]


func portrait_kind() -> String:
	return _portrait.bird_kind()


func preview_egg_kind() -> String:
	return _egg_preview.egg_kind()


func preview_egg_count() -> int:
	return 1


func card_text() -> String:
	return " ".join([
		_name_label.text, _price_label.text, _yield_label.text,
		_stats_label.text, _effect_label.text,
	])


func _effect_description(effect: String) -> String:
	match effect:
		"adjacent_echo":
			return "Copies damage from an adjacent egg."
		"screen_left":
			return "A surviving direct hit makes it retreat left."
		"pink_weakness":
			return "Pink deals 2 direct damage."
		"appetiser":
			return "Appetiser — doubles the next egg's immediate Yolk."
		"sulphurous":
			return "Sulphurous — suppresses 2 Appetite for the rest of the day."
		"shockwave":
			return "Shockwave — strikes both adjacent slots on hatching."
		"oily":
			return "Oily — adds one ▶ before normal belt movement."
		"nostalgic":
			return "Nostalgic — adds one ◀ before normal belt movement."
		"gloopy":
			return "Gloopy — jams the next movement; hatches for −1 Yolk."
	return "Reliable and plentiful."
