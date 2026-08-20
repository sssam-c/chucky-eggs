extends GutTest

const YolkComboScene = preload("res://src/ui/yolk_combo_display.tscn")
const YolkComboDisplayScript = preload("res://src/ui/yolk_combo_display.gd")


func test_yolk_pool_merges_base_values_then_surges_to_the_combo_total() -> void:
	var display: Control = YolkComboScene.instantiate()
	add_child_autofree(display)
	await get_tree().process_frame

	assert_false(display.visible)
	assert_not_null(display.get_node_or_null("YolkBall"))
	assert_not_null(display.get_node_or_null("YolkBall/AmountLabel"))
	assert_not_null(display.get_node_or_null("CalloutLabel"))
	assert_not_null(display.get_node_or_null("MultiplierLabel"))
	assert_null(display.get_node_or_null("AwardPanel"))
	display.begin_pool(2)
	assert_lt(display.ball_visual_scale(), 0.35)
	display.merge_yolk(3)
	assert_eq(display.ball_amount(), 3)
	assert_eq(display.amount_text(), "3")
	assert_gt(display.ball_visual_scale(), 0.75)
	display.merge_yolk(4)
	assert_eq(display.ball_amount(), 4)
	assert_gt(display.ball_visual_scale(), 0.90)
	display.show_multiplier(2, 8)
	assert_eq(display.ball_amount(), 8)
	assert_gte(display.ball_visual_scale(), 1.70)
	assert_eq(display.callout_text(), "DOUBLE YOLKER!")
	assert_eq(display.multiplier_text(), "×2")
	assert_true(display.visible)


func test_finishing_delivery_hides_and_resets_the_transient_ball() -> void:
	var display: Control = YolkComboScene.instantiate()
	add_child_autofree(display)
	await get_tree().process_frame
	display.begin_pool(2)
	display.merge_yolk(4)
	display.show_multiplier(2, 8)
	var ball: Control = display.begin_delivery()

	display.finish_delivery()

	assert_not_null(ball)
	assert_eq(display.ball_amount(), 0)
	assert_eq(display.callout_text(), "")
	assert_false(display.visible)
	assert_false(display.is_shimmer_active())


func test_single_break_uses_the_numbered_ball_without_a_combo_callout() -> void:
	var display: Control = YolkComboScene.instantiate()
	add_child_autofree(display)
	await get_tree().process_frame

	display.begin_pool(1)
	display.merge_yolk(3)
	display.show_multiplier(1, 3)

	assert_eq(display.callout_text(), "")
	assert_eq(display.multiplier_text(), "")
	assert_eq(display.amount_text(), "3")
	assert_true(display.visible)


func test_reduced_motion_stops_the_liquid_shimmer() -> void:
	var display: Control = YolkComboScene.instantiate()
	add_child_autofree(display)
	await get_tree().process_frame
	display.begin_pool(2)
	assert_true(display.is_shimmer_active())

	display.set_reduced_motion(true)

	assert_false(display.is_shimmer_active())


func test_large_same_tap_combos_keep_a_compact_numeric_callout() -> void:
	assert_eq(YolkComboDisplayScript.combo_callout(2), "DOUBLE YOLKER!")
	assert_eq(YolkComboDisplayScript.combo_callout(3), "TRIPLE YOLKER!")
	assert_eq(YolkComboDisplayScript.combo_callout(5), "QUINTUPLE YOLKER!")


func test_yolk_scale_moves_from_tiny_to_massive_without_growing_unbounded() -> void:
	assert_lt(YolkComboDisplayScript.visual_scale_for_yolk(1), 0.5)
	assert_gt(YolkComboDisplayScript.visual_scale_for_yolk(4), 0.9)
	assert_gte(YolkComboDisplayScript.visual_scale_for_yolk(8), 1.7)
	assert_gt(
		YolkComboDisplayScript.visual_scale_for_yolk(12),
		YolkComboDisplayScript.visual_scale_for_yolk(8)
	)
	assert_lte(YolkComboDisplayScript.visual_scale_for_yolk(100), 2.0)
