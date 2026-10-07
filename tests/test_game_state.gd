extends TestCase

var b: BalanceConfig


func before_each() -> void:
	b = BalanceConfig.new()
	b.cell_count = 4
	b.observation_duration = 5.0
	b.run_duration = 10.0


func _state(ids: Array[int], starts: Dictionary) -> GameState:
	return GameState.new(b, ids, starts)


func _to_run(s: GameState) -> void:
	s.tick(b.observation_duration)


func _end_round(s: GameState) -> void:
	s.tick(b.run_duration)


func test_initial_state() -> void:
	var s := _state([1], {1: 3})
	assert_eq(s.phase, GameState.Phase.OBSERVATION)
	assert_eq(s.round_number, 1)
	assert_eq(s.cell_of(1), 3)
	assert_true(s.has_visited(1, 3), "Startzelle zählt als besucht")
	assert_eq(s.visited_count(1), 1)
	assert_true(not s.doors_open())


func test_start_cell_not_visited_when_configured() -> void:
	b.start_cell_counts_as_visited = false
	var s := _state([1], {1: 3})
	assert_eq(s.visited_count(1), 0)


func test_random_start_cells_are_distinct() -> void:
	b.cell_count = 8
	var s := GameState.new(b, [1, 2, 3, 4, 5, 6, 7, 8])
	var seen := {}
	for pid in s.player_ids():
		seen[s.cell_of(pid)] = true
	assert_eq(seen.size(), 8)


func test_phase_cycle_and_timing() -> void:
	var s := _state([1], {1: 1})
	s.tick(4.9)
	assert_eq(s.phase, GameState.Phase.OBSERVATION)
	s.tick(0.2)
	assert_eq(s.phase, GameState.Phase.RUN)
	assert_true(s.doors_open())
	s.leave_cell(1)
	s.enter_cell(1, 2)
	s.tick(9.95)
	assert_eq(s.phase, GameState.Phase.OBSERVATION)
	assert_eq(s.round_number, 2)
	assert_true(not s.doors_open())


func test_large_tick_crosses_several_phases() -> void:
	var s := _state([1], {1: 1})
	s.tick(100.0)
	assert_true(s.is_finished(), "ohne Bewegung scheidet der Spieler aus, Spiel endet")


func test_cannot_enter_during_observation() -> void:
	var s := _state([1], {1: 1})
	assert_true(not s.enter_cell(1, 2))


func test_enter_new_cell() -> void:
	var s := _state([1], {1: 1})
	_to_run(s)
	assert_true(not s.enter_cell(1, 2), "erst aus der Zelle in den Hof")
	assert_true(s.leave_cell(1))
	assert_eq(s.cell_of(1), GameState.NO_CELL)
	assert_true(s.enter_cell(1, 2))
	assert_eq(s.cell_of(1), 2)
	assert_eq(s.claimed_by(2), 1)
	assert_eq(s.visited_count(1), 2)


func test_cannot_revisit_cell() -> void:
	var s := _state([1], {1: 1})
	_to_run(s)
	s.leave_cell(1)
	assert_true(not s.enter_cell(1, 1), "Startzelle ist besucht")


func test_only_one_claim_per_round() -> void:
	var s := _state([1], {1: 1})
	_to_run(s)
	s.leave_cell(1)
	assert_true(s.enter_cell(1, 2))
	s.leave_cell(1)
	assert_true(not s.enter_cell(1, 3))


func test_first_player_claims_cell() -> void:
	var s := _state([1, 2], {1: 1, 2: 2})
	_to_run(s)
	s.leave_cell(1)
	s.leave_cell(2)
	assert_true(s.enter_cell(1, 3))
	assert_true(not s.enter_cell(2, 3), "Zelle ist in dieser Runde vergeben")
	assert_true(s.enter_cell(2, 4))


func test_cannot_enter_cell_occupied_by_other() -> void:
	var s := _state([1, 2], {1: 1, 2: 2})
	_to_run(s)
	s.leave_cell(1)
	assert_true(not s.enter_cell(1, 2), "Spieler 2 steht noch in Zelle 2")


func test_cell_freed_after_leaving_can_be_taken() -> void:
	var s := _state([1, 2], {1: 1, 2: 2})
	_to_run(s)
	s.leave_cell(2)
	s.leave_cell(1)
	assert_true(s.enter_cell(1, 2), "Spieler 1 hat Zelle 2 noch nicht besucht")


func test_standing_still_eliminates() -> void:
	var s := _state([1], {1: 1})
	_to_run(s)
	_end_round(s)
	assert_true(not s.is_alive(1))
	assert_true(s.is_finished())
	assert_eq(s.winners.size(), 0)


func test_in_yard_at_closing_eliminates() -> void:
	var s := _state([1, 2], {1: 1, 2: 2})
	_to_run(s)
	s.leave_cell(1)
	s.leave_cell(2)
	s.enter_cell(2, 3)
	_end_round(s)
	assert_true(not s.is_alive(1))
	assert_true(s.is_alive(2))
	assert_true(not s.is_finished())
	assert_eq(s.round_number, 2)


func test_leaving_claimed_cell_eliminates() -> void:
	var s := _state([1], {1: 1})
	_to_run(s)
	s.leave_cell(1)
	s.enter_cell(1, 2)
	s.leave_cell(1)
	_end_round(s)
	assert_true(not s.is_alive(1))


func test_claims_reset_each_round() -> void:
	var s := _state([1], {1: 1})
	_to_run(s)
	s.leave_cell(1)
	s.enter_cell(1, 2)
	_end_round(s)
	assert_eq(s.claimed_by(2), GameState.NO_PLAYER)
	_to_run(s)
	s.leave_cell(1)
	assert_true(s.enter_cell(1, 3))


func test_win_after_visiting_all_cells() -> void:
	var s := _state([1], {1: 1})
	for cell in [2, 3, 4]:
		_to_run(s)
		assert_true(s.leave_cell(1))
		assert_true(s.enter_cell(1, cell))
		_end_round(s)
	assert_true(s.is_finished())
	assert_eq(s.winners, [1])


func test_all_survivors_win_together() -> void:
	b.cell_count = 2
	var s := _state([1, 2], {1: 1, 2: 2})
	_to_run(s)
	s.leave_cell(1)
	s.leave_cell(2)
	s.enter_cell(1, 2)
	s.enter_cell(2, 1)
	_end_round(s)
	assert_true(s.is_finished())
	assert_eq(s.winners.size(), 2)


func test_game_over_signal_emitted() -> void:
	var s := _state([1], {1: 1})
	var got := []
	s.game_over.connect(func(w: Array) -> void: got.append(w))
	s.tick(100.0)
	assert_eq(got.size(), 1)


func test_eliminated_player_cannot_act() -> void:
	var s := _state([1, 2], {1: 1, 2: 2})
	_to_run(s)
	s.leave_cell(2)
	s.enter_cell(2, 3)
	_end_round(s)
	_to_run(s)
	assert_true(not s.leave_cell(1))
	assert_true(not s.enter_cell(1, 4))
