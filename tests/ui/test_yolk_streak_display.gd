extends GutTest

const YolkStreakScene = preload("res://src/ui/yolk_streak_display.tscn")


func test_break_callouts_accumulate_in_a_stable_bowl_with_one_calculation() -> void:
	var display: Control = YolkStreakScene.instantiate()
	add_child_autofree(display)
	await get_tree().process_frame

	assert_eq(display.streak_text(), "NEXT BREAK  ×1")
	assert_false(display.is_award_visible())
	display.add_hatch(1, 1, 1)
	assert_eq(display.callout_text(), "YOLK!")
	assert_eq(display.pooled_yolk(), 1)
	display.add_hatch(3, 2, 6)
	assert_eq(display.callout_text(), "DOUBLE YOLKER!")
	assert_eq(display.pooled_yolk(), 7)
	display.add_hatch(4, 3, 12)
	assert_eq(display.callout_text(), "TRIPLE YOLKER!")
	assert_eq(display.pooled_yolk(), 19)
	assert_eq(display.get_node("AwardPanel/CalculationLabel").text, "4 YOLK  ×3")
	assert_eq(display.get_node("YolkBowl/BowlTotal").text, "19")
	display.resolve_award(12)
	assert_eq(display.get_node("AwardPanel/CalculationLabel").text, "+12")
	assert_not_null(display.get_node_or_null("StreakBadge"))
	assert_not_null(display.get_node_or_null("YolkBowl"))
	assert_null(display.get_node_or_null("YolkIcons"))
	assert_null(display.get_node_or_null("PoolLabel"))
	assert_true(display.is_award_visible())
	assert_true(display.visible)


func test_finishing_delivery_clears_only_transient_award_and_keeps_streak_anchor() -> void:
	var display: Control = YolkStreakScene.instantiate()
	add_child_autofree(display)
	await get_tree().process_frame
	display.add_hatch(3, 2, 6)

	display.finish_delivery()

	assert_eq(display.pooled_yolk(), 0)
	assert_eq(display.last_streak(), 2)
	assert_eq(display.streak_text(), "STREAK  ×2")
	assert_false(display.is_award_visible())
	assert_true(display.visible)


func test_zero_break_feedback_explains_the_reset_before_clearing() -> void:
	var display: Control = YolkStreakScene.instantiate()
	add_child_autofree(display)
	await get_tree().process_frame

	display.show_reset(3)

	assert_eq(display.callout_text(), "STREAK BROKEN")
	assert_eq(display.get_node("AwardPanel/CalculationLabel").text, "NO EGG BROKE")
	display.finish_reset()
	assert_eq(display.streak_text(), "NEXT BREAK  ×1")
	assert_false(display.is_award_visible())
	assert_true(display.visible)


func test_large_streaks_keep_a_compact_numeric_callout() -> void:
	assert_eq(YolkStreakDisplay.streak_callout(4), "QUADRUPLE YOLKER!")
	assert_eq(YolkStreakDisplay.streak_callout(6), "SEXTUPLE YOLKER!")
	assert_eq(YolkStreakDisplay.streak_callout(7), "7× YOLKER!")
