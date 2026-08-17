extends GutTest

const GrandmaPatience = preload("res://src/domain/grandma_patience.gd")


func test_patience_can_be_inspected_changed_and_gained_above_its_starting_value() -> void:
	var patience = GrandmaPatience.new(10)

	assert_eq(patience.starting(), 10)
	assert_eq(patience.current(), 10)
	assert_true(patience.can_afford(1))
	assert_eq(patience.lose(3), 3)
	assert_eq(patience.current(), 7)
	patience.gain(5)
	assert_eq(patience.current(), 12)
	assert_eq(patience.starting(), 10)


func test_patience_loss_is_clamped_at_zero() -> void:
	var patience = GrandmaPatience.new(2)

	assert_eq(patience.lose(5), 2)
	assert_eq(patience.current(), 0)
	assert_false(patience.can_afford(1))
	assert_eq(patience.lose(1), 0)
	assert_eq(patience.current(), 0)
