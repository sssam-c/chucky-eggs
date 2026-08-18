class_name FlockBirdButton
extends Button

@onready var _portrait: Control = %Portrait
@onready var _name_label: Label = %Name
@onready var _stats_label: Label = %Stats
@onready var _remove_label: Label = %Remove


func render_bird(fact: Dictionary, price: int, can_remove: bool, removal_used := false) -> void:
	var kind := String(fact.kind)
	_portrait.set_bird_kind(kind)
	_name_label.text = kind.to_upper()
	var effect_description := _effect_description(String(fact.get("effect", "none")))
	_stats_label.text = "%d SHELL  •  %d PTS  •  %s" % [
		int(fact.toughness), int(fact.points), effect_description,
	]
	_remove_label.text = "REMOVAL USED" if removal_used else "REMOVE  £%d" % price
	disabled = not can_remove
	accessibility_name = "%s bird" % kind.capitalize()
	accessibility_description = (
		"Lays one egg per day with %d toughness worth %d points. %s Remove for %d pounds.%s"
		% [
			int(fact.toughness),
			int(fact.points),
			effect_description,
			price,
			" The nightly removal has already been used." if removal_used else (
				" Unavailable." if disabled else ""
			),
		]
	)


func _effect_description(effect: String) -> String:
	match effect:
		"adjacent_echo":
			return "Echo"
		"screen_left":
			return "Retreat"
		"pink_weakness":
			return "Pink weakness"
		"appetiser":
			return "Appetiser"
		"sulphurous":
			return "Sulphurous"
		"shockwave":
			return "Shockwave"
		"oily":
			return "Extra ▶"
		"nostalgic":
			return "Reverse ◀"
		"gloopy":
			return "Foul −1 • Jam ⚙"
	return "No effect"


func portrait_kind() -> String:
	return _portrait.bird_kind()


func card_text() -> String:
	return " ".join([_name_label.text, _stats_label.text, _remove_label.text])
