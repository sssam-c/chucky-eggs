class_name BirdPortrait
extends Control

const PlaceholderStyle = preload("res://src/ui/species_placeholder_style.gd")
const SpeciesIconRenderer = preload("res://src/ui/species_icon_renderer.gd")

var _kind := "chicken"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func set_bird_kind(kind: String) -> void:
	_kind = kind if PlaceholderStyle.COLOURS.has(kind) else "chicken"
	queue_redraw()


func bird_kind() -> String:
	return _kind


func placeholder_color() -> Color:
	return PlaceholderStyle.colour(_kind)


func placeholder_shape() -> String:
	return PlaceholderStyle.shape(_kind)


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.47
	draw_circle(center + Vector2(0, 2), radius + 2.0, Color(0, 0, 0, 0.34))
	draw_circle(center, radius, Color("202124"))
	draw_circle(center, radius - 3.0, Color("ded8ca"))
	SpeciesIconRenderer.draw(
		self, _kind, center, radius * 0.72, placeholder_color()
	)
