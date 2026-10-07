extends TestCase

const PATH := "res://config/balance.tres"


func test_config_loads() -> void:
	assert_not_null(load(PATH) as BalanceConfig, "balance.tres muss als BalanceConfig ladbar sein")


func test_plan_start_values() -> void:
	var b := load(PATH) as BalanceConfig
	assert_eq(b.cell_count, 12)
	assert_eq(b.player_count, 8)
	assert_eq(b.observation_duration, 8.0)
	assert_eq(b.run_duration, 25.0)
	assert_eq(b.inventory_slots, 2)
	assert_eq(b.effect_max_rounds, 2)
	assert_eq(b.initial_dangerous_animals, 2)
	assert_eq(b.initial_disruptor_animals, 2)
	assert_eq(b.extra_animals_every_n_rounds, 3)
	assert_true(b.start_cell_counts_as_visited)


func test_animal_types_complete() -> void:
	var b := load(PATH) as BalanceConfig
	for id in ["wolf", "bear", "snake", "wildcat"]:
		assert_true(b.dangerous_animals.has(id), "fehlt: %s" % id)
		var a: Dictionary = b.dangerous_animals[id]
		assert_true(a["delay_player_trapped_min"] <= a["delay_player_trapped_max"], id)
		assert_true(a["delay_self_trapped_min"] <= a["delay_self_trapped_max"], id)
	for id in ["skunk", "porcupine"]:
		assert_true(b.disruptor_animals.has(id), "fehlt: %s" % id)
