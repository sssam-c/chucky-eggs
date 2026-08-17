class_name EggTooltipCard
extends PanelContainer

const PlaceholderStyle = preload("res://src/ui/species_placeholder_style.gd")

@onready var _title: Label = %Title
@onready var _species_swatch: ColorRect = %SpeciesSwatch
@onready var _title_rule: PanelContainer = %TitleRule
@onready var _points_value: Label = %PointsValue
@onready var _chance_value: Label = %ChanceValue
@onready var _on_hit_section: PanelContainer = %OnHitSection
@onready var _on_hit_body: Label = %OnHitBody
@onready var _other_section: PanelContainer = %OtherSection
@onready var _other_body: Label = %OtherBody
@onready var _all_other_section: PanelContainer = %AllOtherSection
@onready var _all_other_body: Label = %AllOtherBody

var _egg: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_render()


func configure(egg: Dictionary) -> void:
	_egg = egg.duplicate(true)
	if is_node_ready():
		_render()


func card_text() -> String:
	var blocks: Array[String] = [
		"%s." % _display_name().to_upper(),
		"POINTS\n%d" % int(_egg.get("points", 0)),
		"CHANCE OF DOUBLE YOLKER\n%s" % _double_yolker_chance_text(),
	]
	var effects := _effect_sections()
	for heading in ["ON HIT EFFECTS", "OTHER EFFECTS", "ALL OTHER EFFECTS"]:
		var body := String(effects.get(heading, ""))
		if not body.is_empty():
			blocks.append("%s\n%s" % [heading, body])
	return "\n\n".join(blocks)


func visible_effect_sections() -> Array[String]:
	var visible_sections: Array[String] = []
	var effects := _effect_sections()
	for heading in ["ON HIT EFFECTS", "OTHER EFFECTS", "ALL OTHER EFFECTS"]:
		if not String(effects.get(heading, "")).is_empty():
			visible_sections.append(heading)
	return visible_sections


func effect_bodies_use_word_wrap() -> bool:
	return (
		_on_hit_body.autowrap_mode != TextServer.AUTOWRAP_OFF
		and _other_body.autowrap_mode != TextServer.AUTOWRAP_OFF
		and _all_other_body.autowrap_mode != TextServer.AUTOWRAP_OFF
	)


func _render() -> void:
	_title.text = "%s." % _display_name().to_upper()
	_points_value.text = str(int(_egg.get("points", 0)))
	_chance_value.text = _double_yolker_chance_text()

	var effects := _effect_sections()
	_configure_section(_on_hit_section, _on_hit_body, String(effects["ON HIT EFFECTS"]))
	_configure_section(_other_section, _other_body, String(effects["OTHER EFFECTS"]))
	_configure_section(
		_all_other_section,
		_all_other_body,
		String(effects["ALL OTHER EFFECTS"])
	)

	var panel_style := get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	var accent := PlaceholderStyle.colour(_kind()).lightened(0.18)
	panel_style.border_color = accent
	add_theme_stylebox_override("panel", panel_style)
	_species_swatch.color = accent
	var rule_style := _title_rule.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	rule_style.bg_color = Color(accent, 0.52)
	_title_rule.add_theme_stylebox_override("panel", rule_style)
	reset_size()
	_fit_to_visible_content.call_deferred()


func _fit_to_visible_content() -> void:
	reset_size()


func _configure_section(section: PanelContainer, body_label: Label, body: String) -> void:
	section.visible = not body.is_empty()
	body_label.text = body


func _effect_sections() -> Dictionary:
	var sections := {
		"ON HIT EFFECTS": "",
		"OTHER EFFECTS": "",
		"ALL OTHER EFFECTS": "",
	}
	match _kind():
		"cuckoo":
			sections["OTHER EFFECTS"] = (
				"Echo — copies damage dealt to an adjacent egg."
			)
		"plover":
			sections["ON HIT EFFECTS"] = (
				"Retreat — after surviving a direct hit, moves one bay left."
			)
		"spoonbill":
			sections["ON HIT EFFECTS"] = (
				"Pink weakness — a direct Pink strike deals 2 damage."
			)

	var extra_effects: Variant = _egg.get("all_other_effects", [])
	if extra_effects is Array:
		var effect_lines: PackedStringArray = []
		for effect: Variant in extra_effects:
			if not String(effect).is_empty():
				effect_lines.append(String(effect))
		sections["ALL OTHER EFFECTS"] = "\n".join(effect_lines)
	elif not String(extra_effects).is_empty():
		sections["ALL OTHER EFFECTS"] = String(extra_effects)
	return sections


func _double_yolker_chance_text() -> String:
	var chance := clampf(float(_egg.get("double_yolk_chance", 0.0)), 0.0, 1.0)
	return "%d%%" % floori(chance * 100.0)


func _display_name() -> String:
	var animal_name := "Soft-Shelled" if _kind() == "soft_shelled" else _kind().capitalize()
	match int(_egg.get("tier", 0)):
		1:
			return "Prize %s" % animal_name
		2:
			return "Champion %s" % animal_name
		var tier when tier > 2:
			return "Tier %d %s" % [tier, animal_name]
	return animal_name


func _kind() -> String:
	return String(_egg.get("kind", "chicken"))
