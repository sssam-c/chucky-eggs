extends GutTest

const YolkStreakScene = preload("res://src/ui/yolk_streak_display.tscn")


func test_break_callouts_and_multiplied_yolk_accumulate_in_one_pool() -> void:
	var display: Control = YolkStreakScene.instantiate()
	add_child_autofree(display)
	await get_tree().process_frame

	display.add_hatch(1, 1, 1)
	assert_eq(display.callout_text(), "YOLK!")
	assert_eq(display.pooled_yolk(), 1)
	display.add_hatch(3, 2, 6)
	assert_eq(display.callout_text(), "DOUBLE YOLKER!")
	assert_eq(display.pooled_yolk(), 7)
	display.add_hatch(4, 3, 12)
	assert_eq(display.callout_text(), "TRIPLE YOLKER!")
	assert_eq(display.pooled_yolk(), 19)
	assert_eq(display.get_node("PoolLabel").text, "YOLK POOL  19")
	assert_eq(display.get_node("EquationLabel").text, "4 YOLK  ×3  =  +12")
	assert_true(display.visible)


func test_reset_clears_and_hides_the_temporary_pool() -> void:
	var display: Control = YolkStreakScene.instantiate()
	add_child_autofree(display)
	await get_tree().process_frame
	display.add_hatch(3, 2, 6)

	display.reset_pool()

	assert_eq(display.pooled_yolk(), 0)
	assert_eq(display.last_streak(), 0)
	assert_false(display.visible)


func test_zero_break_feedback_explains_the_reset_before_clearing() -> void:
	var display: Control = YolkStreakScene.instantiate()
	add_child_autofree(display)
	await get_tree().process_frame

	display.show_reset(3)

	assert_eq(display.callout_text(), "STREAK BROKEN")
	assert_eq(display.get_node("EquationLabel").text, "NO EGG BROKE THIS TAP")
	assert_eq(display.get_node("PoolLabel").text, "NEXT BREAK  ×1")
	assert_true(display.visible)


func test_large_streaks_keep_a_compact_numeric_callout() -> void:
	assert_eq(YolkStreakDisplay.streak_callout(4), "QUADRUPLE YOLKER!")
	assert_eq(YolkStreakDisplay.streak_callout(6), "SEXTUPLE YOLKER!")
	assert_eq(YolkStreakDisplay.streak_callout(7), "7× YOLKER!")
