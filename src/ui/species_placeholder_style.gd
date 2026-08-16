class_name SpeciesPlaceholderStyle
extends RefCounted

# One deliberately flat colour identifies a species everywhere placeholder art
# appears. These values are temporary art direction, not gameplay data.
const COLOURS := {
	"chicken": Color("e2a83f"),
	"cuckoo": Color("3f9c9a"),
	"sparrow": Color("b86f43"),
	"plover": Color("7f9d45"),
	"spoonbill": Color("c8649d"),
}

const SHAPES := {
	"chicken": "round_comb",
	"cuckoo": "long_tail",
	"sparrow": "compact",
	"plover": "long_legged",
	"spoonbill": "spoon_bill",
}

static func colour(kind: String) -> Color:
	return COLOURS.get(kind, COLOURS.chicken)


static func shape(kind: String) -> String:
	return SHAPES.get(kind, SHAPES.chicken)
