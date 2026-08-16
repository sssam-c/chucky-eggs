class_name FlockBirdButton
extends Button

const QualityPalette = preload("res://src/ui/quality_palette.gd")

var _rarity_color := Color(0, 0, 0, 0)

@onready var _rarity_tint: ColorRect = %RarityTint
@onready var _rarity_stripe: ColorRect = %RarityStripe
@onready var _portrait: Control = %Portrait
@onready var _name_label: Label = %Name
@onready var _stats_label: Label = %Stats
@onready var _remove_label: Label = %Remove


func render_bird(fact: Dictionary, price: int, can_remove: bool, removal_used := false) -> void:
	var kind := String(fact.kind)
	var tier := int(fact.get("tier", 0))
	_apply_rarity(tier)
	_portrait.set_bird_kind(kind)
	_name_label.text = "%s %s" % [_quality_name(tier), kind.to_upper()]
	_stats_label.text = "%d SHELL  •  %d PTS" % [int(fact.toughness), int(fact.points)]
	_remove_label.text = "REMOVAL USED" if removal_used else "REMOVE  £%d" % price
	disabled = not can_remove
	accessibility_name = "%s %s bird" % [_quality_name(tier).to_lower(), kind.capitalize()]
	accessibility_description = (
		"Lays one egg per day with %d toughness worth %d points. Remove for %d pounds.%s"
		% [
			int(fact.toughness),
			int(fact.points),
			price,
			" The nightly removal has already been used." if removal_used else (
				" Unavailable." if disabled else ""
			),
		]
	)


func portrait_kind() -> String:
	return _portrait.bird_kind()


func card_text() -> String:
	return " ".join([_name_label.text, _stats_label.text, _remove_label.text])


func rarity_color() -> Color:
	return _rarity_color


func has_rarity_tint() -> bool:
	return _rarity_tint.visible


func _apply_rarity(tier: int) -> void:
	_rarity_color = QualityPalette.rarity_color(tier)
	var accented := _rarity_color.a > 0.0
	_rarity_tint.visible = accented
	_rarity_stripe.visible = accented
	if not accented:
		return
	_rarity_tint.color = Color(_rarity_color, 0.18)
	_rarity_stripe.color = _rarity_color


func _quality_name(tier: int) -> String:
	match tier:
		0:
			return "STANDARD"
		1:
			return "PRIZE"
		2:
			return "CHAMPION"
	return "TIER %d" % tier
