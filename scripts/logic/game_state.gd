class_name GameState
extends RefCounted
## Zentraler Spielzustand (Runde, Phase, Zellen, Spieler). Unabhängig von Szenen.
## Spieleraktionen kommen als Aufrufe (enter_cell, leave_cell); die Logik entscheidet.
## Zellen-IDs laufen von 1 bis cell_count, NO_CELL (0) bedeutet "im Hof".

enum Phase { OBSERVATION, RUN, FINISHED }

signal phase_changed(new_phase: Phase)
signal player_eliminated(player_id: int)
signal game_over(winner_ids: Array)

const NO_CELL := 0
const NO_PLAYER := -1


class PlayerState:
	var id: int
	var alive := true
	var visited := {}  # Zellen-ID -> true
	var cell := NO_CELL

	func _init(p_id: int) -> void:
		id = p_id


var balance: BalanceConfig
var phase: Phase = Phase.OBSERVATION
var round_number := 1
var time_remaining := 0.0
var winners: Array[int] = []

var _players := {}  # Spieler-ID -> PlayerState
var _player_order: Array[int] = []
var _round_claims := {}  # Zelle -> Spieler-ID, nur für die laufende Runde
var _player_claim := {}  # Spieler-ID -> Zelle, nur für die laufende Runde


## start_cells: optional Spieler-ID -> Startzelle. Alle übrigen Spieler bekommen zufällige freie Zellen.
func _init(p_balance: BalanceConfig, player_ids: Array[int], start_cells: Dictionary = {}, rng: RandomNumberGenerator = null) -> void:
	assert(p_balance.observation_duration > 0.0 and p_balance.run_duration > 0.0, "Phasendauern müssen > 0 sein")
	assert(player_ids.size() <= p_balance.cell_count, "Mehr Spieler als Zellen")
	balance = p_balance
	time_remaining = balance.observation_duration

	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var pool: Array[int] = []
	for c in range(1, balance.cell_count + 1):
		if not start_cells.values().has(c):
			pool.append(c)
	for i in range(pool.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := pool[i]
		pool[i] = pool[j]
		pool[j] = tmp

	for pid in player_ids:
		var p := PlayerState.new(pid)
		p.cell = start_cells.get(pid, pool.pop_back())
		if balance.start_cell_counts_as_visited:
			p.visited[p.cell] = true
		_players[pid] = p
		_player_order.append(pid)


func tick(delta: float) -> void:
	if phase == Phase.FINISHED:
		return
	time_remaining -= delta
	while time_remaining <= 0.0 and phase != Phase.FINISHED:
		if phase == Phase.OBSERVATION:
			_set_phase(Phase.RUN)
			time_remaining += balance.run_duration
		else:
			_close_round()
			if phase != Phase.FINISHED:
				_start_next_round()
				time_remaining += balance.observation_duration
	if phase == Phase.FINISHED:
		time_remaining = 0.0


func doors_open() -> bool:
	return phase == Phase.RUN


func is_finished() -> bool:
	return phase == Phase.FINISHED


func player_ids() -> Array[int]:
	return _player_order


func alive_players() -> Array[int]:
	var result: Array[int] = []
	for pid in _player_order:
		if _players[pid].alive:
			result.append(pid)
	return result


func is_alive(pid: int) -> bool:
	return _players[pid].alive


func cell_of(pid: int) -> int:
	return _players[pid].cell


func has_visited(pid: int, cell: int) -> bool:
	return _players[pid].visited.has(cell)


func visited_count(pid: int) -> int:
	return _players[pid].visited.size()


func visited_cells(pid: int) -> Array:
	var cells: Array = _players[pid].visited.keys()
	cells.sort()
	return cells


## Spieler-ID, die die Zelle in dieser Runde beansprucht hat, sonst NO_PLAYER.
func claimed_by(cell: int) -> int:
	return _round_claims.get(cell, NO_PLAYER)


func has_claim_this_round(pid: int) -> bool:
	return _player_claim.has(pid)


## Ein Spieler darf nur aus dem Hof in eine neue, freie Zelle; pro Runde nur eine.
func can_enter(pid: int, cell: int) -> bool:
	if phase != Phase.RUN:
		return false
	var p: PlayerState = _players[pid]
	if not p.alive or p.cell != NO_CELL:
		return false
	if cell < 1 or cell > balance.cell_count:
		return false
	if p.visited.has(cell) or _player_claim.has(pid):
		return false
	if _round_claims.has(cell):
		return false
	for other_id in _player_order:
		if _players[other_id].alive and _players[other_id].cell == cell:
			return false
	return true


func enter_cell(pid: int, cell: int) -> bool:
	if not can_enter(pid, cell):
		return false
	var p: PlayerState = _players[pid]
	p.cell = cell
	p.visited[cell] = true
	_round_claims[cell] = pid
	_player_claim[pid] = cell
	return true


## Zelle in den Hof verlassen. Eine in dieser Runde beanspruchte Zelle bleibt beansprucht.
func leave_cell(pid: int) -> bool:
	var p: PlayerState = _players[pid]
	if phase != Phase.RUN or not p.alive or p.cell == NO_CELL:
		return false
	p.cell = NO_CELL
	return true


func _set_phase(new_phase: Phase) -> void:
	phase = new_phase
	phase_changed.emit(new_phase)


## Schließung: Wer nicht in einer in dieser Runde neu beanspruchten Zelle steht, scheidet aus.
func _close_round() -> void:
	for pid in _player_order:
		var p: PlayerState = _players[pid]
		if not p.alive:
			continue
		var valid: bool = p.cell != NO_CELL and _round_claims.get(p.cell, NO_PLAYER) == pid
		if not valid:
			_eliminate(p)
	var alive := alive_players()
	if alive.is_empty():
		_finish([])
	elif alive.all(func(pid: int) -> bool: return visited_count(pid) >= balance.cell_count):
		_finish(alive)


func _start_next_round() -> void:
	round_number += 1
	_round_claims.clear()
	_player_claim.clear()
	_set_phase(Phase.OBSERVATION)


func _eliminate(p: PlayerState) -> void:
	p.alive = false
	p.cell = NO_CELL
	player_eliminated.emit(p.id)


func _finish(winner_ids: Array[int]) -> void:
	winners = winner_ids
	_set_phase(Phase.FINISHED)
	game_over.emit(winners)
