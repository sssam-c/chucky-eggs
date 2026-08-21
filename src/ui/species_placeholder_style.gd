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
	"woodpecker": Color("b54a3a"),
	"quail": Color("9b72b8"),
	"maleo": Color("df765e"),
	"ostrich": Color("b69a62"),
	"oily": Color("587b9b"),
	"nostalgic": Color("c48755"),
	"gloopy": Color("668f6e"),
}

const SHAPES := {
	"chicken": "round_comb",
	"cuckoo": "long_tail",
	"sparrow": "compact",
	"plover": "long_legged",
	"spoonbill": "spoon_bill",
	"woodpecker": "woodpecker",
	"quail": "topknot",
	"maleo": "casque",
	"ostrich": "tall_neck",
	"oily": "status_oily",
	"nostalgic": "status_nostalgic",
	"gloopy": "status_gloopy",
}

static func colour(kind: String) -> Color:
	return COLOURS.get(kind, COLOURS.chicken)


static func shape(kind: String) -> String:
	return SHAPES.get(kind, SHAPES.chicken)
