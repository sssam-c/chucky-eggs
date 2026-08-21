class_name EggContainerRow
extends PanelContainer

@onready var _position_label: Label = %Position
@onready var _egg_visual: Control = %EggVisual
@onready var _name_label: Label = %Name
@onready var _facts_label: Label = %Facts
@onready var _effect_label: Label = %Effect

var _egg: Dictionary = {}


func render_egg(egg: Dictionary, position_text: String) -> void:
	_egg = egg.duplicate(true)
	_position_label.text = position_text
	_egg_visual.set_egg(_egg, true)
	var kind := String(_egg.get("kind", "egg"))
	_name_label.text = kind.to_upper()
	var toughness := int(_egg.get("toughness", 0))
	var max_toughness := int(_egg.get("max_toughness", toughness))
	var points := int(_egg.get("points", 0))
	var chance := floori(float(_egg.get("double_yolk_chance", 0.0)) * 100.0)
	_facts_label.text = "TOUGHNESS %d / %d  •  %d %s  •  DOUBLE YOLK %d%%" % [
		toughness,
		max_toughness,
		points,
		"POINT" if points == 1 else "POINTS",
		chance,
	]
	_effect_label.text = _effect_text(kind)
	accessibility_name = "%s, %s" % [position_text.capitalize(), _name_label.text.capitalize()]
	accessibility_description = "%d of %d toughness remaining, worth %d points. %s" % [
		toughness, max_toughness, points, _effect_label.text,
	]


func egg_snapshot() -> Dictionary:
	return _egg.duplicate(true)


func position_text() -> String:
	return _position_label.text


func visible_text() -> String:
	return "\n".join([
		_position_label.text, _name_label.text, _facts_label.text, _effect_label.text,
	])
func _effect_text(kind: String) -> String:
	match kind:
		"cuckoo":
			return "ECHO  •  COPIES DAMAGE FROM AN ADJACENT EGG"
		"plover":
			return "RETREAT  •  SURVIVING DIRECT HITS MOVE IT LEFT"
		"spoonbill":
			return "SPARK WEAKNESS  •  PINK DIRECT HITS DEAL 2"
		"woodpecker":
			return "ON BREAK  •  FIRES THE SPOON IMMEDIATELY TO ITS RIGHT"
		"quail":
			return "APPETISER  •  DOUBLES THE NEXT EGG'S IMMEDIATE YOLK"
		"maleo":
			return "SULPHUROUS  •  SUPPRESSES 2 APPETITE THIS DAY"
		"ostrich":
			return "SHOCKWAVE  •  STRIKES BOTH ADJACENT SLOTS"
		"oily":
			return "OILY  •  DIRECT HIT ADDS ONE ▶"
		"nostalgic":
			return "NOSTALGIC  •  DIRECT HIT ADDS ONE ◀"
		"gloopy":
			return "GLOOPY  •  JAMS NEXT MOVEMENT  •  HATCHES FOR −1 YOLK"
	return "NO EXTRA EFFECT"
