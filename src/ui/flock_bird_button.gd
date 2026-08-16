class_name FlockBirdButton
extends Button

@onready var _portrait: Control = %Portrait
@onready var _name_label: Label = %Name
@onready var _stats_label: Label = %Stats
@onready var _remove_label: Label = %Remove


func render_bird(fact: Dictionary, price: int, can_remove: bool) -> void:
	var kind := String(fact.kind)
	var tier := int(fact.get("tier", 0))
	_portrait.set_bird_kind(kind)
	_name_label.text = "%s %s" % [_quality_name(tier), kind.to_upper()]
	_stats_label.text = "%d SHELL  •  %d PTS" % [int(fact.toughness), int(fact.points)]
	_remove_label.text = "REMOVE  £%d" % price
	disabled = not can_remove
	accessibility_name = "%s %s bird" % [_quality_name(tier).to_lower(), kind.capitalize()]
	accessibility_description = (
		"Lays one egg per day with %d toughness worth %d points. Remove for %d pounds.%s"
		% [
			int(fact.toughness),
			int(fact.points),
			price,
			" Unavailable." if disabled else "",
		]
	)


func portrait_kind() -> String:
	return _portrait.bird_kind()


func card_text() -> String:
	return " ".join([_name_label.text, _stats_label.text, _remove_label.text])


func _quality_name(tier: int) -> String:
	match tier:
		0:
			return "STANDARD"
		1:
			return "PRIZE"
		2:
			return "CHAMPION"
	return "TIER %d" % tier
