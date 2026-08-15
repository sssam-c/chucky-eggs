class_name ProducerOutputTile
extends Control

@onready var _portrait: Control = %Portrait
@onready var _name_label: Label = %Name
@onready var _yield_label: Label = %Yield
@onready var _egg_preview: Control = %Egg1

var production_fact: Dictionary = {}


func render_producer(fact: Dictionary) -> void:
	production_fact = fact.duplicate(true)
	var kind := String(fact.kind)
	_portrait.set_bird_kind(kind)
	_name_label.text = kind.to_upper()
	_yield_label.text = "LAYS ×1"
	var egg := {
		"kind": kind,
		"toughness": int(fact.toughness),
		"max_toughness": int(fact.toughness),
		"points": int(fact.points),
		"double_yolk_chance": float(fact.get("double_yolk_chance", 0.0)),
	}
	_egg_preview.set_egg(egg, true)


func egg_origins_global() -> Array[Vector2]:
	return [_egg_preview.global_position + _egg_preview.size * 0.5]
