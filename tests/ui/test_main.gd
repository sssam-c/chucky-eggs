extends GutTest

const ChickenDaySession = preload("res://src/game/chicken_day_session.gd")
const ProducerFlock = preload("res://src/domain/producer_flock.gd")
const MotionTokens = preload("res://src/presentation/motion_tokens.gd")
const BirdPortrait = preload("res://src/ui/bird_portrait.gd")
const EggVisual = preload("res://src/ui/egg_visual.gd")
const AUTHORED_DAILY_EGGS: Array[String] = [
	"chicken", "cuckoo", "chicken", "spoonbill",
	"cuckoo", "plover", "chicken", "chicken",
	"chicken", "cuckoo", "chicken", "spoonbill",
	"cuckoo", "plover", "chicken", "chicken",
	"chicken", "cuckoo", "chicken", "spoonbill",
	"cuckoo", "plover", "chicken", "chicken",
]
const EARLY_SUCCESS_CIRCUITS: Array[String] = [
	"RedCircuit", "RedCircuit", "RedCircuit", "RedCircuit",
	"BlueCircuit", "RedCircuit", "BlueCircuit", "RedCircuit",
]
const AUTHORED_SUCCESS_CIRCUITS: Array[String] = [
	"RedCircuit", "RedCircuit", "RedCircuit", "BlueCircuit", "RedCircuit",
	"RedCircuit", "RedCircuit", "BlueCircuit", "RedCircuit",
]


class IdentityShuffler:
	extends RefCounted

	func shuffle_strings(values: Array[String]) -> Array[String]:
		return values.duplicate()

	func shuffle_dictionaries(values: Array[Dictionary]) -> Array[Dictionary]:
		return values.duplicate(true)


class EffectInjectingShuffler:
	extends RefCounted

	var effect_type: String

	func _init(injected_effect_type: String) -> void:
		effect_type = injected_effect_type

	func shuffle_strings(values: Array[String]) -> Array[String]:
		return values.duplicate()

	func shuffle_dictionaries(values: Array[Dictionary]) -> Array[Dictionary]:
		var eggs := values.duplicate(true)
		if not eggs.is_empty():
			eggs[0]["effects"] = [{"type": effect_type}]
		return eggs


func test_each_species_uses_matching_placeholder_colour_and_distinct_bird_shape() -> void:
	var portrait := BirdPortrait.new()
	var egg_visual := EggVisual.new()
	add_child_autofree(portrait)
	add_child_autofree(egg_visual)

	if not portrait.has_method("placeholder_color") or not egg_visual.has_method("placeholder_color"):
		fail_test("Species placeholders must expose their shared colour.")
		return

	var species_colours: Array[Color] = []
	var bird_shapes: Array[String] = []
	for kind in ProducerFlock.PRODUCER_KINDS:
		portrait.set_bird_kind(kind)
		egg_visual.set_egg({"kind": kind, "toughness": 3, "max_toughness": 3, "points": 1})
		assert_eq(portrait.placeholder_color(), egg_visual.placeholder_color())
		assert_false(species_colours.has(portrait.placeholder_color()))
		assert_false(bird_shapes.has(portrait.placeholder_shape()))
		species_colours.append(portrait.placeholder_color())
		bird_shapes.append(portrait.placeholder_shape())

	assert_false(portrait.has_method("artwork_texture"))
	assert_false(egg_visual.has_method("artwork_texture"))
	assert_false(egg_visual.has_method("placeholder_mark"))


func test_bird_cards_use_no_standard_accent_green_prize_and_blue_champion() -> void:
	var choice = load("res://src/ui/producer_choice_button.tscn").instantiate()
	var flock_bird = load("res://src/ui/flock_bird_button.tscn").instantiate()
	add_child_autofree(choice)
	add_child_autofree(flock_bird)
	await get_tree().process_frame

	for tier in range(3):
		var fact := {
			"kind": "chicken",
			"tier": tier,
			"toughness": 3,
			"points": 3,
			"effect": "none",
			"double_yolk_chance": 0.02,
		}
		choice.render_choice(fact)
		flock_bird.render_bird(fact, 3, true)
		assert_eq(choice.rarity_color(), flock_bird.rarity_color())
		assert_eq(choice.has_rarity_tint(), tier > 0)
		assert_eq(flock_bird.has_rarity_tint(), tier > 0)
		if tier == 0:
			assert_eq(choice.rarity_color(), Color(0, 0, 0, 0))
		elif tier == 1:
			assert_eq(choice.rarity_color(), Color("55b86a"))
		else:
			assert_eq(choice.rarity_color(), Color("4d89e8"))


func test_new_species_reward_cards_explain_their_signature_eggs() -> void:
	var choice = load("res://src/ui/producer_choice_button.tscn").instantiate()
	add_child_autofree(choice)
	await get_tree().process_frame
	var expected_effect_text := {
		"quail": "Appetiser",
		"maleo": "2 Appetite",
		"ostrich": "Shockwave",
		"kiwi": "8 slow-release Yolk",
	}
	for kind: String in expected_effect_text:
		var fact: Dictionary = ChickenDaySession.new(42, ProducerFlock.new([
			{"kind": kind},
		])).state().flock_overview[0]
		choice.render_choice(fact)
		assert_eq(choice.portrait_kind(), kind)
		assert_eq(choice.preview_egg_kind(), kind)
		assert_string_contains(choice.card_text(), expected_effect_text[kind])


func test_occupied_egg_hover_uses_a_custom_magnifying_glass_cursor() -> void:
	var egg_visual := EggVisual.new()
	add_child_autofree(egg_visual)
	egg_visual.set_egg({"kind": "chicken", "points": 3})

	assert_eq(egg_visual.mouse_default_cursor_shape, Control.CURSOR_HELP)
	var cursor_path := "res://assets/ui/cursors/egg_inspect.svg"
	assert_true(ResourceLoader.exists(cursor_path))
	if not ResourceLoader.exists(cursor_path):
		return
	var cursor_texture := load(cursor_path) as Texture2D
	assert_not_null(cursor_texture)
	if cursor_texture != null:
		assert_eq(cursor_texture.get_size(), Vector2(32.0, 32.0))


func test_stage_egg_names_are_available_in_hover_cards_without_visible_labels() -> void:
	var slot = load("res://src/ui/egg_slot.tscn").instantiate()
	slot.slot_index = 1
	add_child_autofree(slot)
	await get_tree().process_frame
	var cuckoo := {
		"kind": "cuckoo",
		"toughness": 4,
		"max_toughness": 4,
		"points": 1,
	}
	slot.render_egg(cuckoo, false)

	assert_null(slot.get_node_or_null("Caption"))
	assert_null(slot.get_node_or_null("EggContent/Kind"))
	var egg_visual: Control = slot.get_node("EggContent/EggVisual")
	assert_eq(egg_visual.mouse_filter, Control.MOUSE_FILTER_PASS)
	assert_eq(egg_visual.tooltip_text, "")
	assert_null(egg_visual.get_node_or_null("ScoreIconHover"))
	assert_null(egg_visual.get_node_or_null("EffectIconHover"))
	assert_true(egg_visual.has_method("show_hover_card"))
	var card: Control = egg_visual.make_tooltip_card()
	add_child_autofree(card)
	assert_string_contains(card.card_text(), "POINTS\n1")
	assert_string_contains(card.card_text(), "copies damage")

	slot.render_egg(cuckoo, false, true)
	assert_null(slot.get_node_or_null("Caption"))
	assert_null(slot.get_node_or_null("EggContent/Kind"))
	var preview_card: Control = egg_visual.make_tooltip_card()
	add_child_autofree(preview_card)
	assert_string_contains(preview_card.card_text(), "CUCKOO.")


func test_compact_egg_preview_uses_the_same_complete_anchored_hover_card() -> void:
	var egg_visual := EggVisual.new()
	egg_visual.size = Vector2(34.0, 48.0)
	add_child_autofree(egg_visual)
	egg_visual.set_egg({
		"kind": "cuckoo",
		"toughness": 4,
		"max_toughness": 4,
		"points": 1,
	}, true)
	await get_tree().process_frame

	assert_eq(egg_visual.mouse_filter, Control.MOUSE_FILTER_PASS)
	var card: Control = egg_visual.make_tooltip_card()
	add_child_autofree(card)
	assert_string_contains(card.card_text(), "CUCKOO.")
	assert_string_contains(card.card_text(), "copies damage")


func test_hopper_preview_hover_card_stays_in_the_same_canvas() -> void:
	var main := _add_main()
	var egg_visual: Control = main.get_node(
		"Content/Stage/Pipe/Preview/Next1/EggContent/EggVisual"
	)
	var popover: Node = egg_visual.get_node("EggHoverPopover")

	assert_false(popover is Window)
	if popover is Window:
		return
	assert_eq((popover as Control).mouse_filter, Control.MOUSE_FILTER_IGNORE)
	egg_visual.show_hover_card()
	await get_tree().process_frame
	await get_tree().process_frame
	assert_true(egg_visual.is_hover_card_visible())


func test_egg_hover_builds_a_clear_wrapped_information_card() -> void:
	var egg_visual := EggVisual.new()
	add_child_autofree(egg_visual)
	egg_visual.set_egg({
		"kind": "chicken",
		"tier": 0,
		"toughness": 3,
		"max_toughness": 3,
		"points": 3,
		"double_yolk_chance": 0.02,
	})
	assert_true(egg_visual.has_method("make_tooltip_card"))
	if not egg_visual.has_method("make_tooltip_card"):
		return
	var card: Control = egg_visual.make_tooltip_card()
	add_child_autofree(card)

	assert_string_contains(card.card_text(), "CHICKEN.")
	assert_string_contains(card.card_text(), "POINTS\n3")
	assert_string_contains(card.card_text(), "CHANCE OF DOUBLE YOLKER\n2%")
	assert_eq(card.visible_effect_sections(), [])
	assert_true(card.effect_bodies_use_word_wrap())
	assert_true(card.has_node("Margin/Stack/Facts/PointsFact"))
	assert_true(card.has_node("Margin/Stack/Facts/ChanceFact"))


func test_egg_hover_card_includes_only_applicable_effect_sections() -> void:
	var egg_visual := EggVisual.new()
	add_child_autofree(egg_visual)
	assert_true(egg_visual.has_method("make_tooltip_card"))
	if not egg_visual.has_method("make_tooltip_card"):
		return

	egg_visual.set_egg({
		"kind": "cuckoo", "points": 1, "double_yolk_chance": 0.0,
	})
	var cuckoo_card: Control = egg_visual.make_tooltip_card()
	add_child_autofree(cuckoo_card)
	assert_eq(cuckoo_card.visible_effect_sections(), ["OTHER EFFECTS"])
	assert_string_contains(cuckoo_card.card_text(), "copies damage")

	egg_visual.set_egg({
		"kind": "plover", "points": 4, "double_yolk_chance": 0.0,
	})
	var plover_card: Control = egg_visual.make_tooltip_card()
	add_child_autofree(plover_card)
	assert_eq(plover_card.visible_effect_sections(), ["ON HIT EFFECTS"])
	assert_string_contains(plover_card.card_text(), "moves one bay left")

	egg_visual.set_egg({
		"kind": "spoonbill", "points": 4, "double_yolk_chance": 0.0,
	})
	var spoonbill_card: Control = egg_visual.make_tooltip_card()
	add_child_autofree(spoonbill_card)
	assert_eq(spoonbill_card.visible_effect_sections(), ["ON HIT EFFECTS"])
	assert_string_contains(spoonbill_card.card_text(), "Pink strike deals 2 damage")


func test_main_stage_exposes_anchored_egg_hover_cards_without_blocking_levers() -> void:
	var main := _add_main_for_ordered_eggs(["cuckoo"])
	await get_tree().process_frame
	var egg_visual: Control = main.get_node(
		"Content/Stage/Belt/Slots/Slot1/EggContent/EggVisual"
	)
	var card: Control = egg_visual.make_tooltip_card()
	add_child_autofree(card)
	assert_string_contains(card.card_text(), "POINTS")
	assert_string_contains(card.card_text(), "Echo")
	assert_true(egg_visual.has_method("show_hover_card"))

	var red_lever: Button = main.get_node("Content/Stage/CircuitBank/RedCircuit")
	assert_eq(red_lever.mouse_filter, Control.MOUSE_FILTER_STOP)
	assert_eq(red_lever.tooltip_text, "")


func test_egg_hover_card_top_aligns_with_egg_and_stays_inside_viewport() -> void:
	var egg_visual := EggVisual.new()
	egg_visual.position = Vector2(320.0, 220.0)
	egg_visual.size = Vector2(132.0, 148.0)
	add_child_autofree(egg_visual)
	egg_visual.set_egg({
		"kind": "plover",
		"tier": 1,
		"points": 6,
		"double_yolk_chance": 0.075,
	})
	assert_true(egg_visual.has_method("show_hover_card"))
	assert_true(egg_visual.has_method("hover_card_rect"))
	if not egg_visual.has_method("show_hover_card") or not egg_visual.has_method("hover_card_rect"):
		return

	egg_visual.show_hover_card()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	var card_rect: Rect2 = egg_visual.hover_card_rect()
	var egg_rect := egg_visual.get_global_rect()
	var viewport_rect := egg_visual.get_viewport().get_visible_rect()
	assert_almost_eq(card_rect.position.y, egg_rect.position.y, 1.0)
	assert_true(viewport_rect.encloses(card_rect))
	assert_gt(card_rect.position.x, egg_rect.end.x)
	var popover_card: Control = egg_visual.get_node("EggHoverPopover/Card")
	assert_eq(card_rect.size, popover_card.get_combined_minimum_size())

	egg_visual.hide_hover_card()
	egg_visual.position.x = viewport_rect.end.x - egg_visual.size.x - 4.0
	egg_visual.show_hover_card()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	card_rect = egg_visual.hover_card_rect()
	egg_rect = egg_visual.get_global_rect()
	assert_almost_eq(card_rect.position.y, egg_rect.position.y, 1.0)
	assert_true(viewport_rect.encloses(card_rect))
	assert_lt(card_rect.end.x, egg_rect.position.x)


func test_flat_placeholder_machine_and_ambience_respect_reduced_motion() -> void:
	var main := _add_main()
	var stage: Control = main.get_node("Content/Stage/Workshop")
	if not stage.has_method("material_texture_count"):
		fail_test("The machine must expose its material texture integration.")
		return
	assert_eq(stage.material_texture_count(), 0)

	var cursor_spoon = load("res://src/presentation/spoon_cursor.tscn").instantiate()
	add_child_autofree(cursor_spoon)
	assert_true(cursor_spoon is Control)
	assert_false(cursor_spoon is TextureRect)

	var ambience = main.get_node_or_null("Content/Stage/Ambience")
	assert_not_null(ambience)
	if ambience == null:
		return
	assert_gt(ambience.mote_count(), 0)
	assert_true(ambience.is_motion_active())

	main.set_reduced_motion(true)
	assert_true(ambience.is_reduced_motion())
	assert_false(ambience.is_motion_active())

	main.set_reduced_motion(false)
	assert_false(ambience.is_reduced_motion())
	assert_true(ambience.is_motion_active())


func test_generated_raster_archive_is_excluded_from_game_exports() -> void:
	var export_presets := ConfigFile.new()
	assert_eq(export_presets.load("res://export_presets.cfg"), OK)
	var excludes := String(export_presets.get_value("preset.0", "exclude_filter", ""))
	assert_string_contains(excludes, "assets/generated/*")
	assert_string_contains(excludes, "docs/*")


func test_main_renders_initial_day_with_grandma_appetite_scorer() -> void:
	var main := _add_main()

	var grandma = main.get_node_or_null("Content/HUD/GrandmaScorer")
	assert_not_null(grandma)
	if grandma == null:
		return
	assert_eq(grandma.get_node("Layout/Appetite/Score").text, "APPETITE 0 / 10")
	assert_eq(grandma.appetite_ratio(), 0.0)
	assert_true(grandma.has_status_space())
	assert_true(grandma.has_dialogue_space())
	assert_true(grandma.is_idle_motion_active())
	var hud: Control = main.get_node("Content/HUD")
	var stage: Control = main.get_node("Content/Stage")
	var belt_condition: Control = main.get_node("Content/Stage/Belt/BeltCondition")
	var belt_condition_label: Label = belt_condition.get_node("BeltConditionLabel")
	var belt: Control = main.get_node("Content/Stage/Belt")
	var settings: MenuButton = main.get_node("Content/HUD/Settings")
	assert_lte(stage.position.y, 16.0)
	assert_gte(grandma.size.x, 260.0)
	assert_lte(grandma.size.x, 320.0)
	assert_gte(grandma.size.y, 650.0)
	assert_gt(grandma.get_global_rect().get_center().x, stage.get_global_rect().get_center().x)
	assert_true(belt.get_global_rect().encloses(belt_condition.get_global_rect()))
	assert_false(grandma.get_global_rect().intersects(belt_condition.get_global_rect()))
	for slot: Control in main.get_node("Content/Stage/Belt/Slots").get_children():
		assert_false(slot.get_global_rect().intersects(belt_condition.get_global_rect()))
	for circuit_button: Control in main.get_node("Content/Stage/CircuitBank").get_children():
		if circuit_button.visible:
			assert_false(circuit_button.get_global_rect().intersects(
				belt_condition.get_global_rect()
			))
	assert_true(grandma.get_global_rect().encloses(settings.get_global_rect()))
	assert_true(hud.get_global_rect().encloses(grandma.get_global_rect()))
	assert_eq(belt_condition_label.text, "BELT CONDITION  12 / 12")
	assert_eq(belt_condition.current_condition(), 12)
	assert_eq(main.get_node("Content/Stage/Pipe/HopperInspect").text, "HOPPER 3")
	assert_eq(main.get_node("Content/Stage/Belt/Bin").text, "BIN 0")
	assert_false(main.has_node("Content/Header"))
	assert_false(main.has_node("Content/FooterPlate"))
	assert_false(main.has_node("Content/Feedback"))
	assert_false(main.has_node("Content/Accessibility"))
	assert_not_null(main.get_node("Content/HUD/Settings"))
	assert_string_contains(main.get_node("Content/Stage/Belt/Slots/Slot1").egg_summary(), "SPARROW")
	assert_string_contains(main.get_node("Content/Stage/Belt/Slots/Slot1").egg_summary(), "TOUGHNESS 1")
	assert_eq(main.get_node("Content/Stage/Pipe/Preview").get_child_count(), 3)
	for preview in main.get_node("Content/Stage/Pipe/Preview").get_children():
		assert_true(preview.egg_kind() in ["chicken", "cuckoo", "sparrow"])
	assert_true(main.theme.has_stylebox("normal", "Button"))
	assert_true(main.theme.has_stylebox("checked", "CheckButton"))


func test_grandma_appetite_fill_is_proportional_and_caps_at_full() -> void:
	var grandma = load("res://src/ui/grandma_scorer.tscn").instantiate()
	add_child_autofree(grandma)
	await get_tree().process_frame

	grandma.render_appetite(3, 10, 2)
	assert_eq(grandma.get_node("Layout/Appetite/Score").text, "APPETITE 3 / 8")
	assert_almost_eq(grandma.appetite_ratio(), 0.3, 0.00001)
	assert_almost_eq(grandma.sulphurous_suppression_ratio(), 0.2, 0.00001)
	assert_almost_eq(
		grandma.get_node("Layout/GrandmaPortrait").hunger_ratio(),
		0.5,
		0.00001
	)
	var appetite_bar: Control = grandma.get_node("Layout/Appetite/YolkBar")
	var suppression_clip: Control = appetite_bar.get_node("SuppressionClip")
	assert_almost_eq(
		suppression_clip.position.x + suppression_clip.size.x,
		appetite_bar.size.x - 4.0,
		0.001
	)
	assert_gt(suppression_clip.size.x, 0.0)
	grandma.render_appetite(12, 10)
	assert_eq(grandma.get_node("Layout/Appetite/Score").text, "APPETITE 12 / 10")
	assert_eq(grandma.appetite_ratio(), 1.0)
	assert_eq(grandma.sulphurous_suppression_ratio(), 0.0)


func test_grandma_compactly_lists_each_active_egg_effect() -> void:
	var grandma = load("res://src/ui/grandma_scorer.tscn").instantiate()
	add_child_autofree(grandma)
	await get_tree().process_frame

	grandma.render_effects({
		"appetiser_charges": 2,
		"sulphurous_suppression": 4,
		"deceptively_filling_reserve": 8,
	})
	var effects: Label = grandma.get_node("Layout/Effects")
	assert_string_contains(effects.text, "APPETISER ×2 · 2 EGGS")
	assert_string_contains(effects.text, "SULPHUROUS · −4 APPETITE THIS DAY")
	assert_string_contains(effects.text, "FILLING · 8 YOLK LEFT")
	assert_string_contains(effects.accessibility_name, "two Appetiser charges")

	grandma.render_effects({
		"appetiser_charges": 0,
		"sulphurous_suppression": 0,
		"deceptively_filling_reserve": 0,
	})
	assert_eq(effects.text, "NO ACTIVE EGG EFFECTS")


func test_resolved_appetiser_updates_grandmas_persistent_status() -> void:
	var session = ChickenDaySession.new(
		0,
		ProducerFlock.new([{"kind": "sparrow"}, {"kind": "chicken"}]),
		EffectInjectingShuffler.new("appetiser")
	)
	var main := _add_main()
	main.replace_session(session)
	main.set_reduced_motion(true)

	await _press_and_wait(main, "RedCircuit")

	var effects: Label = main.get_node("Content/HUD/GrandmaScorer/Layout/Effects")
	assert_eq(effects.text, "APPETISER ×2 · NEXT EGG")
	assert_false(main.is_input_locked())


func test_resolved_sulphurous_permanently_suppresses_the_visible_appetite() -> void:
	var session = ChickenDaySession.new(
		0,
		ProducerFlock.new([{"kind": "sparrow"}, {"kind": "chicken"}]),
		EffectInjectingShuffler.new("sulphurous")
	)
	var main := _add_main()
	main.replace_session(session)
	main.set_reduced_motion(true)
	var presented: Array[String] = []
	main.presentation_event.connect(
		func(event_type: String) -> void: presented.append(event_type)
	)

	await _press_and_wait(main, "RedCircuit")

	var grandma: Control = main.get_node("Content/HUD/GrandmaScorer")
	assert_eq(grandma.get_node("Layout/Appetite/Score").text, "APPETITE 1 / 8")
	assert_almost_eq(grandma.sulphurous_suppression_ratio(), 0.2, 0.00001)
	assert_eq(
		grandma.get_node("Layout/Effects").text,
		"SULPHUROUS · −2 APPETITE THIS DAY"
	)
	assert_lt(presented.find("grandma_effect_activated"), presented.find("conveyor_advanced"))
	assert_false(main.is_input_locked())


func test_shockwave_event_plays_before_the_single_conveyor_advance() -> void:
	var session = ChickenDaySession.new(
		0,
		ProducerFlock.new([{"kind": "sparrow"}, {"kind": "chicken"}]),
		EffectInjectingShuffler.new("shockwave")
	)
	var main := _add_main()
	main.replace_session(session)
	main.set_reduced_motion(true)
	var presented: Array[String] = []
	main.presentation_event.connect(
		func(event_type: String) -> void: presented.append(event_type)
	)

	await _press_and_wait(main, "RedCircuit")

	assert_lt(presented.find("shockwave_fired"), presented.find("conveyor_advanced"))
	assert_eq(presented.count("conveyor_advanced"), 1)
	assert_false(main.is_input_locked())


func test_reduced_motion_stops_grandma_idle_animation() -> void:
	var main := _add_main()
	var grandma = main.get_node("Content/HUD/GrandmaScorer")

	main.set_reduced_motion(true)
	assert_false(grandma.is_idle_motion_active())
	main.set_reduced_motion(false)
	assert_true(grandma.is_idle_motion_active())


func test_hopper_lift_places_the_next_egg_closest_to_its_upper_exit() -> void:
	var main := _add_main()
	var previews: Array[Node] = main.get_node("Content/Stage/Pipe/Preview").get_children()
	var hopper_inspect: Button = main.get_node("Content/Stage/Pipe/HopperInspect")
	var bin_inspect: Button = main.get_node("Content/Stage/Belt/BinInspect")

	assert_eq(previews.size(), 3)
	assert_lt((previews[0] as Control).position.y, (previews[1] as Control).position.y)
	assert_lt((previews[1] as Control).position.y, (previews[2] as Control).position.y)
	assert_gt(
		hopper_inspect.get_global_rect().get_center().y,
		(previews[2] as Control).get_global_rect().get_center().y
	)
	assert_almost_eq(
		hopper_inspect.get_global_rect().end.y,
		bin_inspect.get_global_rect().end.y,
		6.0
	)


func test_hopper_preview_eggs_are_compact_and_open_anchored_popovers() -> void:
	var main := _add_main()
	var preview: Control = main.get_node("Content/Stage/Pipe/Preview/Next1")
	var preview_content: Control = preview.get_node("EggContent")
	var belt_content: Control = main.get_node(
		"Content/Stage/Belt/Slots/Slot1/EggContent"
	)
	var egg_visual: Control = preview.get_node("EggContent/EggVisual")

	assert_lt(preview_content.scale.x, belt_content.scale.x)
	assert_lt(preview_content.scale.y, belt_content.scale.y)
	assert_eq(main.get_node("Content/Stage/Pipe").mouse_filter, Control.MOUSE_FILTER_IGNORE)
	assert_eq(
		main.get_node("Content/Stage/Pipe/Preview").mouse_filter,
		Control.MOUSE_FILTER_IGNORE
	)
	assert_eq(
		main.get_node("Content/Stage/Belt/Slots").mouse_filter,
		Control.MOUSE_FILTER_IGNORE
	)
	assert_eq(egg_visual.mouse_filter, Control.MOUSE_FILTER_PASS)

	egg_visual.show_hover_card()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	assert_true(egg_visual.is_hover_card_visible())
	var card_rect: Rect2 = egg_visual.hover_card_rect()
	assert_true(egg_visual.get_viewport().get_visible_rect().encloses(card_rect))
	assert_gt(card_rect.position.x, egg_visual.get_global_rect().end.x)


func test_hopper_deck_displays_count_and_opens_an_unordered_egg_collection() -> void:
	var main := _add_main_for_ordered_eggs([
		"chicken", "chicken", "chicken", "chicken", "chicken",
		"spoonbill", "plover", "cuckoo", "sparrow",
	])
	var hopper_button: Button = main.get_node("Content/Stage/Pipe/HopperInspect")
	var inspector = main.get_node("ContainerInspector")

	assert_eq(hopper_button.text, "HOPPER 4")
	assert_gte(hopper_button.size.x, 200.0)
	assert_gte(hopper_button.size.y, 40.0)
	assert_false(hopper_button.tooltip_text.to_upper().contains("ORDER"))
	assert_eq(hopper_button.accessibility_name, "Inspect hopper: 4 eggs remaining")
	hopper_button.pressed.emit()
	await get_tree().process_frame

	assert_true(inspector.visible)
	assert_eq(inspector.container_kind(), "hopper")
	assert_eq(inspector.egg_count(), 4)
	assert_eq(inspector.egg_kinds(), ["cuckoo", "plover", "sparrow", "spoonbill"])
	assert_eq(inspector.position_labels(), [])
	assert_eq(inspector.hopper_tile_count(), 4)
	assert_string_contains(inspector.heading_text(), "HOPPER • 4 EGGS")
	assert_eq(inspector.guidance_text(), "")
	assert_false(inspector.all_visible_text().contains("NEXT"))
	assert_false(inspector.all_visible_text().contains("ORDER"))
	assert_true(inspector.get_node("Panel/Margin/Stack/Close").has_focus())
	inspector.close_requested.emit()
	await get_tree().process_frame
	assert_false(inspector.visible)
	assert_true(hopper_button.has_focus())


func test_bin_click_opens_every_stored_egg_with_retained_toughness() -> void:
	var main := _add_main_for_ordered_eggs([
		"chicken", "chicken", "chicken", "chicken", "spoonbill", "chicken", "chicken",
	])
	main.set_reduced_motion(true)
	await _press_and_wait(main, "PinkCircuit")
	var bin_button: Button = main.get_node("Content/Stage/Belt/BinInspect")
	var inspector = main.get_node("ContainerInspector")

	assert_eq(main.get_node("Content/Stage/Belt/Bin").text, "BIN 1")
	assert_eq(bin_button.accessibility_name, "Inspect bin: 1 egg stored")
	bin_button.pressed.emit()
	await get_tree().process_frame

	assert_true(inspector.visible)
	assert_eq(inspector.container_kind(), "bin")
	assert_eq(inspector.egg_count(), 1)
	assert_eq(inspector.egg_kinds(), ["spoonbill"])
	assert_eq(inspector.egg_at(0).toughness, 3)
	assert_eq(inspector.position_labels(), ["STORED 1"])
	assert_string_contains(inspector.guidance_text(), "RETURN ORDER SHUFFLES")
	assert_false(inspector.all_visible_text().contains("IS DOUBLE YOLKER"))


func test_empty_bin_remains_clickable_and_reports_that_it_is_empty() -> void:
	var main := _add_main()
	var bin_button: Button = main.get_node("Content/Stage/Belt/BinInspect")
	var inspector = main.get_node("ContainerInspector")

	assert_false(bin_button.disabled)
	bin_button.pressed.emit()
	await get_tree().process_frame

	assert_true(inspector.visible)
	assert_eq(inspector.egg_count(), 0)
	assert_eq(inspector.empty_text(), "THE BIN IS EMPTY")


func test_mature_machine_layout_uses_the_stage_for_play_and_existing_controls() -> void:
	var main := _add_main()
	assert_true(main.start_dev_day(3))
	await get_tree().process_frame

	var hud: Control = main.get_node("Content/HUD")
	var stage: Control = main.get_node("Content/Stage")
	assert_false(main.has_node("Content/Header"))
	assert_false(main.has_node("Content/FooterPlate"))
	assert_false(main.has_node("Content/Feedback"))
	assert_true(hud.get_global_rect().intersects(stage.get_global_rect()))
	assert_gt(stage.get_global_rect().end.y, 700.0)
	var grandma: Control = main.get_node("Content/HUD/GrandmaScorer")
	var machine = main.get_node("Content/Stage/Workshop")
	var pipe: Control = main.get_node("Content/Stage/Pipe")
	var first_slot: Control = main.get_node("Content/Stage/Belt/Slots/Slot1")
	var first_hammer: Control = main.get_node("Content/Stage/HammerBank/Hammer1")
	var bin_button: Control = main.get_node("Content/Stage/Belt/BinInspect")
	assert_true(machine.uses_curved_bin_exit())
	assert_eq(machine.hopper_outlet_global_position(), machine.conveyor_entry_global_position())
	assert_gte(pipe.size.x, 185.0)
	assert_gte(pipe.size.y, 300.0)
	assert_almost_eq(pipe.get_global_rect().end.y, bin_button.get_global_rect().end.y, 1.0)
	assert_gt(first_slot.position.x, pipe.get_global_rect().end.x - stage.global_position.x)
	assert_gte(first_slot.position.y, 250.0)
	assert_gt(first_slot.stage_content_scale(), 1.0)
	assert_gte(
		first_hammer.pivot_global_position().y
			- first_hammer.stored_bowl_global_position().y,
		110.0
	)
	assert_gte(bin_button.size.x, 130.0)
	assert_gte(bin_button.size.y, 170.0)
	for circuit_button: Control in main.get_node("Content/Stage/CircuitBank").get_children():
		if circuit_button.visible:
			assert_true(stage.get_global_rect().encloses(circuit_button.get_global_rect()))
			assert_false(grandma.get_global_rect().intersects(circuit_button.get_global_rect()))
			assert_gte(circuit_button.size.y, 170.0)
			assert_lte(circuit_button.size.y, 210.0)
			assert_gt(circuit_button.get_global_rect().end.y, 670.0)


func test_debug_mode_can_replace_the_run_with_a_fresh_day_three() -> void:
	var main := _add_main()

	assert_true(InputMap.has_action("dev_start_day_3"))
	assert_true(main.start_dev_day(3))

	assert_true(main.is_dev_mode())
	assert_eq(main.dev_day_number(), 3)
	assert_eq(main.get_node("Content/HUD/GrandmaScorer/Layout/Appetite/Score").text, "APPETITE 0 / 9")
	assert_eq(main.get_node("Content/Stage/Belt/BeltCondition/BeltConditionLabel").text, "BELT CONDITION  12 / 12")
	assert_eq(main.get_node("Content/Stage/Belt/Slots").get_child_count(), 5)
	assert_eq(main.get_node("Content/Stage/CircuitBank").get_child_count(), 3)

	main.restart_day()

	assert_eq(main.dev_day_number(), 3)
	assert_eq(main.get_node("Content/HUD/GrandmaScorer/Layout/Appetite/Score").text, "APPETITE 0 / 9")


func test_debug_settings_picker_starts_with_the_selected_egg_species() -> void:
	var main := _add_main()
	var settings_popup: PopupMenu = main.get_node("Content/HUD/Settings").get_popup()
	var picker: Control = main.get_node("DevEggPicker")
	var dev_item_index := settings_popup.get_item_index(2)

	assert_true(InputMap.has_action("dev_choose_eggs"))
	assert_gte(dev_item_index, 0)
	assert_eq(settings_popup.get_item_text(dev_item_index), "CHOOSE STARTING EGGS…   F4")
	settings_popup.id_pressed.emit(2)
	assert_true(picker.visible)
	assert_eq(picker.total_egg_count(), 8)
	assert_eq(picker.starting_belt_condition(), 12)

	picker.set_egg_order(["kiwi", "quail", "ostrich"])
	picker.move_egg(2, 0)
	picker.set_starting_belt_condition(18)
	picker.submit_selection()

	assert_false(picker.visible)
	assert_true(main.is_dev_mode())
	assert_eq(main.dev_starting_egg_kinds(), ["ostrich", "kiwi", "quail"])
	assert_eq(main.dev_starting_belt_condition(), 18)
	assert_eq(main.dev_day_number(), 3)
	assert_eq(main.get_node("Content/HUD/GrandmaScorer/Layout/Appetite/Score").text, "APPETITE 0 / 9")
	assert_eq(main.get_node("Content/Stage/Belt/BeltCondition/BeltConditionLabel").text, "BELT CONDITION  18 / 18")
	assert_eq(main.get_node("Content/Stage/Belt/Slots/Slot1").current_egg().kind, "ostrich")

	main.restart_day()
	assert_eq(main.get_node("Content/Stage/Belt/BeltCondition/BeltConditionLabel").text, "BELT CONDITION  18 / 18")
	assert_eq(main.get_node("Content/Stage/Belt/Slots/Slot1").current_egg().kind, "ostrich")


func test_dev_egg_picker_fits_default_and_constrained_viewports() -> void:
	var default_eggs: Array[String] = [
		"chicken", "chicken", "chicken", "cuckoo",
		"cuckoo", "sparrow", "sparrow", "sparrow",
	]
	for viewport_size: Vector2i in [Vector2i(1280, 720), Vector2i(1024, 576)]:
		var viewport := SubViewport.new()
		viewport.size = viewport_size
		add_child_autofree(viewport)
		var picker = load("res://src/ui/dev_egg_picker.tscn").instantiate()
		viewport.add_child(picker)
		await get_tree().process_frame
		picker.open_with(default_eggs)
		await get_tree().process_frame

		var viewport_rect := Rect2(Vector2.ZERO, Vector2(viewport_size))
		var panel: PanelContainer = picker.get_node("Panel")
		assert_true(viewport_rect.encloses(panel.get_rect()))
		assert_true(panel.get_global_rect().encloses(
			picker.get_node("Panel/Margin/Layout/Actions/Start").get_global_rect()
		))
		assert_eq(
			picker.get_node("Panel/Margin/Layout/Body/Species/SpeciesButtons").get_child_count(),
			9
		)
		assert_eq(picker.total_egg_count(), 8)


func test_plover_shell_information_shows_the_four_point_payoff() -> void:
	var main := _add_main_for_ordered_eggs(["plover"])
	var slot = main.get_node("Content/Stage/Belt/Slots/Slot1")
	var summary: String = slot.egg_summary()

	assert_string_contains(summary, "TOUGHNESS 6")
	assert_string_contains(summary, "4 POINTS")
	assert_eq(slot.effect_emblem(), "screen_left")


func test_quality_egg_shows_its_tier_and_floored_gameplay_score() -> void:
	var flock = ProducerFlock.new([{"kind": "chicken", "tier": 1}])
	var session = ChickenDaySession.new(42, flock, IdentityShuffler.new())
	var main := _add_main()
	main.replace_session(session)
	var slot = main.get_node("Content/Stage/Belt/Slots/Slot1")

	assert_eq(slot.current_egg().tier, 1)
	assert_almost_eq(float(slot.current_egg().exact_base_points), 4.5, 0.00001)
	assert_eq(slot.current_egg().max_toughness, 5)
	assert_almost_eq(float(slot.current_egg().exact_max_toughness), 4.5, 0.00001)
	assert_string_contains(slot.egg_summary(), "TOUGHNESS 5")
	assert_string_contains(slot.egg_summary(), "4 POINTS")
	assert_false(slot.egg_summary().contains("4.5"))
	assert_string_contains(slot.egg_description(), "Prize")
	assert_eq(slot.quality_tier(), 1)
	assert_eq(slot.quality_ring_count(), 1)


func test_fallen_egg_visibly_recycles_with_its_damage_intact() -> void:
	var flock = ProducerFlock.new([{"kind": "spoonbill", "tier": 1}])
	var session = ChickenDaySession.new(42, flock, IdentityShuffler.new())
	var main := _add_main()
	main.replace_session(session)
	main.set_reduced_motion(true)
	var presented: Array[String] = []
	main.presentation_event.connect(func(event_type: String) -> void: presented.append(event_type))

	for circuit_name in ["RedCircuit", "BlueCircuit", "RedCircuit", "BlueCircuit", "PinkCircuit"]:
		await _press_and_wait(main, circuit_name)

	assert_true(presented.has("egg_binned"))
	assert_true(presented.has("bin_reshuffled"))
	assert_lt(presented.find("egg_binned"), presented.find("bin_reshuffled"))
	assert_lt(presented.find("bin_reshuffled"), presented.find("egg_entered"))
	assert_eq(main.get_node("Content/Stage/Belt/Bin").text, "BIN 0")
	var recycled_egg: Dictionary = main.get_node(
		"Content/Stage/Belt/Slots/Slot1"
	).current_egg()
	assert_eq(recycled_egg.kind, "spoonbill")
	assert_eq(recycled_egg.toughness, 2)
	assert_eq(recycled_egg.max_toughness, 8)


func test_stage_colours_belt_sections_and_keeps_five_spoons_neutral() -> void:
	var main := _add_main()
	var circuits := main.get_node("Content/Stage/CircuitBank")
	var hammers := main.get_node("Content/Stage/HammerBank")
	var slots := main.get_node("Content/Stage/Belt/Slots")
	var machine_stage := main.get_node("Content/Stage/Workshop")

	assert_eq(circuits.get_child_count(), 3)
	assert_eq(hammers.get_child_count(), 5)
	assert_eq(hammers.get_children().filter(func(control: Control) -> bool:
		return control.visible
	).size(), 5)
	assert_eq(circuits.get_node("RedCircuit").circuit_id, "red")
	assert_eq(circuits.get_node("RedCircuit").slot_indices, [0, 2])
	assert_eq(circuits.get_node("RedCircuit").circuit_symbol, "diamond")
	assert_eq(circuits.get_node("BlueCircuit").slot_indices, [1, 3])
	assert_eq(circuits.get_node("BlueCircuit").circuit_symbol, "circle")
	assert_eq(circuits.get_node("PinkCircuit").slot_indices, [4])
	assert_eq(circuits.get_node("PinkCircuit").circuit_symbol, "spark")
	var expected_slot_circuits := ["red", "blue", "red", "blue", "pink"]
	for slot_index in range(5):
		var slot: Control = slots.get_node("Slot%d" % (slot_index + 1))
		assert_eq(slot.circuit_id(), expected_slot_circuits[slot_index])
		assert_gt(slot.circuit_color().a, 0.9)
		assert_eq(machine_stage.belt_section_circuit_id(slot_index), expected_slot_circuits[slot_index])
	for hammer: Control in hammers.get_children():
		assert_false(hammer.is_circuit_marked())
	for circuit_lever: Button in circuits.get_children():
		assert_eq(circuit_lever.control_form(), "lever")
		assert_eq(circuit_lever.text, "")


func test_circuit_lever_has_a_clear_mechanical_throw_and_resets_to_idle() -> void:
	var main := _add_main()
	var lever: Button = main.get_node("Content/Stage/CircuitBank/RedCircuit")
	var idle_handle: Vector2 = lever.lever_handle_center()

	lever.set_press_amount(1.0)
	var pulled_handle: Vector2 = lever.lever_handle_center()

	assert_gt(pulled_handle.x, idle_handle.x)
	assert_gt(pulled_handle.y, idle_handle.y)
	assert_gt(idle_handle.distance_to(pulled_handle), 30.0)
	lever.reset_pose()
	assert_eq(lever.press_amount, 0.0)
	assert_eq(lever.lever_handle_center(), idle_handle)
	assert_eq(lever.mapping_text(), "1+3")


func test_focused_lever_highlights_its_linked_belt_sections() -> void:
	var main := _add_main()
	var stage = main.get_node("Content/Stage/Workshop")
	var red: Button = main.get_node("Content/Stage/CircuitBank/RedCircuit")

	assert_true(red.has_focus())
	assert_eq(stage.highlighted_circuit_id(), "red")

	main.set_reduced_motion(true)
	await _press_and_wait(main, "RedCircuit")
	var blue: Button = main.get_node("Content/Stage/CircuitBank/BlueCircuit")
	assert_false(blue.disabled)
	blue.grab_focus()
	await get_tree().process_frame

	assert_eq(stage.highlighted_circuit_id(), "blue")


func test_early_line_spoons_are_wall_pinned_behind_eggs_and_tip_bowl_first() -> void:
	var main := _add_main()
	var hammers := main.get_node("Content/Stage/HammerBank")
	var slots := main.get_node("Content/Stage/Belt/Slots")

	for slot_index in range(5):
		var hammer = hammers.get_node("Hammer%d" % (slot_index + 1))
		var slot: Control = slots.get_node("Slot%d" % (slot_index + 1))
		var impact: Vector2 = slot.impact_global_position()
		var hinge: Vector2 = hammer.pivot_global_position()
		var stored_bowl: Vector2 = hammer.stored_bowl_global_position()
		var contact_bowl: Vector2 = hammer.contact_bowl_global_position()

		assert_true(hammer.is_wall_pinned_spoon())
		assert_true(hammer.uses_authored_landing_frames())
		assert_eq(hammer.landing_frame_count(), 9)
		assert_true(slot.is_bare_belt_mode())
		assert_almost_eq(stored_bowl.x, impact.x, 1.0)
		assert_almost_eq(hinge.x, impact.x, 1.0)
		assert_lt(stored_bowl.y, hinge.y)
		assert_lt(hinge.y, impact.y)
		assert_lte(impact.y - hinge.y, 18.0)
		assert_almost_eq(contact_bowl.x, impact.x, 1.0)
		assert_almost_eq(contact_bowl.y, impact.y, 1.0)
		assert_lt(hammer.stored_bowl_screen_size().x, hammer.stored_bowl_screen_size().y)
		assert_gt(hammer.contact_bowl_screen_size().x, hammer.contact_bowl_screen_size().y * 3.0)
		assert_gte(hammer.contact_bowl_screen_size().y, 26.0)

		hammer.set_strike_amount(0.50)
		assert_eq(hammer.landing_frame_index(), 4)
		assert_lt(
			hammer.current_bowl_global_positions()[0].distance_to(hinge),
			2.0
		)
		var edge_visual: Dictionary = hammer.bowl_visuals()[0]
		assert_gt(edge_visual.radii.x, edge_visual.radii.y * 2.5)
		assert_eq(hammer.z_index, 0)
		assert_gt(hammer.bowl_foreground_z_index(), main.get_node("Content/Stage/Belt").z_index)

		hammer.set_strike_amount(1.0)
		assert_eq(hammer.landing_frame_index(), 8)
		assert_eq(hammer.z_index, 0)
		assert_gt(hammer.bowl_foreground_z_index(), main.get_node("Content/Stage/Belt").z_index)
		hammer.reset_pose()


func test_all_circuits_are_available_during_an_unlocked_day() -> void:
	var main := _add_main()
	var red: Button = main.get_node("Content/Stage/CircuitBank/RedCircuit")
	var blue: Button = main.get_node("Content/Stage/CircuitBank/BlueCircuit")
	var pink: Button = main.get_node("Content/Stage/CircuitBank/PinkCircuit")

	assert_false(red.disabled)
	assert_false(blue.disabled)
	assert_false(pink.disabled)
	assert_true(red.has_focus())


func test_circuit_levers_have_no_hover_text_and_describe_connections_accessibly() -> void:
	var main := _add_main()
	var red: Button = main.get_node("Content/Stage/CircuitBank/RedCircuit")
	var pink: Button = main.get_node("Content/Stage/CircuitBank/PinkCircuit")

	assert_eq(red.tooltip_text, "")
	assert_eq(red.accessibility_name, "Red diamond lever")
	assert_string_contains(red.accessibility_description, "slots 1 and 3")
	assert_string_contains(red.accessibility_description, "Slot 1: Sparrow egg")
	assert_string_contains(red.accessibility_description, "Slot 3: Sparrow egg")
	assert_eq(pink.accessibility_name, "Pink spark lever")


func test_red_fires_both_connected_spoons_even_when_one_slot_is_empty() -> void:
	var main := _add_main_for_ordered_eggs([
		"chicken", "cuckoo",
	])
	main.set_reduced_motion(true)
	var fired_slots: Array[int] = []
	main.get_node("Presentation").hammer_fired.connect(
		func(slot_index: int) -> void: fired_slots.append(slot_index)
	)

	await _press_and_wait(main, "RedCircuit")

	assert_eq(fired_slots, [0, 2])
	assert_eq(main.get_node("Content/Stage/Belt/BeltCondition/BeltConditionLabel").text, "BELT CONDITION  11 / 12")
	assert_eq(main.get_node("Content/Stage/Pipe/HopperInspect").text, "HOPPER 0")
	assert_string_contains(main.get_node("Content/Stage/Belt/Slots/Slot2").egg_summary(), "TOUGHNESS 2")


func test_empty_blue_strike_fires_advances_and_spends_one_belt_condition() -> void:
	var main := _add_main_for_ordered_eggs([
		"chicken",
	])
	main.set_reduced_motion(true)
	var fired_slots: Array[int] = []
	var presented: Array[String] = []
	main.get_node("Presentation").hammer_fired.connect(
		func(slot_index: int) -> void: fired_slots.append(slot_index)
	)
	main.presentation_event.connect(func(event_type: String) -> void: presented.append(event_type))

	await _press_and_wait(main, "BlueCircuit")

	assert_eq(fired_slots, [1, 3])
	assert_eq(presented, [
		"circuit_fired",
		"conveyor_advanced",
		"belt_condition_spent",
	])
	assert_eq(main.get_node("Content/Stage/Belt/BeltCondition/BeltConditionLabel").text, "BELT CONDITION  11 / 12")
	assert_eq(main.get_node("Content/Stage/Pipe/HopperInspect").text, "HOPPER 0")
	assert_string_contains(main.get_node("Content/Stage/Belt/Slots/Slot2").egg_summary(), "TOUGHNESS 3")


func test_hopper_lift_rises_while_the_next_egg_feeds_the_belt() -> void:
	var main := _add_main_for_ordered_eggs([
		"chicken", "cuckoo", "chicken", "cuckoo", "chicken",
		"chicken", "cuckoo", "chicken",
	])
	main.set_reduced_motion(false)
	var previews: Array[Node] = main.get_node("Content/Stage/Pipe/Preview").get_children()
	var second_origin_y: float = previews[1].motion_content().position.y
	var third_origin_y: float = previews[2].motion_content().position.y
	var conveyor_presented := [false]
	main.presentation_event.connect(func(event_type: String) -> void:
		if event_type == "conveyor_advanced":
			conveyor_presented[0] = true
	)

	main.get_node("Content/Stage/CircuitBank/BlueCircuit").pressed.emit()
	for _frame_index in range(120):
		if conveyor_presented[0]:
			break
		await get_tree().process_frame
	assert_true(conveyor_presented[0])
	if not conveyor_presented[0]:
		return
	for _frame_index in range(120):
		if (
			previews[1].motion_content().position.y < second_origin_y
			and previews[2].motion_content().position.y < third_origin_y
		):
			break
		await get_tree().process_frame
	assert_lt(previews[1].motion_content().position.y, second_origin_y)
	assert_lt(previews[2].motion_content().position.y, third_origin_y)
	await main.playback_completed
	await get_tree().process_frame
	assert_eq(previews[1].motion_content().position, Vector2.ZERO)
	assert_eq(previews[2].motion_content().position, Vector2.ZERO)


func test_moving_eggs_sway_and_the_hopper_feed_lifts_before_pushing_sideways() -> void:
	var main := _add_main_for_ordered_eggs([
		"chicken", "cuckoo", "chicken", "cuckoo", "chicken",
		"chicken", "cuckoo", "chicken",
	])
	main.set_reduced_motion(false)
	var next_content: Control = main.get_node(
		"Content/Stage/Pipe/Preview/Next1"
	).motion_content()
	var belt_contents: Array[Control] = []
	for slot: Button in main.get_node("Content/Stage/Belt/Slots").get_children():
		belt_contents.append(slot.motion_content())
	var circuit_presented := [false]
	var conveyor_presented := [false]
	var entry_presented := [false]
	var saw_belt_sway := false
	var saw_lift_before_push := false
	var saw_feed_sway := false
	var strongest_belt_lean := 0.0
	var feed_backward_lean := 0.0
	main.presentation_event.connect(func(event_type: String) -> void:
		if event_type == "circuit_fired":
			circuit_presented[0] = true
		elif event_type == "conveyor_advanced":
			conveyor_presented[0] = true
		elif event_type == "egg_entered":
			entry_presented[0] = true
	)

	main.get_node("Content/Stage/CircuitBank/BlueCircuit").pressed.emit()
	for _frame_index in range(240):
		await get_tree().process_frame
		if circuit_presented[0] and not conveyor_presented[0]:
			saw_belt_sway = saw_belt_sway or belt_contents.any(
				func(content: Control) -> bool: return absf(content.rotation) > 0.004
			)
			for content: Control in belt_contents:
				strongest_belt_lean = maxf(strongest_belt_lean, absf(content.rotation))
		if conveyor_presented[0] and not entry_presented[0]:
			var feed_offset := next_content.position
			feed_backward_lean = minf(feed_backward_lean, next_content.rotation)
			saw_lift_before_push = saw_lift_before_push or (
				feed_offset.y < -5.0 and absf(feed_offset.x) < 4.0
			)
			saw_feed_sway = saw_feed_sway or (
				feed_offset.x > 8.0 and absf(next_content.rotation) > 0.004
			)
		if entry_presented[0]:
			break

	assert_true(saw_belt_sway)
	assert_true(saw_lift_before_push)
	assert_true(saw_feed_sway)
	assert_gt(strongest_belt_lean, 0.06)
	assert_lt(feed_backward_lean, -0.025)
	assert_true(entry_presented[0])
	for _frame_index in range(30):
		if not main.is_input_locked():
			break
		await get_tree().process_frame
	await get_tree().process_frame
	assert_false(main.is_input_locked())
	assert_eq(next_content.position, Vector2.ZERO)
	assert_eq(next_content.rotation, 0.0)


func test_replacing_the_session_cancels_hopper_feed_sway_without_a_stale_pose() -> void:
	var main := _add_main_for_ordered_eggs([
		"chicken", "cuckoo", "chicken", "cuckoo", "chicken",
		"chicken", "cuckoo", "chicken",
	])
	main.set_reduced_motion(false)
	var next_content: Control = main.get_node(
		"Content/Stage/Pipe/Preview/Next1"
	).motion_content()
	var saw_feed_sway := false

	main.get_node("Content/Stage/CircuitBank/BlueCircuit").pressed.emit()
	for _frame_index in range(240):
		await get_tree().process_frame
		if next_content.position.x > 8.0 and absf(next_content.rotation) > 0.004:
			saw_feed_sway = true
			break

	assert_true(saw_feed_sway)
	main.replace_session(ChickenDaySession.new())
	await get_tree().process_frame
	assert_false(main.is_input_locked())
	assert_eq(next_content.position, Vector2.ZERO)
	assert_eq(next_content.rotation, 0.0)


func test_circuit_event_and_damage_are_presented_before_the_belt_advances() -> void:
	var main := _add_main_for_ordered_eggs([
		"chicken", "chicken",
	])
	main.set_reduced_motion(true)
	var presented: Array[String] = []
	main.presentation_event.connect(func(event_type: String) -> void: presented.append(event_type))

	await _press_and_wait(main, "RedCircuit")

	assert_eq(presented, [
		"circuit_fired",
		"egg_damaged",
		"conveyor_advanced",
		"belt_condition_spent",
	])


func test_original_spoon_rebounds_before_the_egg_damage_response() -> void:
	var main := _add_main()
	main.set_reduced_motion(true)
	var red_spoon: Control = main.get_node("Content/Stage/HammerBank/Hammer1")
	var strike_amounts_during_damage: Array[float] = []
	main.presentation_event.connect(func(event_type: String) -> void:
		if event_type == "egg_damaged":
			strike_amounts_during_damage.append(red_spoon.strike_amount)
	)

	await _press_and_wait(main, "RedCircuit")

	assert_false(strike_amounts_during_damage.is_empty())
	assert_true(strike_amounts_during_damage.all(func(amount: float) -> bool:
		return is_zero_approx(amount)
	))
	assert_eq(red_spoon.strike_amount, 0.0)
	assert_false(main.is_input_locked())


func test_second_circuit_press_is_ignored_while_presentation_barrier_is_active() -> void:
	var main := _add_main_for_ordered_eggs([
		"chicken", "cuckoo", "chicken", "cuckoo", "chicken",
	])
	var red: Button = main.get_node("Content/Stage/CircuitBank/RedCircuit")
	var completion_count := [0]
	var condition_spend_count := [0]
	main.playback_completed.connect(func() -> void: completion_count[0] += 1)
	main.presentation_event.connect(func(event_type: String) -> void:
		if event_type == "belt_condition_spent":
			condition_spend_count[0] += 1
	)

	red.pressed.emit()
	red.pressed.emit()

	assert_true(main.is_input_locked())
	assert_true(main.get_node("Content/Stage/Pipe/HopperInspect").disabled)
	assert_true(main.get_node("Content/Stage/Belt/BinInspect").disabled)
	await main.playback_completed
	await get_tree().process_frame
	assert_eq(main.get_node("Content/Stage/Belt/BeltCondition/BeltConditionLabel").text, "BELT CONDITION  11 / 12")
	assert_eq(completion_count[0], 1)
	assert_eq(condition_spend_count[0], 1)
	assert_false(main.get_node("Content/Stage/Pipe/HopperInspect").disabled)
	assert_false(main.get_node("Content/Stage/Belt/BinInspect").disabled)


func test_red_pair_presents_two_cuckoo_echoes_before_hatching_and_advancing() -> void:
	var main := _add_main_for_ordered_eggs([
		"sparrow", "cuckoo", "sparrow", "chicken", "chicken", "chicken",
	], 99)
	main.set_reduced_motion(true)
	var presented: Array[String] = []
	main.presentation_event.connect(func(event_type: String) -> void: presented.append(event_type))

	await _press_and_wait(main, "RedCircuit")

	assert_eq(presented.slice(0, 8), [
		"circuit_fired",
		"egg_damaged",
		"egg_damaged",
		"egg_damaged",
		"egg_damaged",
		"egg_hatched",
		"egg_hatched",
		"conveyor_advanced",
	])
	assert_eq(main.get_node("Content/HUD/GrandmaScorer/Layout/Appetite/Score").text, "APPETITE 2 / 10")


func test_hatch_burst_carries_resolved_points_into_the_score_before_event_completion() -> void:
	var main := _add_main_for_ordered_eggs(["sparrow"], 99)
	main.set_reduced_motion(false)
	var presenter := main.get_node("Presentation")
	var payoff := main.get_node("Content/HatchPayoff")
	var milestones: Array[String] = []
	var score_when_burst_started := [""]
	var point_text_when_burst_started := [""]
	presenter.hatch_payoff_started.connect(
		func(_slot_index: int, _points_awarded: int) -> void:
			score_when_burst_started[0] = main.get_node("Content/HUD/GrandmaScorer/Layout/Appetite/Score").text
			point_text_when_burst_started[0] = payoff.point_text()
			milestones.append("burst")
	)
	presenter.score_committed.connect(
		func(points_awarded: int, score: int) -> void:
			milestones.append("score:%d:%d" % [points_awarded, score])
	)
	main.presentation_event.connect(
		func(event_type: String) -> void:
			if event_type == "egg_hatched":
				milestones.append("event")
	)

	await _press_and_wait(main, "RedCircuit")

	assert_eq(score_when_burst_started[0], "APPETITE 0 / 10")
	assert_eq(point_text_when_burst_started[0], "+1")
	assert_gte(payoff.fragment_count(), 12)
	assert_eq(milestones, ["burst", "score:1:1", "event"])
	assert_eq(main.get_node("Content/HUD/GrandmaScorer/Layout/Appetite/Score").text, "APPETITE 1 / 10")
	assert_false(payoff.is_active())


func test_double_yolker_outcomes_remain_hidden_while_hover_card_shows_known_chance() -> void:
	var flock = ProducerFlock.new([
		{"kind": "chicken"}, {"kind": "chicken"}, {"kind": "chicken"},
		{"kind": "chicken"}, {"kind": "chicken"}, {"kind": "chicken"},
		{"kind": "chicken"}, {"kind": "chicken"},
	])
	var session = ChickenDaySession.new(42, flock, IdentityShuffler.new())
	var main := _add_main()
	main.replace_session(session)
	var first_slot = main.get_node("Content/Stage/Belt/Slots/Slot1")

	assert_eq(float(first_slot.current_egg().double_yolk_chance), 0.02)
	assert_false(first_slot.egg_summary().contains("DOUBLE"))
	assert_false(first_slot.egg_summary().contains("1 IN"))
	assert_false(first_slot.egg_summary().contains("10%"))
	assert_false(first_slot.egg_description().contains("Double Yolker"))
	var first_card: Control = first_slot.get_node("EggContent/EggVisual").make_tooltip_card()
	add_child_autofree(first_card)
	assert_string_contains(first_card.card_text(), "CHANCE OF DOUBLE YOLKER\n2%")
	assert_false(first_card.card_text().contains("IS DOUBLE YOLKER"))
	var previews: Array[Node] = main.get_node("Content/Stage/Pipe/Preview").get_children()
	assert_eq(float(previews[0].current_egg().double_yolk_chance), 0.02)
	assert_eq(float(previews[1].current_egg().double_yolk_chance), 0.02)
	assert_eq(previews[0].egg_summary(), previews[1].egg_summary())
	assert_eq(previews[0].egg_description(), previews[1].egg_description())


func test_parent_loading_tile_does_not_repeat_species_level_odds() -> void:
	var tile = (load("res://src/presentation/producer_output_tile.tscn") as PackedScene).instantiate()
	add_child_autofree(tile)
	tile.render_producer({
		"kind": "chicken",
		"toughness": 3,
		"points": 3,
		"double_yolk_chance": 0.10,
	})

	assert_eq(tile.odds_text(), "")
	assert_eq(float(tile.production_fact.double_yolk_chance), 0.10)


func test_double_yolker_hatch_has_a_large_two_yolk_six_point_payoff() -> void:
	var flock = ProducerFlock.new([
		{"kind": "chicken"},
		{"kind": "chicken"},
		{"kind": "chicken"},
		{"kind": "chicken"},
	])
	var session = null
	for day_seed in range(1000):
		var candidate = ChickenDaySession.new(day_seed, flock, IdentityShuffler.new())
		if bool(candidate.state().slots[0].is_double_yolker):
			session = candidate
			break
	assert_not_null(session)
	var main := _add_main()
	main.replace_session(session)
	main.set_reduced_motion(true)
	await _press_and_wait(main, "RedCircuit")
	await _press_and_wait(main, "BlueCircuit")
	main.set_reduced_motion(false)
	var payoff := main.get_node("Content/HatchPayoff")
	var reveal := ["", "", 0]
	main.get_node("Presentation").hatch_payoff_started.connect(
		func(_slot_index: int, _points_awarded: int) -> void:
			reveal[0] = payoff.jackpot_text()
			reveal[1] = payoff.point_text()
			reveal[2] = payoff.yolk_count()
	)

	await _press_and_wait(main, "RedCircuit")

	assert_eq(reveal, ["DOUBLE YOLKER!", "+6", 2])
	assert_eq(main.get_node("Content/HUD/GrandmaScorer/Layout/Appetite/Score").text, "APPETITE 6 / 10")
	assert_false(payoff.is_active())


func test_restart_clears_an_interrupted_hatch_payoff_without_committing_score() -> void:
	var main := _add_authored_main()
	main.set_reduced_motion(true)
	await _press_and_wait(main, "RedCircuit")
	await _press_and_wait(main, "BlueCircuit")
	main.set_reduced_motion(false)
	var presenter := main.get_node("Presentation")
	var payoff := main.get_node("Content/HatchPayoff")
	var committed_scores: Array[int] = []
	presenter.score_committed.connect(
		func(_points_awarded: int, score: int) -> void: committed_scores.append(score)
	)

	main.get_node("Content/Stage/CircuitBank/RedCircuit").pressed.emit()
	await presenter.hatch_payoff_started
	assert_true(payoff.is_active())
	main.restart_day()
	await get_tree().process_frame

	assert_false(payoff.is_active())
	assert_eq(payoff.point_text(), "")
	assert_eq(committed_scores, [])
	assert_eq(main.get_node("Content/HUD/GrandmaScorer/Layout/Appetite/Score").text, "APPETITE 0 / 10")


func test_pink_spoonbill_combo_presents_double_damage_and_the_cuckoo_echo() -> void:
	var main := _add_main_for_ordered_eggs([
		"chicken", "chicken", "chicken", "cuckoo", "spoonbill", "chicken",
	])
	main.set_reduced_motion(true)
	var presented: Array[String] = []
	var points_landed: Array[int] = []
	main.presentation_event.connect(func(event_type: String) -> void: presented.append(event_type))
	main.get_node("Presentation").score_committed.connect(
		func(points_awarded: int, _score: int) -> void: points_landed.append(points_awarded)
	)

	await _press_and_wait(main, "PinkCircuit")

	assert_eq(presented.slice(0, 7), [
		"circuit_fired", "egg_damaged", "egg_damaged",
		"conveyor_advanced", "egg_binned", "egg_entered", "bin_reshuffled",
	])
	assert_eq(points_landed, [])
	assert_eq(main.get_node("Content/HUD/GrandmaScorer/Layout/Appetite/Score").text, "APPETITE 0 / 10")


func test_restart_cancels_active_circuit_playback_without_stale_state() -> void:
	var main := _add_main_for_ordered_eggs([
		"chicken", "cuckoo", "chicken", "cuckoo", "chicken",
	])
	var completion_count := 0
	main.playback_completed.connect(func() -> void: completion_count += 1)

	main.get_node("Content/Stage/CircuitBank/RedCircuit").pressed.emit()
	main.restart_day()
	await get_tree().create_timer(0.5).timeout

	assert_false(main.is_input_locked())
	assert_eq(main.get_node("Content/Stage/Belt/BeltCondition/BeltConditionLabel").text, "BELT CONDITION  12 / 12")
	assert_string_contains(main.get_node("Content/Stage/Belt/Slots/Slot1").egg_summary(), "TOUGHNESS 3")
	assert_eq(completion_count, 0)


func test_settings_menu_updates_mute_and_reduced_motion_presentation() -> void:
	var main := _add_main()
	var popup: PopupMenu = main.get_node("Content/HUD/Settings").get_popup()

	popup.id_pressed.emit(0)
	popup.id_pressed.emit(1)

	assert_true(main.is_muted())
	assert_true(main.is_reduced_motion())
	assert_true(popup.is_item_checked(popup.get_item_index(0)))
	assert_true(popup.is_item_checked(popup.get_item_index(1)))
	assert_true(main.get_node("Presentation/UIFeedback").is_muted())
	assert_true(main.get_node("Presentation/UIFeedback").is_reduced_motion())


func test_ui_feedback_uses_shared_motion_tokens_and_cancellable_control_motion() -> void:
	var main := _add_main()
	var feedback = main.get_node("Presentation/UIFeedback")
	var action: Button = main.get_node("ResultOverlay/Card/Content/Restart")

	assert_lt(MotionTokens.SNAP, MotionTokens.SETTLE)
	assert_lt(MotionTokens.SETTLE, MotionTokens.REVEAL)
	assert_true(feedback.is_control_registered(action))
	assert_true(feedback.is_control_registered(
		main.get_node("BirdOfferOverlay/Card/Content/RewardChoices/Choice1")
	))
	assert_gte(feedback.registered_control_count(), 8)

	main.set_reduced_motion(false)
	action.button_down.emit()
	assert_true(feedback.is_control_animating(action))
	main.set_reduced_motion(true)
	assert_false(feedback.is_control_animating(action))
	assert_eq(action.scale, Vector2.ONE)


func test_resolved_hud_facts_trigger_non_blocking_ui_feedback() -> void:
	var main := _add_main_for_ordered_eggs([
		"chicken", "cuckoo", "chicken", "cuckoo", "chicken",
	])
	main.set_reduced_motion(false)
	var feedback = main.get_node("Presentation/UIFeedback")
	var kinds: Array[String] = []
	feedback.feedback_presented.connect(
		func(kind: String) -> void: kinds.append(kind)
	)

	await _press_and_wait(main, "RedCircuit")

	assert_true("belt condition" in kinds)
	assert_true("hopper" in kinds)
	assert_true(feedback.has_active_motion())
	main.set_reduced_motion(true)
	assert_false(feedback.has_active_motion())
	assert_eq(main.get_node("Content/Stage/Belt/BeltCondition").scale, Vector2.ONE)
	assert_eq(main.get_node("Content/Stage/Pipe/HopperInspect").scale, Vector2.ONE)
	assert_eq(main.get_node("Content/Stage/Belt/BeltCondition").modulate, Color.WHITE)
	assert_eq(main.get_node("Content/Stage/Pipe/HopperInspect").modulate, Color.WHITE)


func test_crunch_audio_streams_are_present_and_non_empty() -> void:
	var main := _add_main()
	var audio_root: Node = main.get_node("Presentation/Audio")

	for player_name in ["Lever", "Impact", "Echo", "Shuffle", "Hatch", "Score", "Belt", "Loss", "Pipe"]:
		var player: AudioStreamPlayer = audio_root.get_node(player_name)
		assert_not_null(player.stream, "%s has a stream" % player_name)
		assert_gt(player.stream.data.size(), 1000, "%s stream contains PCM data" % player_name)
	var ui_audio_root: Node = main.get_node("Presentation/UIFeedback/Audio")
	for player_name in ["Focus", "Press", "Confirm", "Reject", "Panel"]:
		var player: AudioStreamPlayer = ui_audio_root.get_node(player_name)
		assert_not_null(player.stream, "%s UI sound has a stream" % player_name)
		assert_gt(player.stream.data.size(), 1000, "%s UI sound contains PCM data" % player_name)


func test_day_result_appears_when_hopper_and_conveyor_are_empty() -> void:
	var main := _add_main_for_ordered_eggs(["chicken"])
	main.set_reduced_motion(true)

	for circuit_name in ["RedCircuit", "BlueCircuit", "RedCircuit"]:
		await _press_and_wait(main, circuit_name)

	var result_panel: Control = main.get_node("ResultOverlay")
	assert_true(result_panel.visible)
	assert_eq(main.get_node("ResultOverlay/Card/Content/Result").text, "DAY FAILED")
	assert_eq(main.get_node("Content/Stage/Belt/BeltCondition/BeltConditionLabel").text, "BELT CONDITION  9 / 12")
	assert_false(main.get_node("WorkshopOverlay").visible)
	assert_true(main.get_node("ResultOverlay/Card/Content/Restart").visible)
	assert_eq(main.get_node("ResultOverlay/Card/Content/Restart").text, "RETRY DAY 1")
	assert_eq(main.get_node("ResultOverlay/Card/Content/CashPayout").text, "NO CASH EARNED  •  BALANCE £0")
	assert_eq(
		main.get_node("ResultOverlay/Card/Content/FlockSummary").text,
		"FLOCK 1 PRODUCER  •  DAILY OUTPUT 1 EGG"
	)

	main.get_node("ResultOverlay/Card/Content/Restart").pressed.emit()
	assert_false(result_panel.visible)
	assert_eq(main.get_node("Content/Stage/Belt/BeltCondition/BeltConditionLabel").text, "BELT CONDITION  12 / 12")


func test_success_result_ledger_is_acknowledged_before_the_store_opens() -> void:
	var main := _add_authored_main()
	main.set_reduced_motion(true)

	await _complete_successful_day(main, false)
	await get_tree().process_frame

	var result_overlay: Control = main.get_node("ResultOverlay")
	var result_card: Control = main.get_node("ResultOverlay/Card")
	assert_true(result_overlay.visible)
	assert_false(main.get_node("WorkshopOverlay").visible)
	assert_eq(main.get_node("ResultOverlay/Card/Content/Result").text, "DAY 1 COMPLETE")
	assert_string_contains(
		main.get_node("ResultOverlay/Card/Content/ResultScore").text,
		"APPETITE MET"
	)
	assert_string_contains(
		main.get_node("ResultOverlay/Card/Content/CashPayout").text,
		"BALANCE £3"
	)
	assert_string_contains(
		main.get_node("ResultOverlay/Card/Content/FlockSummary").text,
		"FLOCK 24"
	)
	for panel_path in ["HeaderRack", "LedgerPanel", "ActionWell"]:
		assert_true(result_card.get_global_rect().encloses(
			main.get_node("ResultOverlay/Card/Content/%s" % panel_path).get_global_rect()
		))
	var action: Button = main.get_node("ResultOverlay/Card/Content/Restart")
	assert_eq(action.text, "VIEW BIRD OFFER")
	assert_true(action.has_focus())
	assert_false(main.is_result_transition_active())

	action.pressed.emit()
	await get_tree().process_frame

	assert_false(result_overlay.visible)
	assert_true(main.get_node("BirdOfferOverlay").visible)
	assert_false(main.get_node("WorkshopOverlay").visible)
	assert_true(main.get_node("BirdOfferOverlay/Card/Content/RewardChoices/Choice1").has_focus())


func test_result_reveal_is_cancelled_when_the_session_is_replaced() -> void:
	var main := _add_authored_main()
	main.set_reduced_motion(false)

	await _complete_successful_day(main, false)

	assert_true(main.is_result_transition_active())
	main.replace_session(ChickenDaySession.new())
	await get_tree().process_frame
	assert_false(main.is_result_transition_active())
	assert_false(main.get_node("ResultOverlay").visible)


func test_success_opens_three_free_quality_offers_on_a_separate_screen() -> void:
	var main := _add_authored_main()
	main.set_reduced_motion(true)

	await _complete_successful_day(main)

	var choices: HBoxContainer = main.get_node("BirdOfferOverlay/Card/Content/RewardChoices")
	var offered_kinds: Array[String] = []
	for choice in choices.get_children().filter(func(button: Button) -> bool: return button.visible):
		offered_kinds.append(choice.producer_kind)
		assert_eq(choice.portrait_kind(), choice.producer_kind)
		assert_eq(choice.preview_egg_kind(), choice.producer_kind)
		assert_eq(choice.preview_egg_count(), 1)
		assert_string_contains(choice.card_text(), "EGG")
		assert_string_contains(choice.card_text(), "TOUGHNESS")
		assert_string_contains(choice.card_text(), "POINT")
		assert_string_contains(choice.card_text(), "FREE")
		assert_eq(choice.tooltip_text, "")
	assert_false(main.get_node("ResultOverlay").visible)
	assert_true(main.get_node("BirdOfferOverlay").visible)
	assert_false(main.get_node("WorkshopOverlay").visible)
	assert_gt(main.get_node("BirdOfferOverlay").z_index, main.get_node("Content").z_index)
	assert_true(choices.visible)
	assert_eq(choices.get_child_count(), 3)
	assert_eq(offered_kinds.duplicate().reduce(
		func(unique: Array, kind: String) -> Array:
			if kind not in unique:
				unique.append(kind)
			return unique,
		[]
	).size(), 3)
	assert_string_contains(
		main.get_node("BirdOfferOverlay/Card/Content/BirdOfferSummary").text,
		"DAY 2 APPETITE 9"
	)
	assert_eq(main.get_node("Content/Stage/Belt/BeltCondition/BeltConditionLabel").text, "BELT CONDITION  91 / 99")
	await get_tree().process_frame
	assert_true(main.get_node("BirdOfferOverlay/Card/Content/RewardChoices/Choice1").has_focus())
	var offer_card: Control = main.get_node("BirdOfferOverlay/Card")
	assert_true(main.get_global_rect().encloses(offer_card.get_global_rect()))
	assert_true(offer_card.get_global_rect().encloses(choices.get_global_rect()))
	for choice: Button in choices.get_children():
		assert_gte(choice.custom_minimum_size.x, 320.0)
		assert_gte(choice.custom_minimum_size.y, 200.0)
	assert_false(main.get_node("BirdOfferOverlay").has_node("Card/Content/FlockScroll"))


func test_flock_overview_removes_the_selected_bird_for_three_pounds() -> void:
	var producers: Array[Dictionary] = []
	for egg_index in range(7):
		producers.append({"kind": "chicken"})
	var session = ChickenDaySession.new(
		42, ProducerFlock.new(producers), IdentityShuffler.new(), 1, 99
	)
	while int(session.state().cash) < 3:
		for circuit_id in [
			"red", "red", "red", "red", "blue", "red", "blue", "red",
		]:
			session.submit_circuit(circuit_id)
			if session.state().phase != "day":
				break
		if int(session.state().cash) < 3:
			session.claim_bird_offer(0)
			session.leave_shop()
	assert_eq(session.state().phase, "bird_offer")
	session.claim_bird_offer(0)
	assert_eq(session.state().phase, "shop")

	var main := _add_main()
	main.set_reduced_motion(true)
	main.replace_session(session)
	await get_tree().process_frame

	var cash_before := int(
		main.get_node("WorkshopOverlay/Card/Content/WorkshopBalance").text.trim_prefix("BALANCE £")
	)
	var flock_grid: GridContainer = main.get_node(
		"WorkshopOverlay/Card/Content/FlockScroll/FlockGrid"
	)
	var flock_size_before := flock_grid.get_child_count()
	var selected: Button = flock_grid.get_child(2)
	var selected_kind: String = selected.portrait_kind()
	assert_false(selected.disabled)
	assert_true(main.get_node("Presentation/UIFeedback").is_control_registered(selected))

	selected.pressed.emit()
	await get_tree().process_frame

	assert_eq(
		main.get_node("WorkshopOverlay/Card/Content/WorkshopBalance").text,
		"BALANCE £%d" % (cash_before - 3)
	)
	assert_eq(flock_grid.get_child_count(), flock_size_before - 1)
	assert_string_contains(main.get_node("WorkshopOverlay/Card/Content/WorkshopStatus").text, "REMOVED")
	assert_string_contains(main.get_node("WorkshopOverlay/Card/Content/WorkshopStatus").text, selected_kind.to_upper())
	assert_true(flock_grid.get_children().all(func(bird: Button) -> bool:
		return bird.disabled and bird.card_text().contains("REMOVAL USED")
	))
	assert_eq(
		main.get_node("Presentation/UIFeedback").registered_control_count(),
		8 + flock_grid.get_child_count()
	)


func test_store_motion_is_cancellable_and_reduced_motion_opens_immediately() -> void:
	var main := _add_authored_main()
	main.set_reduced_motion(false)

	await _complete_successful_day(main)

	assert_true(main.get_node("BirdOfferOverlay").visible)
	assert_false(main.get_node("WorkshopOverlay").visible)
	assert_false(main.is_workshop_transition_active())
	main.get_node("BirdOfferOverlay/Card/Content/RewardChoices/Choice1").pressed.emit()
	await get_tree().process_frame
	assert_false(main.get_node("BirdOfferOverlay").visible)
	assert_true(main.get_node("WorkshopOverlay").visible)
	assert_true(main.is_workshop_transition_active())
	main.replace_session(ChickenDaySession.new())
	await get_tree().process_frame
	assert_false(main.is_workshop_transition_active())
	assert_false(main.get_node("BirdOfferOverlay").visible)
	assert_false(main.get_node("WorkshopOverlay").visible)

	main = _add_authored_main()
	main.set_reduced_motion(true)
	await _complete_successful_day(main)
	assert_true(main.get_node("BirdOfferOverlay").visible)
	main.get_node("BirdOfferOverlay/Card/Content/RewardChoices/Choice1").pressed.emit()
	await get_tree().process_frame
	assert_true(main.get_node("WorkshopOverlay").visible)
	assert_false(main.is_workshop_transition_active())


func test_early_success_shows_fixed_day_payout_and_persistent_balance() -> void:
	var daily_eggs: Array[String] = []
	daily_eggs.resize(7)
	daily_eggs.fill("chicken")
	var main := _add_main_for_ordered_eggs(daily_eggs, 99)
	main.set_reduced_motion(true)
	var presented: Array[String] = []
	main.presentation_event.connect(func(event_type: String) -> void: presented.append(event_type))

	for circuit_name: String in EARLY_SUCCESS_CIRCUITS:
		await _press_and_wait(main, circuit_name)

	assert_eq(presented.slice(-3), ["day_remainder_discarded", "day_ended", "cash_awarded"])
	assert_true(main.get_node("ResultOverlay").visible)
	assert_string_contains(
		main.get_node("ResultOverlay/Card/Content/CashPayout").text,
		"DAY PAYOUT"
	)
	assert_false(
		"PROTOTYPE" in main.get_node("ResultOverlay/Card/Content/CashPayout").text
	)
	assert_false(main.get_node("BirdOfferOverlay").visible)
	assert_false(main.get_node("WorkshopOverlay").visible)
	main.get_node("ResultOverlay/Card/Content/Restart").pressed.emit()
	await get_tree().process_frame
	assert_true(main.get_node("BirdOfferOverlay").visible)
	assert_false(main.get_node("WorkshopOverlay").visible)


func test_claiming_a_free_bird_then_leaving_starts_day_two_with_the_larger_flock() -> void:
	var main := _add_authored_main()
	main.set_reduced_motion(true)
	await _complete_successful_day(main)
	var first_choice = main.get_node("BirdOfferOverlay/Card/Content/RewardChoices/Choice1")
	var expected_flock_size := 25
	var loading_facts: Array[Vector2i] = []
	main.production_loading_started.connect(
		func(producer_count: int, egg_count: int) -> void:
			loading_facts.append(Vector2i(producer_count, egg_count))
	)

	assert_false(main.get_node("ResultOverlay").visible)
	assert_true(main.get_node("BirdOfferOverlay").visible)
	assert_false(main.get_node("WorkshopOverlay").visible)
	assert_false(first_choice.disabled)
	first_choice.pressed.emit()
	await get_tree().process_frame
	assert_false(main.get_node("BirdOfferOverlay").visible)
	assert_true(main.get_node("WorkshopOverlay").visible)
	assert_eq(main.get_node("WorkshopOverlay/Card/Content/WorkshopBalance").text, "BALANCE £3")
	assert_true(main.get_node("WorkshopOverlay/Card/Content/FlockPanel").get_global_rect().encloses(
		main.get_node("WorkshopOverlay/Card/Content/FlockScroll").get_global_rect()
	))
	assert_eq(main.get_node(
		"WorkshopOverlay/Card/Content/FlockScroll/FlockGrid"
	).get_child_count(), expected_flock_size)
	assert_string_contains(main.get_node("WorkshopOverlay/Card/Content/WorkshopStatus").text, "NO CHARGE")
	var ui_feedback = main.get_node("Presentation/UIFeedback")
	assert_eq(ui_feedback.last_feedback_kind(), "confirm")
	assert_eq(
		main.get_node("WorkshopOverlay/Card/Content/WorkshopActions/ContinueWorkshop").text,
		"LEAVE SHOP & START DAY 2"
	)
	assert_false(main.get_node(
		"WorkshopOverlay/Card/Content/WorkshopActions/ContinueWorkshop"
	).disabled)

	main.get_node("WorkshopOverlay/Card/Content/WorkshopActions/ContinueWorkshop").pressed.emit()
	await main.production_loading_completed
	await get_tree().process_frame

	assert_eq(loading_facts, [Vector2i(expected_flock_size, expected_flock_size)])
	assert_false(main.get_node("ResultOverlay").visible)
	assert_false(main.get_node("WorkshopOverlay").visible)
	assert_false(main.get_node("ProductionLoader").visible)
	assert_eq(main.get_node("Content/Stage/Pipe/HopperInspect").text, "HOPPER %d" % maxi(0, expected_flock_size - 5))
	assert_eq(main.get_node("Content/HUD/GrandmaScorer/Layout/Appetite/Score").text, "APPETITE 0 / 9")
	assert_false(main.get_node("Content/Stage/Belt/Slots/Slot1").current_egg().is_empty())
	assert_false(main.has_node("Content/Stage/Belt/Slots/Slot6"))
	for hammer_index in range(1, 6):
		assert_true(
			main.get_node("Content/Stage/HammerBank/Hammer%d" % hammer_index)
			.is_wall_pinned_spoon()
		)


func test_day_three_keeps_the_same_single_track_and_three_levers() -> void:
	var main := _add_authored_main()
	main.set_reduced_motion(true)
	await _complete_successful_day(main)
	main.get_node("BirdOfferOverlay/Card/Content/RewardChoices/Choice1").pressed.emit()
	await get_tree().process_frame
	main.get_node("WorkshopOverlay/Card/Content/WorkshopActions/ContinueWorkshop").pressed.emit()
	await main.production_loading_completed

	await _complete_successful_day(main)
	assert_true(main.get_node("BirdOfferOverlay").visible)
	main.get_node("BirdOfferOverlay/Card/Content/RewardChoices/Choice1").pressed.emit()
	await get_tree().process_frame
	assert_true(main.get_node("WorkshopOverlay").visible)
	assert_false(
		main.get_node("WorkshopOverlay/Card/Content/WorkshopStatus").text.contains("REFIT")
	)
	assert_eq(
		main.get_node("WorkshopOverlay/Card/Content/WorkshopActions/ContinueWorkshop").text,
		"LEAVE SHOP & START DAY 3"
	)

	main.get_node("WorkshopOverlay/Card/Content/WorkshopActions/ContinueWorkshop").pressed.emit()
	await main.production_loading_completed
	await get_tree().process_frame

	var circuits := main.get_node("Content/Stage/CircuitBank")
	assert_eq(circuits.get_child_count(), 3)
	assert_eq(circuits.get_node("RedCircuit").slot_indices, [0, 2])
	assert_eq(circuits.get_node("BlueCircuit").slot_indices, [1, 3])
	assert_eq(circuits.get_node("PinkCircuit").slot_indices, [4])
	assert_true(circuits.get_node("RedCircuit").has_focus())
	assert_eq(main.get_node("Content/Stage/Belt/Slots").get_child_count(), 5)
	assert_eq(main.get_node("Content/Stage/Belt/Bin").text, "BIN 0")
	for hammer_number in range(1, 6):
		var hammer: Control = main.get_node(
			"Content/Stage/HammerBank/Hammer%d" % hammer_number
		)
		assert_true(hammer.visible)
		assert_true(hammer.is_wall_pinned_spoon())
		assert_eq(hammer.contact_points_global().size(), 1)
	assert_false(main.is_input_locked())


func test_replacing_the_session_cancels_an_active_production_loading_sequence() -> void:
	var main := _add_authored_main()
	main.set_reduced_motion(true)
	await _complete_successful_day(main)
	main.get_node("BirdOfferOverlay/Card/Content/RewardChoices/Choice1").pressed.emit()
	await get_tree().process_frame
	main.set_reduced_motion(false)
	var completion_count := [0]
	var started_count := [0]
	main.production_loading_completed.connect(func() -> void: completion_count[0] += 1)
	main.production_loading_started.connect(
		func(_producer_count: int, _egg_count: int) -> void: started_count[0] += 1
	)

	main.get_node("WorkshopOverlay/Card/Content/WorkshopActions/ContinueWorkshop").pressed.emit()
	while started_count[0] == 0:
		await get_tree().process_frame
	assert_eq(started_count[0], 1)
	assert_true(main.is_input_locked())
	assert_true(main.get_node("ProductionLoader").is_active())

	main.replace_session(ChickenDaySession.new())
	await get_tree().create_timer(0.25).timeout

	assert_false(main.get_node("ProductionLoader").is_active())
	assert_false(main.get_node("ProductionLoader").visible)
	assert_false(main.is_input_locked())
	assert_eq(completion_count[0], 0)
	assert_eq(main.get_node("Content/HUD/GrandmaScorer/Layout/Appetite/Score").text, "APPETITE 0 / 10")


func _press_and_wait(main: Control, circuit_name: String) -> void:
	var circuit_button: Button = main.get_node("Content/Stage/CircuitBank/%s" % circuit_name)
	if circuit_button.disabled:
		return
	circuit_button.pressed.emit()
	await main.playback_completed
	await get_tree().process_frame


func _complete_successful_day(main: Control, acknowledge_result := true) -> void:
	for circuit_name in AUTHORED_SUCCESS_CIRCUITS:
		if main.get_node("Content/Stage/CircuitBank/%s" % circuit_name).disabled:
			continue
		await _press_and_wait(main, circuit_name)
		if main.get_node("ResultOverlay").visible or main.get_node("WorkshopOverlay").visible:
			break
	if (
		acknowledge_result
		and main.get_node("ResultOverlay").visible
		and main.get_node("ResultOverlay/Card/Content/Result").text.contains("COMPLETE")
	):
		main.get_node("ResultOverlay/Card/Content/Restart").pressed.emit()
		await get_tree().process_frame


func _add_main() -> Control:
	var packed_scene := load("res://src/ui/main.tscn") as PackedScene
	var main := packed_scene.instantiate() as Control
	add_child_autofree(main)
	return main


func _add_authored_main() -> Control:
	var producers: Array[Dictionary] = []
	for kind: String in AUTHORED_DAILY_EGGS:
		producers.append({"kind": kind})
	var session = ChickenDaySession.new(
		0,
		ProducerFlock.new(producers),
		IdentityShuffler.new(),
		1,
		99
	)
	var main := _add_main()
	main.replace_session(session)
	return main


func _add_main_for_ordered_eggs(
	egg_kinds: Array[String], starting_belt_condition := 12
) -> Control:
	var producers: Array[Dictionary] = []
	for kind: String in egg_kinds:
		producers.append({"kind": kind})
	var session = ChickenDaySession.new(
		0,
		ProducerFlock.new(producers),
		IdentityShuffler.new(),
		1,
		starting_belt_condition
	)
	var main := _add_main()
	main.replace_session(session)
	return main
