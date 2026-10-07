extends Node3D
## Wurzel der Spielszene (M1, Singleplayer): verbindet GameState mit Arena, Spieler und HUD.
## Der Spieler bewegt sich physisch; Zellwechsel werden als Aktionen an den GameState gemeldet.

const BALANCE_PATH := "res://config/balance.tres"
const LOCAL_PLAYER_ID := 1

var balance: BalanceConfig
var state: GameState
var arena: ArenaView
var player: PlayerView
var hud: GameHud


func _ready() -> void:
	InputSetup.ensure_actions()
	balance = load(BALANCE_PATH) as BalanceConfig
	_setup_environment()

	arena = ArenaView.new()
	add_child(arena)
	arena.build(balance)

	var ids: Array[int] = [LOCAL_PLAYER_ID]
	state = GameState.new(balance, ids)

	player = PlayerView.new()
	player.speed = balance.player_speed
	add_child(player)
	player.global_position = arena.spawn_position(state.cell_of(LOCAL_PLAYER_ID))

	hud = GameHud.new()
	add_child(hud)

	state.player_eliminated.connect(func(_id: int) -> void: player.controls_enabled = false)
	state.game_over.connect(func(_w: Array) -> void: player.controls_enabled = false)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	state.tick(delta)
	_report_player_cell()
	arena.refresh(state, LOCAL_PLAYER_ID)
	hud.update_view(state, LOCAL_PLAYER_ID)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("interact") and player.controls_enabled:
		var door := arena.nearest_hand_door(player.global_position, balance.interact_range)
		if door != null:
			arena.toggle_hand_door(door)
	elif event.is_action_pressed("restart") and (state.is_finished() or not state.is_alive(LOCAL_PLAYER_ID)):
		get_tree().reload_current_scene()


## Meldet Zellwechsel (Mittelpunkt des Spielers) als Aktionen an den GameState.
func _report_player_cell() -> void:
	if not state.is_alive(LOCAL_PLAYER_ID):
		return
	var physical := arena.cell_at(player.global_position)
	var logical := state.cell_of(LOCAL_PLAYER_ID)
	if physical == logical:
		return
	if logical != GameState.NO_CELL:
		state.leave_cell(LOCAL_PLAYER_ID)
	if physical != GameState.NO_CELL:
		state.enter_cell(LOCAL_PLAYER_ID, physical)


func _setup_environment() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-60, 30, 0)
	add_child(sun)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.55, 0.7, 0.9)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.6, 0.6, 0.65)
	add_child(env)
