class_name BirdPortrait
extends Control

const PORTRAIT_ATLAS: Texture2D = preload(
	"res://assets/generated/bird_portraits_v1.png"
)
const PORTRAIT_REGIONS := {
	"chicken": Rect2(0, 0, 611, 643),
	"cuckoo": Rect2(611, 0, 612, 643),
	"plover": Rect2(0, 643, 611, 643),
	"spoonbill": Rect2(611, 643, 612, 643),
}

var _kind := "chicken"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func set_bird_kind(kind: String) -> void:
	_kind = kind if PORTRAIT_REGIONS.has(kind) else "chicken"
	queue_redraw()


func bird_kind() -> String:
	return _kind


func artwork_region() -> Rect2:
	return PORTRAIT_REGIONS.get(_kind, PORTRAIT_REGIONS.chicken)


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.47
	draw_circle(center + Vector2(0, 2), radius + 3.0, Color(0, 0, 0, 0.42))
	draw_circle(center, radius, Color("171516"))
	draw_circle(center, radius - 3.0, _backdrop_color())
	draw_arc(center, radius - 2.0, 0.0, TAU, 48, Color("e3a84b"), 3.0, true)

	var source := artwork_region()
	var available := Vector2(radius * 2.02, radius * 2.02)
	var scale_factor := minf(available.x / source.size.x, available.y / source.size.y)
	var artwork_size := source.size * scale_factor
	var destination := Rect2(center - artwork_size * 0.5, artwork_size)
	draw_texture_rect_region(PORTRAIT_ATLAS, destination, source)

	# The restrained inner highlight joins the painted cutout to the existing
	# brass medallion without covering species-defining feathers or beaks.
	draw_arc(
		center - Vector2(1, 1), radius - 5.0, PI * 1.04, PI * 1.78, 24,
		Color(1.0, 0.88, 0.62, 0.42), 2.0, true
	)


func _backdrop_color() -> Color:
	match _kind:
		"cuckoo": return Color("173b40")
		"plover": return Color("34401d")
		"spoonbill": return Color("4b2944")
	return Color("55291b")
