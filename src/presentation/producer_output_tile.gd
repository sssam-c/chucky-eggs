class_name ProducerOutputTile
extends Control

@onready var _portrait: Control = %Portrait
@onready var _name_label: Label = %Name
@onready var _yield_label: Label = %Yield
@onready var _egg_previews: Array[Control] = [%Egg1, %Egg2]

var production_fact: Dictionary = {}


func render_producer(fact: Dictionary) -> void:
	production_fact = fact.duplicate(true)
	var kind := String(fact.kind)
	var daily_yield := int(fact.daily_yield)
	_portrait.set_bird_kind(kind)
	_name_label.text = kind.to_upper()
	_yield_label.text = "LAYS ×%d" % daily_yield
	var egg := {
		"kind": kind,
		"toughness": int(fact.toughness),
		"max_toughness": int(fact.toughness),
		"points": int(fact.points),
	}
	for preview_index in range(_egg_previews.size()):
		_egg_previews[preview_index].visible = preview_index < daily_yield
		_egg_previews[preview_index].set_egg(egg, true)


func egg_origins_global() -> Array[Vector2]:
	var origins: Array[Vector2] = []
	for preview: Control in _egg_previews:
		if preview.visible:
			origins.append(preview.global_position + preview.size * 0.5)
	return origins
