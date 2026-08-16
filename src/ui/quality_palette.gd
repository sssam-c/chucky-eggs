class_name QualityPalette
extends RefCounted

const PRIZE_COLOR := Color("55b86a")
const CHAMPION_COLOR := Color("4d89e8")


static func rarity_color(tier: int) -> Color:
	if tier == 1:
		return PRIZE_COLOR
	if tier >= 2:
		return CHAMPION_COLOR
	return Color(0, 0, 0, 0)
