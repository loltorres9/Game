class_name ArenaView
extends Node3D
## Baut die Arena aus Primitiven: Hof in der Mitte, Zellen an Nord- und Südwand.
## Jede Zelle hat einen Vorderraum mit elektronischer Tür zum Hof und einen Hinterraum
## mit Handtür. Zell-Koordinaten: lokal +z zeigt zum Hof, Ursprung liegt auf der Handtür-Linie.

const COLOR_WALL := Color(0.55, 0.55, 0.6)
const COLOR_FLOOR := Color(0.4, 0.4, 0.43)
const COLOR_YARD := Color(0.5, 0.45, 0.35)
const COLOR_VISITED := Color(0.25, 0.6, 0.3)
const COLOR_TAKEN := Color(0.75, 0.5, 0.2)
const COLOR_DOOR_CLOSED := Color(0.3, 0.5, 0.9, 0.4)
const COLOR_DOOR_BLOCKED := Color(0.9, 0.2, 0.2, 0.5)
const COLOR_HAND_DOOR := Color(0.5, 0.33, 0.15)


class CellView:
	var id: int
	var root: Node3D
	var door: StaticBody3D
	var door_mat: StandardMaterial3D
	var hand_door: StaticBody3D
	var hand_open := false
	var floor_mat: StandardMaterial3D
	var half_width: float
	var front: float
	var back: float

	## margin: wie weit der Mittelpunkt hinter der Tür liegen muss (0 = Türlinie).
	func contains(world_pos: Vector3, margin: float = 0.0) -> bool:
		var p := root.to_local(world_pos)
		return absf(p.x) <= half_width and p.z >= -back and p.z <= front - margin


var cells := {}  # Zellen-ID -> CellView
var _b: BalanceConfig


func build(balance: BalanceConfig) -> void:
	_b = balance
	var north := ceili(balance.cell_count / 2.0)
	var south := balance.cell_count - north
	var row_width := maxi(north, south) * balance.cell_width
	var cell_depth := balance.cell_front_depth + balance.cell_back_depth

	_box(self, Vector3(0, -0.1, 0), Vector3(row_width, 0.2, balance.yard_depth), COLOR_YARD)
	# Äußere Hofwände an den Schmalseiten
	for sx in [-1.0, 1.0]:
		_box(self, Vector3(sx * (row_width / 2.0), balance.wall_height / 2.0, 0),
			Vector3(0.4, balance.wall_height, balance.yard_depth + 2.0 * cell_depth), COLOR_WALL)

	var id := 1
	for i in north:
		var x := -row_width / 2.0 + balance.cell_width * (i + 0.5)
		var z := -balance.yard_depth / 2.0 - balance.cell_front_depth
		_build_cell(id, Vector3(x, 0, z), 0.0)
		id += 1
	for i in south:
		var x := -row_width / 2.0 + balance.cell_width * (i + 0.5)
		var z := balance.yard_depth / 2.0 + balance.cell_front_depth
		_build_cell(id, Vector3(x, 0, z), 180.0)
		id += 1


## Zelle, in der sich die Weltposition befindet, sonst GameState.NO_CELL.
func cell_at(world_pos: Vector3, margin: float = 0.0) -> int:
	for id in cells:
		if cells[id].contains(world_pos, margin):
			return id
	return GameState.NO_CELL


func spawn_position(cell_id: int) -> Vector3:
	var cv: CellView = cells[cell_id]
	return cv.root.to_global(Vector3(0, 0.1, cv.front / 2.0))


## Aktualisiert Türen und Bodenfarben anhand des Spielzustands (aus Sicht eines Spielers).
func refresh(state: GameState, pid: int) -> void:
	for id in cells:
		var cv: CellView = cells[id]
		var inside: bool = state.cell_of(pid) == id
		# Tür schließt hinter dem Spieler, sobald er die Zelle in dieser Runde betreten hat.
		var sealed: bool = inside and state.claimed_by(id) == pid
		var blocked: bool = not state.doors_open() or sealed or (not inside and not state.can_enter(pid, id))
		cv.door.collision_layer = 1 if blocked else 0
		cv.door.visible = blocked
		cv.door_mat.albedo_color = COLOR_DOOR_BLOCKED if state.doors_open() else COLOR_DOOR_CLOSED
		var color := COLOR_FLOOR
		if state.has_visited(pid, id):
			color = COLOR_VISITED
		elif state.claimed_by(id) != GameState.NO_PLAYER:
			color = COLOR_TAKEN
		cv.floor_mat.albedo_color = color


## Nächste Handtür in Reichweite (oder null).
func nearest_hand_door(world_pos: Vector3, max_distance: float) -> CellView:
	var best: CellView = null
	var best_dist := max_distance
	for id in cells:
		var cv: CellView = cells[id]
		var d := cv.hand_door.global_position.distance_to(Vector3(world_pos.x, cv.hand_door.global_position.y, world_pos.z))
		if d <= best_dist:
			best_dist = d
			best = cv
	return best


func toggle_hand_door(cv: CellView) -> void:
	cv.hand_open = not cv.hand_open
	cv.hand_door.collision_layer = 0 if cv.hand_open else 1
	cv.hand_door.visible = not cv.hand_open


func _build_cell(id: int, pos: Vector3, rot_y_deg: float) -> void:
	var w := _b.cell_width
	var h := _b.wall_height
	var front := _b.cell_front_depth
	var back := _b.cell_back_depth
	var depth := front + back
	var mid_z := (front - back) / 2.0
	var seg_w := (w - _b.door_width) / 2.0
	var seg_x := _b.door_width / 2.0 + seg_w / 2.0

	var cv := CellView.new()
	cv.id = id
	cv.half_width = w / 2.0
	cv.front = front
	cv.back = back
	cv.root = Node3D.new()
	cv.root.name = "Cell%d" % id
	cv.root.position = pos
	cv.root.rotation_degrees.y = rot_y_deg
	add_child(cv.root)
	var r := cv.root

	var floor_body := _box(r, Vector3(0, -0.1, mid_z), Vector3(w, 0.2, depth), COLOR_FLOOR)
	cv.floor_mat = (floor_body.get_child(0) as MeshInstance3D).material_override
	for sx in [-1.0, 1.0]:
		_box(r, Vector3(sx * w / 2.0, h / 2.0, mid_z), Vector3(0.3, h, depth), COLOR_WALL)
	_box(r, Vector3(0, h / 2.0, -back), Vector3(w, h, 0.3), COLOR_WALL)
	for sx in [-1.0, 1.0]:
		_box(r, Vector3(sx * seg_x, h / 2.0, front), Vector3(seg_w, h, 0.3), COLOR_WALL)
		_box(r, Vector3(sx * seg_x, h / 2.0, 0.0), Vector3(seg_w, h, 0.3), COLOR_WALL)

	cv.door = _box(r, Vector3(0, h / 2.0, front), Vector3(_b.door_width, h, 0.2), COLOR_DOOR_CLOSED)
	cv.door_mat = (cv.door.get_child(0) as MeshInstance3D).material_override
	cv.door_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cv.hand_door = _box(r, Vector3(0, h / 2.0, 0.0), Vector3(_b.door_width, h, 0.2), COLOR_HAND_DOOR)

	var label := Label3D.new()
	label.text = str(id)
	label.font_size = 128
	label.pixel_size = 0.01
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(1, 1, 1)
	label.outline_size = 24
	label.position = Vector3(0, h + 1.0, front)
	r.add_child(label)

	cells[id] = cv


static func _box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	parent.add_child(body)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material_override = mat
	body.add_child(mesh)
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	shape.shape = bs
	body.add_child(shape)
	return body
